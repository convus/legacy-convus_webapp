require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "active_link" do
    context "match_controller" do
      let(:request) { double("request", url: new_hypothesis_path) }
      before { allow(helper).to receive(:request).and_return(request) }
      it "returns the link active with match_controller if on the controller" do
        expect(active_link("Hypothesis", new_hypothesis_path, class: "seeeeeeee", id: "something", match_controller: true)).to eq '<a class="seeeeeeee active" id="something" href="' + new_hypothesis_path + '">Hypothesis</a>'
      end
    end
  end

  describe "sortable_search_params" do
    before { controller.params = ActionController::Parameters.new(passed_params) }
    context "no sortable_search_params" do
      let(:passed_params) { {party: "stuff"} }
      it "returns an empty hash" do
        expect(sortable_search_params.to_unsafe_h).to eq({})
        expect(sortable_search_params?).to be_falsey
      end
    end
    context "direction, sort" do
      let(:passed_params) { {direction: "asc", sort: "stolen", party: "long"} }
      let(:target) { {direction: "asc", sort: "stolen"} }
      it "returns a hash" do
        expect(sortable_search_params.to_unsafe_h).to eq(target.as_json)
        expect(sortable_search_params?).to be_truthy
      end
    end
    context "search_array" do
      let(:passed_params) { {search_array: ["COVID-19"], commit: "Search"} }
      let(:target) { {search_array: ["COVID-19"]} }
      it "returns a hash" do
        expect(sortable_search_params.to_unsafe_h).to eq(target.as_json)
        expect(sortable_search_params?).to be_truthy
      end
    end
  end

  describe "hypothesis_link_to" do
    let(:target) { '<a class="a-class" id="something" href="/hypotheses/12">Hypothesis Link</a>' }
    it "links without hypothesis existing" do
      expect(hypothesis_link_to("Hypothesis Link", 12, class: "a-class", id: "something")).to eq target
    end
    context "with block" do
      it "works" do
        result = hypothesis_link_to 12, class: "a-class", id: "something" do
          "Hypothesis Link"
        end
        expect(result).to eq target
      end
    end
    context "with hypothesis existing" do
      let!(:hypothesis) { FactoryBot.create(:hypothesis, title: "this hypothesis is important") }
      let(:target) { '<a data-thing="whatever" title="this hypothesis is important" href="/hypotheses/this-hypothesis-is-important">1</a>' }
      it "links with hypothesis title" do
        expect(hypothesis_link_to("1", "this-hypothesis-is-important", "data-thing" => "whatever")).to eq target
      end
    end
  end


  describe "citation_link_to" do
    let(:target) { '<a class="a-class" id="something" href="/citations/12">Citation Link</a>' }
    it "links without citation existing" do
      expect(citation_link_to("Citation Link", 12, class: "a-class", id: "something")).to eq target
    end
    context "with block" do
      it "works" do
        result = citation_link_to 12, class: "a-class", id: "something" do
          "Citation Link"
        end
        expect(result).to eq target
      end
    end
    context "with citation existing" do
      let(:publication) { FactoryBot.create(:publication, title: "Some publication") }
      let!(:citation) { FactoryBot.create(:citation, title: "this citation is important", publication: publication) }
      let(:target) { '<a target="_blank" title="Some publication: this citation is important" href="/citations/' + citation.id.to_s + '">1</a>' }
      it "links with citation title" do
        expect(citation_link_to("1", citation.id, "target" => "_blank")).to eq target
      end
    end
  end
end
