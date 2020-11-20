# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/admin/content_commits", type: :request do
  let(:base_url) { "/admin/content_commits" }
  let!(:subject) { FactoryBot.create(:content_commit) }

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
    it "renders" do
      get base_url
      expect(response.code).to eq "200"
      expect(response).to render_template("admin/content_commits/index")
      expect(assigns(:content_commits).pluck(:id)).to eq([subject.id])
      expect(assigns(:controller_namespace)).to eq "admin"
    end
  end
end
