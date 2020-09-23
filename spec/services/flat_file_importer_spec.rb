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
      FlatFileSerializer.write_all_files
    end

    def serialized_hypothesis(hypothesis)

    end

    def serialized_citation(citation)
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
        hypothesis_serialized_og = Hypothesis.first.flat_file_content
        expect(Citation.count).to eq 1
        citation_serialized_og = Citation.first.flat_file_content

        Hypothesis.destroy_all
        Citation.destroy_all
        # TODO: import publications and tags
        # publication_id = Publication.first.id
        # tag_id = Tag.first.id
        # Publication.destroy_all
        # Tag.destroy_all
        subject.import_all_files
        expect(Hypothesis.count).to eq 1
        expect(Hypothesis.first.flat_file_content).to eq hypothesis_serialized_og
        expect(Citation.count).to eq 1
        expect(Citation.first.flat_file_content).to eq citation_serialized_og
        expect(HypothesisCitation.count).to eq 1 # Ensure we haven't created extras accidentally
        expect(Publication.count).to eq 1 # Ensure we haven't created extras accidentally
      end
    end
  end
end
