# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/hypotheses", type: :request do
  let(:base_url) { "/hypotheses" }
  let(:current_user) { nil }
  let(:subject) { FactoryBot.create(:hypothesis, creator_id: current_user&.id) }
  let(:full_citation_params) do
    {
      title: "Testing hypothesis creation is very important",
      kind: "research_review",
      peer_reviewed: true,
      randomized_controlled_trial: true,
      url_is_direct_link_to_full_text: "1",
      authors_str: "\nZack\n George\n",
      published_date_str: "1990-12-2",
      url_is_not_publisher: false
    }
  end
  let(:citation_url) { "https://example.com/something-of-interest" }

  describe "index" do
    let!(:hypothesis) { FactoryBot.create(:hypothesis) }
    let!(:hypothesis_approved1) { FactoryBot.create(:hypothesis_approved, title: "Here are dogs", tags_string: "animals, Something of Interest") }
    let!(:hypothesis_approved2) { FactoryBot.create(:hypothesis_approved, title: "Here be dragons", tags_string: "animals") }
    let(:tag1) { hypothesis_approved1.tags.first }
    let(:tag2) { hypothesis_approved1.tags.last }
    it "renders only the approved" do
      expect(tag1.title).to eq "animals"
      expect(tag2.title).to eq "Something of Interest"
      expect(Hypothesis.with_tag_ids([tag1.id]).pluck(:id)).to match_array([hypothesis_approved1.id, hypothesis_approved2.id])
      expect(Hypothesis.with_tag_ids([tag1.id, tag2.id]).pluck(:id)).to eq([hypothesis_approved1.id])
      get base_url
      expect(response).to render_template("hypotheses/index")
      expect(assigns(:hypotheses).pluck(:id)).to match_array([hypothesis_approved1.id, hypothesis_approved2.id])
      expect(assigns(:controller_namespace)).to be_blank
      # Unapproved
      get base_url, params: {search_unapproved: true}
      expect(assigns(:hypotheses).pluck(:id)).to eq([hypothesis.id])
      # Tags
      get base_url, params: {search_array: "something of interest,,"}
      expect(assigns(:search_tags).pluck(:id)).to eq([tag2.id])
      expect(assigns(:search_items)).to eq(["Something of Interest"])
      expect(assigns(:hypotheses).pluck(:id)).to eq([hypothesis_approved1.id])
      # text search
      get base_url, params: {search_array: "Animals, HERE"}
      expect(assigns(:search_tags).pluck(:id)).to eq([tag1.id])
      expect(assigns(:search_items)).to eq(["animals", "HERE"])
      expect(assigns(:hypotheses).pluck(:id)).to match_array([hypothesis_approved1.id, hypothesis_approved2.id])
      # text search
      get base_url, params: {search_array: "DOgs  "}
      expect(assigns(:search_tags).pluck(:id)).to eq([])
      expect(assigns(:search_items)).to eq(["DOgs"])
      expect(assigns(:hypotheses).pluck(:id)).to eq([hypothesis_approved1.id])
    end
  end

  describe "show" do
    it "renders" do
      post "/user_scores", params: {hypothesis_id: subject.id, kind: "quality", score: 12}
      expect(session[:after_sign_in_score]).to eq "#{subject.id},12,quality"
      expect(subject.approved?).to be_falsey
      get "#{base_url}/#{subject.to_param}"
      expect(response.code).to eq "200"
      expect(response).to render_template("hypotheses/show")
      expect(UserScore.count).to eq 0
      expect(session[:after_sign_in_score]).to eq "#{subject.id},12,quality"
      # Test that it sets the right title
      title_tag = response.body[/<title.*<\/title>/]
      expect(title_tag).to eq "<title>#{subject.title}</title>"
    end
    context "approved" do
      let(:subject) { FactoryBot.create(:hypothesis_approved) }
      let!(:explanation) { FactoryBot.create(:explanation_approved, hypothesis: subject) }
      it "renders" do
        expect(subject.approved?).to be_truthy
        expect(explanation.approved?).to be_truthy
        expect(subject.explanations.shown.pluck(:id)).to eq([explanation.id])
        get "#{base_url}/#{subject.to_param}"
        expect(response.code).to eq "200"
        expect(response).to render_template("hypotheses/show")
        expect(assigns(:explanations).pluck(:id)).to eq([explanation.id])
        expect(assigns(:unapproved_explanations).pluck(:id)).to eq([])
      end
      context "unapproved explanation_id" do
        let(:current_user) { FactoryBot.create(:user) }
        let!(:explanation2) { FactoryBot.create(:explanation, hypothesis: subject, creator: current_user) }
        let!(:explanation3) { FactoryBot.create(:explanation, hypothesis: subject) }
        it "renders, includes unapproved_hypothesis_citation" do
          expect(subject.approved?).to be_truthy
          expect(explanation.approved?).to be_truthy
          expect(explanation2.creator_id).to eq current_user.id
          expect(explanation2.approved?).to be_falsey
          expect(explanation2.shown?(current_user)).to be_truthy
          expect(explanation3.shown?(current_user)).to be_falsey
          # passing ID renders that explanation
          get "#{base_url}/#{subject.to_param}?explanation_id=#{explanation3.ref_number}"
          expect(response.code).to eq "200"
          expect(response).to render_template("hypotheses/show")
          expect(assigns(:explanations).pluck(:id)).to eq([explanation.id])
          expect(assigns(:unapproved_explanations).pluck(:id)).to eq([explanation3.id])
          # And with the user signed in!
          sign_in current_user
          get "#{base_url}/#{subject.to_param}"
          expect(response.code).to eq "200"
          expect(response).to render_template("hypotheses/show")
          expect(assigns(:explanations).pluck(:id)).to eq([explanation.id])
          expect(assigns(:unapproved_explanations).pluck(:id)).to eq([explanation2.id])
          # passing ID renders that explanation (even with user)
          get "#{base_url}/#{subject.to_param}?explanation_id=#{explanation3.ref_number}"
          expect(response.code).to eq "200"
          expect(response).to render_template("hypotheses/show")
          expect(assigns(:explanations).pluck(:id)).to eq([explanation.id])
          expect(assigns(:unapproved_explanations).pluck(:id)).to eq([explanation3.id])
        end
      end
      # Commented out in PR#146 - add when adding challenges
      # context "with challenged" do
      #   let(:challenged_hypothesis_citation) { FactoryBot.create(:hypothesis_citation_approved, hypothesis: subject) }
      #   let!(:hypothesis_citation_challenge) { FactoryBot.create(:hypothesis_citation_challenge_citation_quotation, :approved, challenged_hypothesis_citation: challenged_hypothesis_citation) }
      #   it "renders" do
      #     expect(subject.approved?).to be_truthy
      #     expect(hypothesis_citation_challenge.approved?).to be_truthy
      #     expect(subject.hypothesis_citations.approved.pluck(:id)).to match_array([challenged_hypothesis_citation.id, hypothesis_citation_challenge.id])
      #     get "#{base_url}/#{subject.to_param}"
      #     expect(response.code).to eq "200"
      #     expect(response).to render_template("hypotheses/show")
      #     expect(flash).to be_blank
      #     expect(assigns(:hypothesis_citations).pluck(:id)).to eq([challenged_hypothesis_citation.id])
      #     expect(assigns(:unapproved_hypothesis_citation)&.id).to be_blank
      #     # And requesting it with the
      #     get "#{base_url}/#{subject.to_param}?hypothesis_citation_id=#{hypothesis_citation_challenge.id}"
      #     expect(response.code).to eq "200"
      #     expect(response).to render_template("hypotheses/show")
      #     expect(flash[:success]).to be_present
      #     expect(assigns(:hypothesis_citations).pluck(:id)).to eq([challenged_hypothesis_citation.id])
      #     expect(assigns(:unapproved_hypothesis_citation)&.id).to be_blank
      #   end
      # end
    end
    context "after_sign_in_score and user signed in" do
      let(:current_user) { FactoryBot.create(:user) }
      before do
        post "/user_scores", params: {hypothesis_id: subject.id, kind: "quality", score: 12}
        expect(session[:after_sign_in_score]).to eq "#{subject.id},12,quality"
        sign_in current_user
      end
      it "renders, creates user score only once" do
        expect {
          get "#{base_url}/#{subject.to_param}"
        }.to change(UserScore, :count).by 1
        expect(response.code).to eq "200"
        expect(response).to render_template("hypotheses/show")
        expect(session[:after_sign_in_score]).to be_blank
        user_score = current_user.user_scores.current.last
        expect(user_score.hypothesis_id).to eq subject.id
        expect(user_score.kind).to eq "quality"
        expect(user_score.score).to eq 9
      end
      context "with existing score" do
        let!(:user_score1) { FactoryBot.create(:user_score, user: current_user, hypothesis: subject, score: score) }
        let(:score) { 2 }
        it "creates a new score" do
          expect(user_score1.expired?).to be_falsey
          expect {
            get "#{base_url}/#{subject.to_param}"
          }.to change(UserScore, :count).by 1
          expect(response.code).to eq "200"
          expect(response).to render_template("hypotheses/show")
          expect(session[:after_sign_in_score]).to be_blank
          expect(current_user.user_scores.count).to eq 2
          user_score = current_user.user_scores.current.last
          expect(user_score.hypothesis_id).to eq subject.id
          expect(user_score.kind).to eq "quality"
          expect(user_score.score).to eq 9
          user_score1.reload
          expect(user_score1.expired?).to be_truthy
        end
        context "score is the same" do
          let(:score) { 9 }
          it "does not create a new user score" do
            expect {
              get "#{base_url}/#{subject.to_param}"
            }.to_not change(UserScore, :count)
            expect(response.code).to eq "200"
            expect(response).to render_template("hypotheses/show")
            expect(session[:after_sign_in_score]).to be_blank
            expect(current_user.user_scores.count).to eq 1
          end
        end
      end
    end
  end

  describe "new" do
    it "redirects" do
      get "#{base_url}/new"
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "/hypotheses/new"
    end
  end

  context "logged in" do
    include_context :logged_in_as_user
    describe "index" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("hypotheses/index")
      end
    end

    describe "new" do
      it "renders" do
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("hypotheses/new")
      end
    end

    describe "create" do
      let(:hypothesis_params) do
        {
          title: "This seems like the truth",
          tags_string: "economy\n",
        }
      end
      it "creates" do
        expect(Hypothesis.count).to eq 0
        Sidekiq::Worker.clear_all
        expect {
          post base_url, params: {hypothesis: hypothesis_params.merge(approved_at: Time.current.to_s)}
        }.to change(Hypothesis, :count).by 1
        hypothesis = Hypothesis.last
        expect(response).to redirect_to new_hypothesis_explanation_path(hypothesis_id: hypothesis.ref_id)
        expect(AddToGithubContentJob.jobs.count).to eq 0
        expect(flash[:success]).to be_present

        expect(hypothesis.title).to eq hypothesis_params[:title]
        expect(hypothesis.creator).to eq current_user
        expect(hypothesis.pull_request_number).to be_blank
        expect(hypothesis.approved_at).to be_blank
        expect(hypothesis.tags.count).to eq 1
        expect(hypothesis.tags.pluck(:title)).to eq(["economy"])
      end
    end
  end
end
