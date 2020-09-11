# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/citations", type: :request do
  let(:base_url) { "/citations" }

  it "renders" do
    get base_url
    expect(response).to render_template("citations/index")
  end

  context "logged in" do
    include_context :logged_in_as_user
    describe "index" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("citations/index")
      end
    end
  end
end
