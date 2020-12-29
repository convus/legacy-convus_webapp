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
      FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis, url: citation.url)
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
          {url: "https://www.kqed.org/science/1969271/making-sense-of-purple-air-vs-airnow-and-a-new-map-to-rule-them-all", quotes: []}
        ]
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
      citation = hypothesis.citations.first
      expect(citation.approved?).to be_truthy
    end
    context "hypothesis already exists" do
      let(:og_title) { "Purple air sensors are less accurate than EPA sensors" }
      let(:old_attrs) { hypothesis_attrs.merge(title: og_title, topics: ["Environment"]) }
      let(:hypothesis) { FlatFileImporter.import_hypothesis(old_attrs) }
      it "imports as expected" do
        og_slug = hypothesis.slug
        expect(hypothesis.title).to_not eq hypothesis_attrs[:title]
        expect(hypothesis.tag_titles).to eq(["Environment"])
        expect(hypothesis.tags.pluck(:id)).to eq([tag.id])
        expect(hypothesis.previous_titles.pluck(:title)).to eq([])
        expect(Tag.count).to eq 1
        expect(tag.approved?).to be_falsey
        Sidekiq::Worker.clear_all

        FlatFileImporter.import_hypothesis(hypothesis_attrs)
        hypothesis.reload
        expect(hypothesis.title).to eq hypothesis_attrs[:title]
        expect(hypothesis.id).to eq hypothesis_attrs[:id]
        expect(hypothesis.slug).to_not eq og_slug

        expect(hypothesis.tags.approved.count).to eq 2
        expect(hypothesis.tags.pluck(:title)).to match_array(["Environment", "Air quality"])
        tag.reload
        expect(tag.approved_at).to be_within(5).of Time.current
        expect(Tag.count).to eq 2

        expect(hypothesis.citations.count).to eq 1
        expect(hypothesis.flat_file_serialized.except(:topics)).to eq(hypothesis_attrs.except(:topics))

        StorePreviousHypothesisTitleJob.drain
        expect(hypothesis.previous_titles.pluck(:title)).to eq([og_title])
      end
      describe "removing one of the hypothesis_citations" do
        it "removes the hypothesis_citation if it isn't present" do
          fail
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
