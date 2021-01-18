# Not dealing with testing this on CI right now

unless ENV["CIRCLECI"]
  require "rails_helper"

  RSpec.describe FlatFileImporter do
    let(:subject) { described_class }
    let(:base_dir) { FlatFileImporter::FILES_PATH }

    def delete_existing_files
      FileUtils.rm_rf(base_dir)
    end

    def list_of_files
      Dir.glob("#{base_dir}/**/*")
        .map { |f| file_without_base_dir(f) }
        .select { |f| f.present? && f.match?(/\..+/) } # Only return files with file extensions (ie reject directories)
    end

    def file_without_base_dir(str)
      # Remove base_dir and also the leading forward slash, if it's present
      str.gsub(/\A#{base_dir}/, "").delete_prefix("/")
    end

    def write_basic_files
      delete_existing_files
      publication = FactoryBot.create(:publication, title: "The Hill")
      citation = FactoryBot.create(:citation_approved, title: "some citation", publication: publication, kind: "government_statistics")
      hypothesis = FactoryBot.create(:hypothesis_approved, title: "hypothesis-1")
      FactoryBot.create(:hypothesis_citation_approved, hypothesis: hypothesis, url: citation.url)
      FactoryBot.create(:tag, title: "Health & Wellness", taxonomy: "family_rank")
      FlatFileSerializer.write_all_files
    end

    def expect_hypothesis_matches_og_content(og_content, og_serialized)
      expect(Hypothesis.count).to eq 1
      unless Hypothesis.first.flat_file_content == og_content
        pp Hypothesis.first.flat_file_serialized, og_serialized
        expect(Hypothesis.first.flat_file_serialized.except("created_timestamp")).to eq og_serialized.except("created_timestamp")
      end
    end

    def expect_citation_matches_og_content(og_content, og_serialized)
      expect(Citation.count).to eq 1
      unless Citation.first.flat_file_content == og_content
        pp Citation.first.flat_file_serialized, og_serialized
        expect(Citation.first.flat_file_content).to eq og_content
      end
      expect(HypothesisCitation.count).to eq 1 # Ensure we haven't created extras accidentally
      expect(Publication.count).to eq 1 # Ensure we haven't created extras accidentally
    end

    describe "import_all_files" do
      let(:target_filenames) do
        [
          "citations/the-hill/some-citation.yml",
          "hypotheses/hypothesis-1.yml",
          "publications.csv",
          "tags.csv"
        ]
      end
      it "imports what was exported" do
        write_basic_files
        expect(list_of_files).to match_array(target_filenames)
        expect(Hypothesis.count).to eq 1
        hypothesis_serialized_og = Hypothesis.first.flat_file_serialized
        hypothesis_content_og = Hypothesis.first.flat_file_content
        expect(Citation.count).to eq 1
        citation_serialized_og = Citation.first.flat_file_serialized
        citation_content_og = Citation.first.flat_file_content
        expect(Tag.count).to eq 1
        expect(Tag.approved.count).to eq 0
        tag_serialized_og = Tag.pluck(*Tag.serialized_attrs) # This is how tags are serialized
        expect(Publication.count).to eq 1
        publication_serialized_og = Publication.pluck(*Publication.serialized_attrs) # This is how publications are serialized

        Hypothesis.destroy_all
        Citation.destroy_all
        Tag.destroy_all
        Publication.destroy_all

        Sidekiq::Worker.clear_all
        subject.import_all_files
        expect_hypothesis_matches_og_content(hypothesis_content_og, hypothesis_serialized_og)
        expect_citation_matches_og_content(citation_content_og, citation_serialized_og)
        expect(Tag.pluck(:title, :id, :taxonomy)).to eq tag_serialized_og
        expect(UpdateHypothesisScoreJob.jobs.count).to eq 1

        # And do it a few more times, to ensure it doesn't duplicate things
        subject.import_all_files
        subject.import_all_files
        expect_hypothesis_matches_og_content(hypothesis_content_og, hypothesis_serialized_og)
        expect_citation_matches_og_content(citation_content_og, citation_serialized_og)
        expect(Tag.pluck(*Tag.serialized_attrs)).to eq tag_serialized_og
        expect(Publication.pluck(*Publication.serialized_attrs)).to eq publication_serialized_og
      end
    end
  end

  describe "import_hypothesis" do
    let(:hypothesis_attrs) do
      {
        title: "Purple air sensors are less accurate than EPA sensors. By turning on the conversion \"AQandU\" the data will more closely align with EPA readings",
        id: 2115,
        refuted_by_hypotheses: [],
        topics: ["environment ", "Air quality"],
        cited_urls: [
          {url: "https://www.kqed.org/science/1969271/making-sense-of-purple-air-vs-airnow-and-a-new-map-to-rule-them-all",
           quotes: [],
           challenges: nil}
        ],
        new_cited_url: nil
      }
    end
    let!(:tag) { Tag.find_or_create_for_title("Environment") }
    it "imports the hypothesis we expect" do
      expect(Hypothesis.count).to eq 0
      expect(Citation.count).to eq 0
      expect(Tag.count).to eq 1
      expect(tag.approved?).to be_falsey
      hypothesis = FlatFileImporter.import_hypothesis(hypothesis_attrs)
      expect(hypothesis.title).to eq hypothesis_attrs[:title]
      expect(hypothesis.id).to eq hypothesis_attrs[:id]

      expect(hypothesis.tags.approved.count).to eq 2
      expect(hypothesis.tags.pluck(:title)).to match_array(["Environment", "Air quality"])
      tag.reload
      expect(tag.approved_at).to be_within(5).of Time.current

      expect(hypothesis.citations.count).to eq 1
      expect(hypothesis.flat_file_serialized.except(:topics)).to eq(hypothesis_attrs.except(:topics))

      expect(hypothesis.hypothesis_citations.count).to eq 1
      hypothesis_citation = hypothesis.hypothesis_citations.first
      expect(hypothesis_citation.approved_at).to be_within(5).of Time.current
      expect(hypothesis_citation.creator_id).to be_blank

      citation = hypothesis.citations.first
      expect(citation.approved?).to be_truthy
    end
    context "hypothesis already exists" do
      let(:og_title) { "Purple air sensors are less accurate than EPA sensors" }
      let(:old_attrs) { hypothesis_attrs.merge(title: og_title, topics: ["Environment"]) }
      let(:hypothesis) { FlatFileImporter.import_hypothesis(old_attrs) }
      let(:user) { FactoryBot.create(:user) }
      let(:user2) { FactoryBot.create(:user) }
      let(:citation) { hypothesis.citations.first }
      it "imports as expected" do
        approved_at = Time.current - 5.minutes
        expect(citation.approved?).to be_truthy
        citation.update(creator_id: user2.id, approved_at: nil) # Ensure import approves existing citations
        hypothesis.update(creator_id: user.id, approved_at: approved_at)
        hypothesis.reload
        og_slug = hypothesis.slug
        expect(hypothesis.title).to_not eq hypothesis_attrs[:title]
        expect(hypothesis.tag_titles).to eq(["Environment"])
        expect(hypothesis.tags.pluck(:id)).to eq([tag.id])
        expect(hypothesis.previous_titles.pluck(:title)).to eq([])
        expect(hypothesis.creator_id).to eq user.id
        expect(hypothesis.hypothesis_citations.count).to eq 1
        hypothesis_citation = hypothesis.hypothesis_citations.first
        expect(hypothesis_citation.creator_id).to be_blank # Imported before hypothesis had creator_id
        hypothesis_citation.update(approved_at: approved_at)
        expect(Tag.count).to eq 1
        expect(tag.approved?).to be_falsey
        Sidekiq::Worker.clear_all

        FlatFileImporter.import_hypothesis(hypothesis_attrs)
        hypothesis.reload
        expect(hypothesis.title).to eq hypothesis_attrs[:title]
        expect(hypothesis.id).to eq hypothesis_attrs[:id]
        expect(hypothesis.slug).to_not eq og_slug
        expect(hypothesis.approved_at).to be_within(1).of approved_at

        expect(hypothesis.tags.approved.count).to eq 2
        expect(hypothesis.tags.pluck(:title)).to match_array(["Environment", "Air quality"])
        tag.reload
        expect(tag.approved_at).to be_within(5).of Time.current
        expect(Tag.count).to eq 2

        expect(hypothesis.citations.pluck(:id)).to eq([citation.id])
        citation.reload
        expect(citation.approved_at).to be_within(5).of Time.current
        expect(citation.creator_id).to eq user2.id
        expect(hypothesis.flat_file_serialized.except(:topics)).to eq(hypothesis_attrs.except(:topics))

        expect(hypothesis.hypothesis_citations.pluck(:id)).to eq([hypothesis_citation.id])
        hypothesis_citation.reload
        expect(hypothesis_citation.creator_id).to eq user.id
        expect(hypothesis_citation.approved_at).to be_within(1).of approved_at

        StorePreviousHypothesisTitleJob.drain
        expect(hypothesis.previous_titles.pluck(:title)).to eq([og_title])
      end
      describe "removing one of the hypothesis_citations" do
        let!(:hypothesis_citation_old) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis, url: "http://example.com/", quotes_text: "some quote") }
        let(:citation_old) { hypothesis_citation_old.citation }
        it "removes the hypothesis_citation if it isn't present" do
          citation_old.update(approved_at: Time.current)
          hypothesis.reload
          expect(hypothesis.citations.count).to eq 2
          expect(hypothesis.citations.approved.count).to eq 2
          expect(hypothesis.citations.pluck(:id)).to include(citation_old.id)
          expect(hypothesis.quotes.pluck(:text)).to eq(["some quote"])
          expect(citation_old.approved?).to be_truthy
          expect(citation_old.hypotheses.pluck(:id)).to eq([hypothesis.id])
          hypothesis_citation = hypothesis.hypothesis_citations.where.not(citation_id: hypothesis_citation_old.id).first
          expect(hypothesis_citation.citation.creator_id).to be_blank
          hypothesis_citation.update(creator_id: user.id)
          expect(hypothesis.title).to_not eq hypothesis_attrs[:title]
          expect(hypothesis.tags.pluck(:id)).to eq([tag.id])
          expect(Tag.count).to eq 1
          expect(Citation.count).to eq 2
          expect(tag.approved?).to be_falsey
          Sidekiq::Worker.clear_all

          FlatFileImporter.import_hypothesis(hypothesis_attrs)
          hypothesis.reload
          expect(hypothesis.title).to eq hypothesis_attrs[:title]
          expect(hypothesis.id).to eq hypothesis_attrs[:id]

          expect(hypothesis.tags.approved.count).to eq 2
          expect(hypothesis.tags.pluck(:title)).to match_array(["Environment", "Air quality"])
          tag.reload
          expect(tag.approved_at).to be_within(5).of Time.current
          expect(Tag.count).to eq 2

          expect(hypothesis.citations.pluck(:id)).to eq([hypothesis_citation.citation_id])
          expect(hypothesis.citations.approved.count).to eq 1
          expect(hypothesis.hypothesis_citations.pluck(:id)).to eq([hypothesis_citation.id])
          hypothesis_citation.reload
          expect(hypothesis_citation.citation.creator_id).to be_blank
          expect(hypothesis_citation.creator_id).to eq user.id # Hasn't changed

          expect(hypothesis.flat_file_serialized.except(:topics)).to eq(hypothesis_attrs.except(:topics))

          expect(Citation.count).to eq 2
          citation_old.reload
          expect(citation_old.hypotheses.pluck(:id)).to eq([])
          expect(citation_old.quotes.pluck(:text)).to eq(["some quote"]) # Not deleting this, for now

          StorePreviousHypothesisTitleJob.drain
          expect(hypothesis.previous_titles.pluck(:title)).to eq([og_title])
        end
      end
      context "new_cited_url" do
        let!(:hypothesis_citation) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis, url: "https://example.com/citation_addition", quotes_text: "ddsfasdf") }
        let(:hypothesis_attrs_new_cited_url) { old_attrs.merge(new_cited_url: {url: hypothesis_citation.url, quotes: ["ddsfasdf"]}) }
        it "doesn't delete the existing url, even though they aren't included" do
          hypothesis.reload

          expect(hypothesis_citation.reload.approved?).to be_falsey
          expect(hypothesis.citations.count).to eq 2
          expect(hypothesis.citations.approved.count).to eq 1
          hypothesis.included_unapproved_hypothesis_citation = hypothesis_citation
          expect_hashes_to_match(hypothesis.flat_file_serialized, hypothesis_attrs_new_cited_url)
          Sidekiq::Worker.clear_all

          FlatFileImporter.import_hypothesis(hypothesis.flat_file_serialized)
          hypothesis.reload
          expect(hypothesis.title).to eq old_attrs[:title]
          expect(hypothesis.id).to eq old_attrs[:id]
          expect(hypothesis.citations.count).to eq 2
          expect(hypothesis.citations.approved.count).to eq 2

          expect(hypothesis_citation.reload.approved?).to be_truthy
          expect(hypothesis_citation.quotes_text).to eq "ddsfasdf"
        end
      end
    end
    context "refuting hypothesis" do
      let!(:hypothesis_refuting) { FactoryBot.create(:hypothesis) }
      let(:hypothesis_attrs_refuted) { hypothesis_attrs.merge(refuted_by_hypotheses: [hypothesis_refuting.title]) }
      let(:hypothesis) { FlatFileImporter.import_hypothesis(hypothesis_attrs) }
      it "imports and adds refuting" do
        hypothesis.reload
        expect(hypothesis.refuted?).to be_falsey
        FlatFileImporter.import_hypothesis(hypothesis_attrs_refuted)

        hypothesis.reload
        expect(hypothesis.refuted?).to be_truthy
        expect(hypothesis.refuted_at).to be_within(1).of Time.current
        expect(hypothesis.refuted_by_hypotheses.pluck(:id)).to eq([hypothesis_refuting.id])
      end
    end
  end

  describe "import citation" do
    let(:citation_attrs) do
      {
        title: "Bureau of Justice Statistics,  Crime Victimization, 2019",
        id: "1627",
        peer_reviewed: "false",
        url_is_not_publisher: "false",
        url_is_direct_link_to_full_text: "true",
        url: "https://www.bjs.gov/index.cfm?ty=pbdetail&iid=7046",
        publication_title: "Bureau of Justice Statistics",
        published_date: "2019-02-03",
        authors: ["Rachel E. Morgan", "Jennifer L. Truman"],
        kind: "government statistics",
        quotes: ["There were 880,000 fewer victims of serious crimes (generally felonies) in 2019 than in 2018, a 19% drop"]
      }
    end
    it "imports the citation" do
      citation = FlatFileImporter.import_citation(citation_attrs)
      expect(citation.kind_humanized).to eq citation_attrs[:kind]
      expect_attrs_to_match_hash(citation, citation_attrs.except(:published_date, :quotes, :kind))
      # We don't actually import quotes from the citation! They come from the hypotheses
      expect(citation.quotes.count).to eq 0
      expect_hashes_to_match(citation.flat_file_serialized, citation_attrs.merge(quotes: []))
    end
  end
end
