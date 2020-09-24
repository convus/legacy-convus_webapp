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
      citation = FactoryBot.create(:citation_approved, title: "some citation", publication: publication)
      FactoryBot.create(:hypothesis_approved, title: "hypothesis-1", citation_urls: "#{citation.url},")
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
        tag_serialized_og = Tag.pluck(*Tag.serialized_attrs) # This is how tags are serialized
        expect(Publication.count).to eq 1
        publication_serialized_og = Publication.pluck(*Publication.serialized_attrs) # This is how publications are serialized

        Hypothesis.destroy_all
        Citation.destroy_all
        Tag.destroy_all
        Publication.destroy_all

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
end
