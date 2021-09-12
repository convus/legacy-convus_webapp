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
      hypothesis = FactoryBot.create(:hypothesis_approved, title: "hypothesis-1", ref_number: 2115)
      explanation = FactoryBot.create(:explanation, hypothesis: hypothesis)
      FactoryBot.create(:explanation_quote, explanation: explanation, url: citation.url)
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
      expect(Publication.count).to eq 1 # Ensure we haven't created extras accidentally
    end

    describe "import_all_files" do
      let(:target_filenames) do
        [
          "citations/the-hill/some-citation.yml",
          "hypotheses/1MR_hypothesis-1.md",
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
    let(:file_content) do
      "---\nid: #{ref_id}\nhypothesis: #{title}\ntopics:\n#{tags_serialized}\n" \
      "citations:\n#{citations_serialized}\n---\n## Explanation 1\n\n#{explanation_text}"
    end
    let(:ref_id) { "1MR" }
    let(:url1) { "https://www.kqed.org/science/1969271/making-sense-of-purple-air-vs-airnow-and-a-new-map-to-rule-them-all" }
    let(:title) { "Purple air sensors are less accurate than EPA sensors but provide useful data." }
    let(:tags_serialized) { "- environment\n- Air Quality" }
    let(:explanation_text) do
      "The sensors maintained and used by the US government are very accurate, however " \
      "there aren't as many of them. Private, lower-cost air quality monitors can help fill " \
      "in the gap:\n\n\n> Broadly put, PurpleAir provides more localized, more current and " \
      "less accurate readings than AirNow.\n> ref:#{url1}"
    end
    let(:citations_serialized) do
      "  #{url1}:\n    title: Making Sense of Purple Air vs. AirNow, and a New Map to Rule Them All" \
      "\n    published_date: 2020-09-04\n    publication_title: KQED"
    end
    let!(:tag) { Tag.find_or_create_for_title("Environment") }
    it "imports the hypothesis we expect" do
      expect(Hypothesis.count).to eq 0
      expect(Explanation.count).to eq 0
      expect(Citation.count).to eq 0
      expect(Tag.count).to eq 1
      expect(tag.approved?).to be_falsey

      hypothesis = FlatFileImporter.import_hypothesis(file_content)
      expect(hypothesis.title).to eq title
      expect(hypothesis.ref_id).to eq ref_id
      expect(hypothesis.ref_number).to eq 2115

      expect(Hypothesis.count).to eq 1
      expect(Explanation.count).to eq 1
      expect(Citation.count).to eq 1
      expect(Tag.count).to eq 2

      expect(hypothesis.tags.approved.count).to eq 2
      expect(hypothesis.tags.pluck(:title)).to match_array(["Environment", "Air Quality"])
      tag.reload
      expect(tag.approved_at).to be_within(5).of Time.current

      explanation = hypothesis.explanations.first
      expect(explanation.text_with_references).to eq explanation_text
      expect(explanation.body_html).to be_present
      expect(explanation.citations.count).to eq 1
      expect(explanation.approved?).to be_truthy

      citation = hypothesis.citations.first
      expect(citation.approved?).to be_truthy
      expect(citation.published_date_str).to eq "2020-09-04"
      expect(citation.title).to eq "Making Sense of Purple Air vs. AirNow, and a New Map to Rule Them All"
      expect(citation.publication_title).to eq "KQED"
    end
    context "hypothesis already exists" do
      let(:og_title) { "Purple air or whatever." }
      let(:hypothesis) { Hypothesis.create(title: og_title, ref_id: ref_id, creator: user, approved_at: approved_at, tags_string: "Environment") }
      let(:user) { FactoryBot.create(:user) }
      let(:user2) { FactoryBot.create(:user) }
      let(:citation) { Citation.create(url: url1, creator: user2) }
      let(:approved_at) { Time.current - 5.minutes }
      it "imports as expected" do
        expect(citation.reload.approved?).to be_falsey

        og_slug = hypothesis.slug
        expect(hypothesis.title).to eq og_title
        expect(hypothesis.tag_titles).to eq(["Environment"])
        expect(hypothesis.tags.pluck(:id)).to eq([tag.id])
        expect(hypothesis.previous_titles.pluck(:title)).to eq([])
        expect(hypothesis.creator_id).to eq user.id
        expect(Tag.count).to eq 1
        expect(tag.approved?).to be_falsey
        Sidekiq::Worker.clear_all

        FlatFileImporter.import_hypothesis(file_content)
        hypothesis.reload
        expect(hypothesis.title).to eq title
        expect(hypothesis.ref_id).to eq ref_id
        expect(hypothesis.ref_number).to eq 2115
        expect(hypothesis.slug).to_not eq og_slug

        expect(Hypothesis.count).to eq 1
        expect(Explanation.count).to eq 1
        expect(Citation.count).to eq 1
        expect(Tag.count).to eq 2

        StorePreviousHypothesisTitleJob.drain
        expect(hypothesis.previous_titles.pluck(:title)).to eq([og_title])
      end

      describe "removing one of the hypothesis_citations" do
        let(:explanation) { hypothesis.explanations.create(text: "something something something") }
        let!(:explanation_quote) { explanation.explanation_quotes.create(text: "a quote!", url: "https://something.com") }
        it "removes the hypothesis_citation if it isn't present" do
          hypothesis.reload
          explanation_quote.reload
          expect(explanation_quote.removed?).to be_falsey
          expect(explanation.explanation_quotes.pluck(:id)).to eq([explanation_quote.id])

          Sidekiq::Worker.clear_all

          FlatFileImporter.import_hypothesis(file_content)
          hypothesis.reload
          expect(hypothesis.title).to eq title
          expect(hypothesis.ref_id).to eq ref_id
          expect(hypothesis.ref_number).to eq 2115

          expect(Hypothesis.count).to eq 1
          expect(Explanation.count).to eq 1
          expect(Citation.count).to eq 2
          expect(Tag.count).to eq 2

          explanation.reload
          expect(explanation.text_with_references).to eq explanation_text
          expect(explanation.body_html).to be_present
          expect(explanation.citations.count).to eq 2
          expect(explanation.citations_not_removed.count).to eq 1
          expect(explanation.approved?).to be_truthy
          expect(explanation_quote.reload.removed?).to be_truthy

          StorePreviousHypothesisTitleJob.drain
          expect(hypothesis.previous_titles.pluck(:title)).to eq([og_title])
        end
      end
      # context "new challenge" do
      #   it "adds"
      # end
      # context "challenge exists" do
      #   it "updates"
      # end
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
        doi: "https://doi.org/10.1038/s41467-020-17316-z",
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
