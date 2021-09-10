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

  # Commented out in PR#146
  # describe "import_hypothesis" do
  #   let(:hypothesis_attrs) do
  #     {
  #       title: "Purple air sensors are less accurate than EPA sensors. By turning on the conversion \"AQandU\" the data will more closely align with EPA readings",
  #       id: "1MR",
  #       explanations: {},
  #       topics: ["environment ", "Air quality"],
  #       cited_urls: [
  #         {url: "https://www.kqed.org/science/1969271/making-sense-of-purple-air-vs-airnow-and-a-new-map-to-rule-them-all",
  #          quotes: [],
  #          challenges: nil}
  #       ],
  #       new_cited_url: nil
  #     }
  #   end
  #   let!(:tag) { Tag.find_or_create_for_title("Environment") }
  #   it "imports the hypothesis we expect" do
  #     expect(Hypothesis.count).to eq 0
  #     expect(Citation.count).to eq 0
  #     expect(Tag.count).to eq 1
  #     expect(tag.approved?).to be_falsey
  #     hypothesis = FlatFileImporter.import_hypothesis(hypothesis_attrs)
  #     expect(hypothesis.title).to eq hypothesis_attrs[:title]
  #     expect(hypothesis.ref_id).to eq hypothesis_attrs[:id]

  #     expect(hypothesis.tags.approved.count).to eq 2
  #     expect(hypothesis.tags.pluck(:title)).to match_array(["Environment", "Air quality"])
  #     tag.reload
  #     expect(tag.approved_at).to be_within(5).of Time.current

  #     expect(hypothesis.citations.count).to eq 1
  #     expect(hypothesis.flat_file_serialized.except(:topics)).to eq(hypothesis_attrs.except(:topics))

  #     citation = hypothesis.citations.first
  #     expect(citation.approved?).to be_truthy
  #   end
  #   context "hypothesis already exists" do
  #     let(:og_title) { "Purple air sensors are less accurate than EPA sensors" }
  #     let(:old_attrs) { hypothesis_attrs.merge(title: og_title, topics: ["Environment"]) }
  #     let(:hypothesis) { FlatFileImporter.import_hypothesis(old_attrs) }
  #     let(:user) { FactoryBot.create(:user) }
  #     let(:user2) { FactoryBot.create(:user) }
  #     let(:citation) { hypothesis.citations.first }
  #     it "imports as expected" do
  #       approved_at = Time.current - 5.minutes
  #       expect(citation.approved?).to be_truthy
  #       citation.update(creator_id: user2.id, approved_at: nil) # Ensure import approves existing citations
  #       hypothesis.update(creator_id: user.id, approved_at: approved_at)
  #       hypothesis.reload
  #       og_slug = hypothesis.slug
  #       expect(hypothesis.title).to_not eq hypothesis_attrs[:title]
  #       expect(hypothesis.tag_titles).to eq(["Environment"])
  #       expect(hypothesis.tags.pluck(:id)).to eq([tag.id])
  #       expect(hypothesis.previous_titles.pluck(:title)).to eq([])
  #       expect(hypothesis.creator_id).to eq user.id
  #       expect(Tag.count).to eq 1
  #       expect(tag.approved?).to be_falsey
  #       Sidekiq::Worker.clear_all

  #       FlatFileImporter.import_hypothesis(hypothesis_attrs)
  #       hypothesis.reload
  #       expect(hypothesis.title).to eq hypothesis_attrs[:title]
  #       expect(hypothesis.ref_id).to eq hypothesis_attrs[:id]
  #       expect(hypothesis.slug).to_not eq og_slug
  #       expect(hypothesis.approved_at).to be_within(1).of approved_at

  #       expect(hypothesis.tags.approved.count).to eq 2
  #       expect(hypothesis.tags.pluck(:title)).to match_array(["Environment", "Air quality"])
  #       tag.reload
  #       expect(tag.approved_at).to be_within(5).of Time.current
  #       expect(Tag.count).to eq 2

  #       expect(hypothesis.citations.pluck(:id)).to eq([citation.id])
  #       citation.reload
  #       expect(citation.approved_at).to be_within(5).of Time.current
  #       expect(citation.creator_id).to eq user2.id
  #       expect(hypothesis.flat_file_serialized.except(:topics)).to eq(hypothesis_attrs.except(:topics))

  #       StorePreviousHypothesisTitleJob.drain
  #       expect(hypothesis.previous_titles.pluck(:title)).to eq([og_title])
  #     end

  #     describe "removing one of the hypothesis_citations" do
  #       let!(:hypothesis_citation_old) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis, url: "http://example.com/", quotes_text: "some quote") }
  #       let(:citation_old) { hypothesis_citation_old.citation }
  #       it "removes the hypothesis_citation if it isn't present" do
  #         citation_old.update(approved_at: Time.current)
  #         hypothesis.reload
  #         expect(hypothesis.citations.count).to eq 2
  #         expect(hypothesis.citations.approved.count).to eq 2
  #         expect(hypothesis.citations.pluck(:id)).to include(citation_old.id)
  #         expect(hypothesis.quotes.pluck(:text)).to eq(["some quote"])
  #         expect(citation_old.approved?).to be_truthy
  #         expect(citation_old.hypotheses.pluck(:id)).to eq([hypothesis.id])
  #         hypothesis_citation = hypothesis.hypothesis_citations.where.not(citation_id: hypothesis_citation_old.id).first
  #         expect(hypothesis_citation.citation.creator_id).to be_blank
  #         hypothesis_citation.update(creator_id: user.id)
  #         expect(hypothesis.title).to_not eq hypothesis_attrs[:title]
  #         expect(hypothesis.tags.pluck(:id)).to eq([tag.id])
  #         expect(Tag.count).to eq 1
  #         expect(Citation.count).to eq 2
  #         expect(tag.approved?).to be_falsey
  #         Sidekiq::Worker.clear_all

  #         FlatFileImporter.import_hypothesis(hypothesis_attrs)
  #         hypothesis.reload
  #         expect(hypothesis.title).to eq hypothesis_attrs[:title]
  #         expect(hypothesis.ref_id).to eq hypothesis_attrs[:id]

  #         expect(hypothesis.tags.approved.count).to eq 2
  #         expect(hypothesis.tags.pluck(:title)).to match_array(["Environment", "Air quality"])
  #         tag.reload
  #         expect(tag.approved_at).to be_within(5).of Time.current
  #         expect(Tag.count).to eq 2

  #         expect(hypothesis.citations.pluck(:id)).to eq([hypothesis_citation.citation_id])
  #         expect(hypothesis.citations.approved.count).to eq 1
  #         expect(hypothesis.hypothesis_citations.pluck(:id)).to eq([hypothesis_citation.id])
  #         hypothesis_citation.reload
  #         expect(hypothesis_citation.citation.creator_id).to be_blank
  #         expect(hypothesis_citation.creator_id).to eq user.id # Hasn't changed

  #         expect(hypothesis.flat_file_serialized.except(:topics)).to eq(hypothesis_attrs.except(:topics))

  #         expect(Citation.count).to eq 2
  #         citation_old.reload
  #         expect(citation_old.hypotheses.pluck(:id)).to eq([])
  #         expect(citation_old.quotes.pluck(:text)).to eq(["some quote"]) # Not deleting this, for now

  #         StorePreviousHypothesisTitleJob.drain
  #         expect(hypothesis.previous_titles.pluck(:title)).to eq([og_title])
  #       end
  #     end
  #     context "new_cited_url" do
  #       let!(:hypothesis_citation) { FactoryBot.create(:hypothesis_citation, hypothesis: hypothesis, url: "https://example.com/citation_addition", quotes_text: "ddsfasdf") }
  #       let(:hypothesis_attrs_new_cited_url) { old_attrs.merge(new_cited_url: {url: hypothesis_citation.url, quotes: ["ddsfasdf"], challenges: nil}) }
  #       it "adds the new hypothesis_citation" do
  #         hypothesis.reload

  #         expect(hypothesis_citation.reload.approved?).to be_falsey
  #         expect(hypothesis.citations.count).to eq 2
  #         expect(hypothesis.citations.approved.count).to eq 1
  #         hypothesis.included_unapproved_hypothesis_citation = hypothesis_citation
  #         expect_hashes_to_match(hypothesis.flat_file_serialized, hypothesis_attrs_new_cited_url)
  #         Sidekiq::Worker.clear_all

  #         FlatFileImporter.import_hypothesis(hypothesis.flat_file_serialized)
  #         hypothesis.reload
  #         expect(hypothesis.title).to eq old_attrs[:title]
  #         expect(hypothesis.ref_id).to eq old_attrs[:id]
  #         expect(hypothesis.citations.count).to eq 2
  #         expect(hypothesis.citations.approved.count).to eq 2

  #         expect(hypothesis_citation.reload.approved?).to be_truthy
  #         expect(hypothesis_citation.quotes_text).to eq "ddsfasdf"
  #         expect(hypothesis_citation.challenged_hypothesis_citation&.id).to be_blank
  #       end
  #     end
  #     context "new challenge" do
  #       let(:challenged_hypothesis_citation) { hypothesis.reload.hypothesis_citations.first }
  #       let(:quotes_text) { "one weird thing that you should know right now" }
  #       let(:hypothesis_attrs_new_cited_url) do
  #         old_attrs.merge(new_cited_url: {
  #           url: challenged_hypothesis_citation.url,
  #           quotes: [quotes_text],
  #           challenges: challenged_hypothesis_citation.url
  #         })
  #       end
  #       it "adds the new hypothesis_citation" do
  #         hypothesis.reload
  #         expect(hypothesis.citations.count).to eq 1
  #         expect(hypothesis.citations.approved.pluck(:id)).to eq([challenged_hypothesis_citation.citation_id])
  #         Sidekiq::Worker.clear_all

  #         FlatFileImporter.import_hypothesis(hypothesis_attrs_new_cited_url)
  #         hypothesis.reload
  #         expect(hypothesis.title).to eq old_attrs[:title]
  #         expect(hypothesis.ref_id).to eq old_attrs[:id]
  #         expect(hypothesis.citations.count).to eq 2
  #         expect(hypothesis.hypothesis_citations.count).to eq 2
  #         expect(hypothesis.hypothesis_citations.approved.count).to eq 2

  #         hypothesis_citation = hypothesis.hypothesis_citations.reorder(:created_at).last
  #         expect(hypothesis_citation.reload.approved?).to be_truthy
  #         expect(hypothesis_citation.quotes_text).to eq quotes_text
  #         expect(hypothesis_citation.url).to eq challenged_hypothesis_citation.url
  #         expect(hypothesis_citation.challenged_hypothesis_citation&.id).to eq challenged_hypothesis_citation.id
  #         expect(hypothesis_citation.kind).to eq "challenge_citation_quotation"
  #       end
  #       context "challenge exists in db" do
  #         let(:example_url) { "https://example.com/citation_addition" }
  #         let(:hypothesis_attrs_new_cited_url) do
  #           old_attrs.merge(new_cited_url: {
  #             url: example_url,
  #             quotes: [quotes_text],
  #             challenges: challenged_hypothesis_citation.url
  #           })
  #         end
  #         let!(:hypothesis_citation_challenge) { FactoryBot.create(:hypothesis_citation_challenge_by_another_citation, challenged_hypothesis_citation: challenged_hypothesis_citation, quotes_text: quotes_text, url: example_url) }
  #         it "approves the challenge" do
  #           hypothesis.reload
  #           expect(hypothesis_citation_challenge.reload.approved?).to be_falsey
  #           expect(hypothesis.hypothesis_citations.approved.pluck(:id)).to eq([challenged_hypothesis_citation.id])
  #           hypothesis.included_unapproved_hypothesis_citation = hypothesis_citation_challenge
  #           expect_hashes_to_match(hypothesis.flat_file_serialized, hypothesis_attrs_new_cited_url)
  #           Sidekiq::Worker.clear_all

  #           FlatFileImporter.import_hypothesis(hypothesis.flat_file_serialized)
  #           hypothesis.reload
  #           expect(hypothesis.title).to eq old_attrs[:title]
  #           expect(hypothesis.ref_id).to eq old_attrs[:id]
  #           expect(hypothesis.citations.count).to eq 2
  #           expect(hypothesis.citations.count).to eq 2
  #           expect(hypothesis.citations.approved.count).to eq 2

  #           expect(hypothesis_citation_challenge.reload.approved?).to be_truthy
  #           expect(hypothesis_citation_challenge.quotes_text).to eq quotes_text
  #           expect(hypothesis_citation_challenge.url).to eq example_url
  #           expect(hypothesis_citation_challenge.challenged_hypothesis_citation&.id).to eq challenged_hypothesis_citation.id
  #           expect(hypothesis_citation_challenge.kind).to eq "challenge_by_another_citation"
  #         end
  #       end
  #     end
  #     context "explanation" do
  #       let(:hypothesis_attrs) do
  #         {
  #           title: "The earth is roughly spherical",
  #           id: "J",
  #           cited_urls: [],
  #           new_cited_url: nil,
  #           topics: [],
  #           explanations: {1 =>
  #               {id: 1,
  #                text:
  #                 "There are many pieces of evidence to the roughly spherical shape of the earth - such as photos from space - but in terms of personally verifiable evidence, timezones demonstrate the rotation of the earth:\n\n" \
  #                   "> On a flat Earth, a Sun that shines in all directions would illuminate the entire surface at the same time, and all places would experience sunrise and sunset at the horizon at about the same time. With a spherical Earth, half the planet is in daylight at any given time and the other half experiences nighttime. When a given location on the spherical Earth is in sunlight, its antipode - the location exactly on the opposite side of the Earth - is in darkness.\n\n" \
  #                   "And because the earth is spinning it is drawn into a sphere like shape:\n\n" \
  #                   "> The Earth is massive enough that the pull of gravity maintains its roughly spherical shape. Most of its deviation from spherical stems from the centrifugal force caused by rotation around its north-south axis. This force deforms the sphere into an oblate ellipsoid\n",
  #                quote_urls:
  #                 ["https://en.wikipedia.org/wiki/Spherical_Earth",
  #                   "https://en.wikipedia.org/wiki/Spherical_Earth"]}}
  #         }
  #       end
  #       it "creates the explanation" do
  #         expect(Hypothesis.count).to eq 0
  #         expect(Citation.count).to eq 0
  #         expect(Tag.count).to eq 1
  #         expect(tag.approved?).to be_falsey
  #         hypothesis = FlatFileImporter.import_hypothesis(hypothesis_attrs)
  #         expect(hypothesis.title).to eq hypothesis_attrs[:title]
  #         expect(hypothesis.ref_id).to eq hypothesis_attrs[:id]
  #         expect(hypothesis.tags.approved.count).to eq 0

  #         expect(hypothesis.explanations.count).to eq 1
  #         explanation = hypothesis.explanations.first
  #         expect(explanation.approved_at).to be_within(5).of Time.current
  #         expect(explanation.ref_number).to eq 1
  #         expect(explanation.text).to eq hypothesis_attrs.dig(:explanations, 1, :text)
  #         expect(explanation.body_html).to be_present
  #         expect(explanation.explanation_quotes.not_removed.count).to eq 2
  #         explanation_quote1 = explanation.explanation_quotes.ref_ordered.first
  #         expect(explanation_quote1.ref_number).to eq 1
  #         expect(explanation_quote1.url).to eq "https://en.wikipedia.org/wiki/Spherical_Earth"
  #         expect(explanation_quote1.text).to eq "On a flat Earth, a Sun that shines in all directions would illuminate the entire surface at the same time, and all places would experience sunrise and sunset at the horizon at about the same time. With a spherical Earth, half the planet is in daylight at any given time and the other half experiences nighttime. When a given location on the spherical Earth is in sunlight, its antipode - the location exactly on the opposite side of the Earth - is in darkness."

  #         explanation_quote2 = explanation.explanation_quotes.ref_ordered.last
  #         expect(explanation_quote2.ref_number).to eq 2
  #         expect(explanation_quote2.url).to eq "https://en.wikipedia.org/wiki/Spherical_Earth"
  #         expect(explanation_quote2.text).to eq "The Earth is massive enough that the pull of gravity maintains its roughly spherical shape. Most of its deviation from spherical stems from the centrifugal force caused by rotation around its north-south axis. This force deforms the sphere into an oblate ellipsoid"

  #         # Will need to add these!
  #         expect(hypothesis.citations.count).to eq 1

  #         expect_hashes_to_match(hypothesis.flat_file_serialized, hypothesis_attrs)
  #       end
  #     end
  #   end
  # end

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
