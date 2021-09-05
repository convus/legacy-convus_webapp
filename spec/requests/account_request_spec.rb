# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/account", type: :request do
  let(:base_url) { "/account" }

  it "redirects" do
    get base_url
    expect(response).to redirect_to new_user_session_path
  end

  context "logged in" do
    include_context :logged_in_as_user
    describe "show" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("accounts/show")
      end
      context "with not submitted things" do
        let!(:hypothesis_approved) { FactoryBot.create(:hypothesis_approved, creator: current_user) }
        let!(:hypothesis_approved2) { FactoryBot.create(:hypothesis_approved, creator: current_user) }
        let!(:hypothesis_not_submitted) { FactoryBot.create(:hypothesis, creator: current_user) }
        let(:user_hypothesis_ids) { [hypothesis_approved.id, hypothesis_approved2.id, hypothesis_not_submitted.id] }
        it "renders with expected things" do
          current_user.reload
          expect(current_user.created_hypotheses.pluck(:id)).to match_array(user_hypothesis_ids)
          expect(current_user.created_hypotheses.not_submitted_to_github.pluck(:id)).to match_array([hypothesis_not_submitted.id])
          get base_url
          expect(response.code).to eq "200"
          expect(response).to render_template("accounts/show")
          expect(assigns(:hypotheses).pluck(:id)).to match_array(user_hypothesis_ids)
          expect(assigns(:hypotheses_submitted).pluck(:id)).to match_array([hypothesis_approved.id, hypothesis_approved2.id])
          expect(assigns(:hypotheses_not_submitted).pluck(:id)).to match_array([hypothesis_not_submitted.id])
        end
      end
    end
  end
end
