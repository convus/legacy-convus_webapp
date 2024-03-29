# Not dealing with testing this on CI right now

unless ENV["CIRCLECI"]
  require "rails_helper"

  RSpec.describe FlatFileSerializer do
    let(:subject) { described_class }
    let(:base_dir) { FlatFileSerializer::FILES_PATH }
    let(:publication) { FactoryBot.create(:publication, title: "The Hill, etc") }

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

    before { delete_existing_files }

    describe "write_all_files" do
      let!(:citation) { FactoryBot.create(:citation_approved, title: "some citation", publication: publication) }
      let!(:hypothesis) { FactoryBot.create(:hypothesis_approved, title: "hypothesis-1", ref_number: 10) }
      let(:target_filenames) do
        [
          "citations/the-hill-etc/some-citation.yml",
          "hypotheses/A_hypothesis-1.md",
          "publications.csv",
          "tags.csv"
        ]
      end
      it "writes the expected files" do
        subject.write_all_files
        expect(list_of_files).to match_array(target_filenames)
      end
    end

    describe "write_approved_hypotheses" do
      let!(:citation) { FactoryBot.create(:citation_approved, title: "Pelosi digs in as pressure builds for COVID-19 deal", publication: publication) }
      let(:hypothesis) { FactoryBot.create(:hypothesis_approved, title: "US waiting for updated COVID-19 relief package", tags_string: "some tag", ref_number: 112) }
      let(:explanation) { FactoryBot.create(:explanation, hypothesis: hypothesis) }
      let!(:explanation_quote) { FactoryBot.create(:explanation_quote, explanation: explanation, url: citation.url) }
      let(:target_filename) { "hypotheses/34_us-waiting-for-updated-covid-19-relief-package.md" }
      it "writes the files" do
        hypothesis.reload
        expect(hypothesis.ref_id).to eq "34"
        expect(hypothesis.citations.pluck(:id)).to eq([citation.id])
        expect(hypothesis.tags.count).to eq 1
        expect(list_of_files).to eq([])
        hypothesis.flat_file_name(base_dir)
        expect(file_without_base_dir(hypothesis.flat_file_name(base_dir))).to eq target_filename
        Hypothesis.approved.find_each { |hypothesis| subject.write_hypothesis(hypothesis) }
        expect(list_of_files).to eq([target_filename])
      end
    end

    describe "write_all_citations" do
      let!(:citation) { FactoryBot.create(:citation_approved, title: "Pelosi digs in as pressure builds for COVID-19 deal", publication: publication) }
      let(:target_filename) { "citations/the-hill-etc/pelosi-digs-in-as-pressure-builds-for-covid-19-deal.yml" }
      it "writes the files" do
        expect(list_of_files).to eq([])
        citation.flat_file_name(base_dir)
        expect(file_without_base_dir(citation.flat_file_name(base_dir))).to eq target_filename
        Citation.approved.find_each { |citation| subject.write_citation(citation) }
        expect(list_of_files).to eq([target_filename])
      end
    end

    describe "write_all_tags" do
      let!(:tag) { FactoryBot.create(:tag_approved) }
      it "writes the csv file" do
        expect(list_of_files).to eq([])
        subject.write_approved_tags
        expect(list_of_files).to eq(["tags.csv"])
        output = File.read(subject.tags_file)
        expect(output.split("\n").count).to eq 2
      end
    end

    describe "write_all_publications" do
      let(:target) { ["The Hill, etc", publication.id.to_s, "false", "false", "false", nil, nil] }
      require "csv"
      it "writes the csv file" do
        expect(publication).to be_present
        expect(list_of_files).to eq([])
        subject.write_all_publications
        expect(list_of_files).to eq(["publications.csv"])
        output = File.read(subject.publications_file)
        expect(output.split("\n").count).to eq 2
        lines = CSV.parse(output)
        expect(lines.last).to eq target
      end
    end
  end
end
