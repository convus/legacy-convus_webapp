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
end
