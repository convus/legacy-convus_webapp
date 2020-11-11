# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/user_scores", type: :request do
  let(:base_url) { "/user_scores" }
  let!(:hypothesis) { FactoryBot.create(:hypothesis) }

  it "redirects" do
    post base_url, params: { hypothesis_id: hypothesis.id, kind: "quality", score: 8 }
    expect(response).to redirect_to new_user_session_path
    expect(session[:user_return_to]).to eq(hypothesis_path(hypothesis.id))
    expect(session[:after_sign_in_score]).to eq("#{hypothesis.id},8,quality")
  end

  context "logged in" do
    include_context :logged_in_as_user
    describe "creates the user_score" do
      it "renders" do
        expect do
          post base_url, params: { hypothesis_id: hypothesis.id, kind: "quality", score: 8 }
        end.to change(UserScore, :count).by 1
        expect(flash).to be_blank
        expect(response).to redirect_to(hypothesis_path(hypothesis.to_param))

        user_score = UserScore.last
        expect(user_score.user_id).to eq current_user.id
        expect(user_score.kind).to eq "quality"
        expect(user_score.score).to eq 8
      end
    end
  end
end
