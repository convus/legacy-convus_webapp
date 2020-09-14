# Not dealing with testing this on CI right now

unless ENV["CIRCLECI"]
  require "rails_helper"

  RSpec.describe FlatFileSerializer do
    let(:subject) { described_class }

    def delete_existing_files
      FileUtils.rm_rf(FlatFileSerializer::FILES_PATH)
    end

    def list_of_files
      Dir.glob("#{FlatFileSerializer::FILES_PATH}/**/*.yml")
        .map { |f| f.gsub(FlatFileSerializer::FILES_PATH, "") }.compact
    end

    # it "writes the expected files"

    describe "write_all_publications" do
      let!(:publication) { FactoryBot.create(:publication, title: "Test of things name") }
      it "writes the files" do
        delete_existing_files
        expect(list_of_files).to eq([])
        expect(publication.flat_file_name(FlatFileSerializer::FILES_PATH)).to eq "../test_flat_file_out/publications/test-of-things-name.yml"
        subject.write_all_publications
        expect(list_of_files).to eq(["/publications/test-of-things-name.yml"])
      end
    end
  end
end
