# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/account", type: :request do
  let(:base_url) { "/account"}

  it "redirects" do
    get base_url
    expect(response).to redirect_to user_github_omniauth_authorize_path
  end
  context "logged in" do
    include_context :logged_in_as_user
    describe "show" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("landing/index")
      end
    end
  end
end
