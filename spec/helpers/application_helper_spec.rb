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
end
