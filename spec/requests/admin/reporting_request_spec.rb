# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/admin/reporting", type: :request do
  let(:base_url) { "/admin" }

  context "not logged in" do
    describe "index" do
      it "redirects" do
        get base_url
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context "logged in as user" do
    include_context :logged_in_as_user
    describe "index" do
      it "redirects" do
        get base_url
        expect(response).to redirect_to(account_path)
        expect(flash[:error]).to be_present
      end
    end
  end

  context "logged_in_as_developer" do
    include_context :logged_in_as_developer
    describe "root" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/reporting/index")
        expect(assigns(:controller_namespace)).to eq "admin"
      end
    end
  end
end
