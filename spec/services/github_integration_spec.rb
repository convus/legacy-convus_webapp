require "rails_helper"

RSpec.describe GithubIntegration do
  let(:subject) { described_class.new }

  def branches(client)
    subject.refs.map(&:ref).uniq
  end

  def open_pull_requests(client)
    subject.pull_requests(state: "open")
  end

  describe "main_branch_ref" do
    let(:target) { "b26302f7f2872653dece0c814a31401a0653963c" }
    it "gets the main branch sha" do
      VCR.use_cassette("github_integration-main_branch_sha", match_requests_on: [:method]) do
        expect(subject.main_branch_sha).to eq target
      end
    end
  end

  describe "get most recent main branch commit" do
    let(:target) { JSON.parse(File.read(Rails.root.join("spec", "fixtures", "content_commit.json"))).with_indifferent_access }
    it "gets the main branch sha" do
      VCR.use_cassette("github_integration-last_main_commit", match_requests_on: [:method]) do
        last_main_commit = subject.last_main_commit
        expect_hashes_to_match(last_main_commit.except("files"), target.except("files"))
        expect(last_main_commit["files"]).to eq target["files"]
      end
    end
  end

  describe "create_citation_pull_request" do
    let(:citation) do
      ci = Citation.create(url: "https://www.example.com/testing")
      ci.update_column :id, 42 # Consistent PRs
      ci
    end
    it "creates the PR" do
      VCR.use_cassette("github_integration-create_citation_pull_request", match_requests_on: [:method]) do
        initial_branch_count = branches(subject.client).count
        initial_pull_requests = open_pull_requests(subject.client)
        pull_request = subject.create_citation_pull_request(citation)
        # IDK wtf is happening with this being the same branch count, but whatever, it works for now
        expect(branches(subject.client).count).to be >= initial_branch_count
        prs = open_pull_requests(subject.client)
        expect(prs.count).to be > initial_pull_requests.count
        citation.reload
        expect(citation.pull_request_number).to be_present

        # Can't do this via octokit.rb right now. BUT OH DAMN THIS IS SOMETHING WE WANT - to make this truthy
        expect(pull_request.maintainer_can_modify).to be_falsey
      end
    end
  end

  describe "create_explanation_pull_request" do
    let(:hypothesis_title) { "The earth is roughly spherical" }
    let(:approved_at) { Time.current - 1.hour }
    let(:hypothesis) { Hypothesis.create(title: hypothesis_title, created_at: approved_at, approved_at: approved_at, ref_number: 19) }
    let(:quote1) { "On a flat Earth, a Sun that shines in all directions would illuminate the entire surface at the same time, and all places would experience sunrise and sunset at the horizon at about the same time. With a spherical Earth, half the planet is in daylight at any given time and the other half experiences nighttime. When a given location on the spherical Earth is in sunlight, its antipode - the location exactly on the opposite side of the Earth - is in darkness." }
    let(:quote2) { "The Earth is massive enough that the pull of gravity maintains its roughly spherical shape. Most of its deviation from spherical stems from the centrifugal force caused by rotation around its north-south axis. This force deforms the sphere into an oblate ellipsoid" }
    let(:explanation_text) do
      "There are many pieces of evidence to the roughly spherical shape of the earth - such as photos from space - but in terms of personally verifiable evidence, timezones demonstrate the rotation of the earth:\n\n" \
      "> #{quote1}\n\n" \
      "And because the earth is spinning it is drawn into a sphere like shape:\n\n" \
      "> #{quote2}\n"
    end
    let(:url) { "https://en.wikipedia.org/wiki/Spherical_Earth" }
    let(:explanation) { Explanation.create(text: explanation_text, hypothesis: hypothesis) }
    let!(:explanation_quote1) { ExplanationQuote.create(explanation: explanation, text: quote1, url: url) }
    let!(:explanation_quote2) { ExplanationQuote.create(explanation: explanation, text: quote2, url: url) }
    let(:citation) { explanation_quote1.citation }

    it "creates the pull request" do
      # Make sure the citation finds the existing citation file, so it updates rather that creates
      citation.update(title: "Spherical Earth", publication_title: "Wikipedia")
      expect(hypothesis.reload.approved?).to be_truthy
      expect(hypothesis.ref_id).to eq "J"
      expect(explanation.reload.explanation_quotes.pluck(:ref_number)).to eq([1, 2])
      expect(explanation.pull_request_number).to be_blank
      expect(citation.reload.approved?).to be_falsey
      expect(citation.reload.pull_request_number).to be_blank
      expect(hypothesis.citations.pluck(:id)).to eq([citation.id])

      # Make sure that the above hypothesis_title is actually a title that is used in the content_repository
      # Or this isn't testing updating the file contents
      VCR.use_cassette("github_integration-existing_file-create_explanation_pull_request", match_requests_on: [:method], record: :new_episodes) do
        hypothesis.reload
        expect(hypothesis.pull_request_number).to be_blank
        expect(hypothesis.explanations.submitted_to_github.count).to eq 0
        pull_request = subject.create_explanation_pull_request(explanation)
        explanation.reload
        expect(explanation.pull_request_number).to be_present

        # And check the hypothesis
        hypothesis.reload
        expect(hypothesis.pull_request_number).to be_blank
        expect(hypothesis.explanations.submitted_to_github.count).to eq 1

        # And check the citation
        citation.reload
        expect(citation.pull_request_number).to be_present
        expect(citation.approved?).to be_falsey

        # Can't do this via octokit.rb right now. BUT OH GOD THIS IS SOMETHING WE WANT - to make this truthy
        expect(pull_request.maintainer_can_modify).to be_falsey
      end
    end

    context "hypothesis file doesn't exist" do
      let(:hypothesis_title) { "Something else about earth sphericalness" }
      let(:hypothesis) { Hypothesis.create(title: hypothesis_title, created_at: Time.current - 1.hour, ref_number: 11) }

      it "creates the hypothesis" do
        expect(hypothesis.reload.pull_request_number).to be_blank
        expect(hypothesis.approved?).to be_falsey
        expect(hypothesis.ref_id).to eq "B"
        expect(explanation.reload.explanation_quotes.pluck(:ref_number)).to eq([1, 2])
        expect(explanation.pull_request_number).to be_blank

        # Make sure that the above hypothesis_title is actually a title that is used in the content_repository
        # Or this isn't testing updating the file contents
        VCR.use_cassette("github_integration-create_explanation_pull_request_new", match_requests_on: [:method], record: :new_episodes) do
          hypothesis.reload
          expect(hypothesis.pull_request_number).to be_blank
          expect(hypothesis.explanations.submitted_to_github.count).to eq 0
          subject.create_explanation_pull_request(explanation)
          explanation.reload
          expect(explanation.pull_request_number).to be_present

          # And check the hypothesis
          hypothesis.reload
          expect(hypothesis.pull_request_number).to be_blank
          expect(hypothesis.explanations.submitted_to_github.count).to eq 1
        end
      end
      context "with relations" do
        let(:earlier_approval) { Time.current - 20.days }
        let(:hypothesis_earlier) { Hypothesis.create(title: "The earth is roughly spherical", ref_number: 19, approved_at: earlier_approval, created_at: earlier_approval) }
        let!(:hypothesis_relation) { HypothesisRelation.find_or_create_for(kind: "hypothesis_support", hypotheses: [hypothesis, hypothesis_earlier]) }
        it "creates the pull request" do
          expect(hypothesis_earlier.reload.approved?).to be_truthy
          expect(hypothesis_earlier.ref_id).to eq "J"

          expect(hypothesis.reload.pull_request_number).to be_blank
          expect(hypothesis.approved?).to be_falsey
          expect(hypothesis.ref_id).to eq "B"
          expect(explanation.reload.explanation_quotes.pluck(:ref_number)).to eq([1, 2])
          expect(explanation.pull_request_number).to be_blank
          expect(hypothesis_relation.reload.approved?).to be_falsey
          expect(hypothesis_relation.pull_request_number).to be_blank

          # Make sure that the above hypothesis_title is actually a title that is used in the content_repository
          # Or this isn't testing updating the file contents
          VCR.use_cassette("github_integration-create_explanation_pull_request_relations", match_requests_on: [:method], record: :new_episodes) do
            hypothesis.reload
            expect(hypothesis.pull_request_number).to be_blank
            expect(hypothesis.explanations.submitted_to_github.count).to eq 0
            subject.create_explanation_pull_request(explanation)
            explanation.reload
            expect(explanation.pull_request_number).to be_present

            # And check the hypothesis
            hypothesis.reload
            expect(hypothesis.pull_request_number).to be_blank
            expect(hypothesis.explanations.submitted_to_github.count).to eq 1
            expect(hypothesis_relation.reload.approved?).to be_falsey
            expect(hypothesis_relation.pull_request_number).to be_present
          end
        end
      end
    end
  end
end
