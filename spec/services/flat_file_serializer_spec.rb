# Not dealing with testing this on CI right now

unless ENV["CIRCLECI"]
  require "rails_helper"

  RSpec.describe FlatFileSerializer do
    let(:subject) { described_class }
    let(:base_dir) { FlatFileSerializer::FILES_PATH }
    let!(:publication) { FactoryBot.create(:publication, title: "The Hill") }

    def delete_existing_files
      FileUtils.rm_rf(base_dir)
    end

    def list_of_files
      Dir.glob("#{base_dir}/**/*.yml").map { |f| file_without_base_dir(f) }.compact
    end

    def file_without_base_dir(str)
      # Remove base_dir and also the leading forward slash, if it's present
      str.gsub(/\A#{base_dir}/, "").gsub(/\A\//, "")
    end

    before { delete_existing_files }

    describe "write_all_files" do
      it "writes the expected files"
    end

    describe "write_all_hypotheses" do
      let!(:citation) { FactoryBot.create(:citation, title: "Pelosi digs in as pressure builds for COVID-19 deal", publication: publication) }
      let(:hypothesis) { FactoryBot.create(:hypothesis, title: "US waiting for updated COVID-19 relief package", tags_string: "some tag", citations: [citation]) }
      let(:target_filename) { "hypotheses/us-waiting-for-updated-covid-19-relief-package.yml" }
      it "writes the files" do
        hypothesis.reload
        expect(hypothesis.citations.pluck(:id)).to eq([citation.id])
        expect(hypothesis.tags.count).to eq 1
        expect(list_of_files).to eq([])
        filename = hypothesis.flat_file_name(base_dir)
        expect(file_without_base_dir(hypothesis.flat_file_name(base_dir))).to eq target_filename
        subject.write_all_hypotheses
        expect(list_of_files).to eq([target_filename])
      end
    end

    describe "write_all_citations" do
      let!(:citation) { FactoryBot.create(:citation, title: "Pelosi digs in as pressure builds for COVID-19 deal", publication: publication) }
      let(:target_filename) { "citations/the-hill-pelosi-digs-in-as-pressure-builds-for-covid-19-deal.yml" }
      it "writes the files" do
        expect(list_of_files).to eq([])
        filename = citation.flat_file_name(base_dir)
        expect(file_without_base_dir(citation.flat_file_name(base_dir))).to eq target_filename
        subject.write_all_citations
        expect(list_of_files).to eq([target_filename])
      end
    end

    describe "write_all_publications" do
      xit "writes the files" do
        expect(list_of_files).to eq([])
        filename = publication.flat_file_name(base_dir)
        expect(file_without_base_dir(filename)).to eq "publications/test-of-things-name.yml"
        subject.write_all_publications
        expect(list_of_files).to eq(["/publications/test-of-things-name.yml"])
      end
    end
  end
end
