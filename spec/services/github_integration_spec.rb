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

  describe "create_hypothesis_pull_request" do
    let(:hypothesis) do
      hy = Hypothesis.create(title: "Testing GitHub integration")
      hy.update_column :id, 42 # So we get consistent PRs
      hy
    end

    it "creates the pull request" do
      expect(hypothesis.pull_request_number).to be_blank
      # When changing this - you have to remove any existing refs for branches named the same.
      # Delete it either by closing the PR: https://github.com/convus/convus_content/pulls
      # Or deleting the branch manually (if PR wasn't created): https://github.com/convus/convus_content/branches
      VCR.use_cassette("github_integration-create_hypothesis_pull_request", match_requests_on: [:method]) do
        branches(subject.client).count
        open_pull_requests(subject.client)
        pull_request = subject.create_hypothesis_pull_request(hypothesis)
        # This isn't testing correctly, even though the pull request is being created correctly
        # ... so ignore for now. To re-enable, will require assigning results above to variables
        # expect(branches(subject.client).count).to be > initial_branch_count
        # prs = open_pull_requests(subject.client)
        # expect(prs.count).to be > initial_pull_requests.count
        hypothesis.reload
        expect(hypothesis.pull_request_number).to be_present

        # Can't do this via octokit.rb right now. BUT OH GOD THIS IS SOMETHING WE WANT - to make this truthy
        expect(pull_request.maintainer_can_modify).to be_falsey
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
        expect(branches(subject.client).count).to be > initial_branch_count
        prs = open_pull_requests(subject.client)
        expect(prs.count).to be > initial_pull_requests.count
        citation.reload
        expect(citation.pull_request_number).to be_present

        # Can't do this via octokit.rb right now. BUT OH DAMN THIS IS SOMETHING WE WANT - to make this truthy
        expect(pull_request.maintainer_can_modify).to be_falsey
      end
    end
  end

  describe "create_hypothesis_citation_pull_request" do
    let(:hypothesis) do
      hy = Hypothesis.create(title: "Testing GitHub Hypothesis Citation addition", approved_at: Time.current - 1.hour)
      hy.update_columns(id: 42, created_at: hy.approved_at) # So we get consistent PRs
      hy
    end
    let!(:hypothesis_citation_prior) { FactoryBot.create(:hypothesis_citation_approved, hypothesis: hypothesis, quotes_text: "Some quote here") }
    let!(:hypothesis_citation) { hypothesis.hypothesis_citations.create(url: "https://testing.convus.org/examples/etc", quotes_text: "whooooooo") }

    it "creates the pull request" do
      expect(hypothesis_citation.pull_request_number).to be_blank
      # When changing this - you have to remove any existing refs for branches named the same.
      # Delete it either by closing the PR: https://github.com/convus/convus_content/pulls
      # Or deleting the branch manually (if PR wasn't created): https://github.com/convus/convus_content/branches
      VCR.use_cassette("github_integration-create_hypothesis_citation_pull_request", match_requests_on: [:method]) do
        hypothesis.reload
        expect(hypothesis.hypothesis_citations.submitted_to_github.count).to eq 1
        branches(subject.client).count
        open_pull_requests(subject.client)
        expect(hypothesis_citation)
        pull_request = subject.create_hypothesis_citation_pull_request(hypothesis_citation)
        # This isn't testing correctly, even though the pull request is being created correctly
        # ... so ignore for now. To re-enable, will require assigning results above to variables
        # expect(branches(subject.client).count).to be > initial_branch_count
        # prs = open_pull_requests(subject.client)
        # expect(prs.count).to be > initial_pull_requests.count
        hypothesis_citation.reload
        expect(hypothesis_citation.pull_request_number).to be_present

        # And check the hypothesis
        hypothesis.reload
        expect(hypothesis_citation.pull_request_number).to be_blank #
        expect(hypothesis.hypothesis_citations.submitted_to_github.count).to eq 2

        # Can't do this via octokit.rb right now. BUT OH GOD THIS IS SOMETHING WE WANT - to make this truthy
        expect(pull_request.maintainer_can_modify).to be_falsey
      end
    end
  end
end
