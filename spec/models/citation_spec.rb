require 'rails_helper'

RSpec.describe Citation, type: :model do
  describe "calculated_score" do
    let(:citation) { Citation.new }
    before { citation.set_calculated_attributes }
    it "is 0" do
      expect(citation.kind).to eq "article"
      expect(citation.kind_score).to eq 1
    end
    context "with publication" do
      let(:publication) { Publication.new }
      let(:citation) { Citation.new(publication: publication) }
      it "is 0" do
        expect(citation.kind).to eq "article"
        expect(citation.kind_score).to eq 1
      end
      context "publication has issued retractions" do
        let(:publication) { Publication.new(has_issued_retractions: true) }
        it "is 2" do
          expect(citation.kind_score).to eq 3
        end
      end
    end
    context "open_access_peer_reviewed" do
      let(:citation) { Citation.new(kind: "open_access_peer_reviewed") }
      it "is 20" do
        expect(citation.kind_score).to eq 20
      end
    end
  end
end
