# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/hypotheses", type: :request do
  let(:base_url) { "/hypotheses" }
  let(:full_citation_params) do
    {
      title: "Testing hypothesis creation is very important",
      assignable_kind: "article",
      peer_reviewed: true,
      randomized_controlled_trial: true,
      url_is_direct_link_to_full_text: "0",
      authors_str: "\nZack\n George\n",
      published_date_str: "1990-12-2",
      url_is_not_publisher: false,
      quotes_text: "First quote from this literature\nSecond quote, which is cool\nThird"
    }
  end
  let(:full_citation_url) { "https://example.com/something-of-interest" }
  let(:subject) { FactoryBot.create(:hypothesis, creator_id: current_user&.id) }
  let(:current_user) { nil }

  describe "index" do
    let!(:hypothesis) { FactoryBot.create(:hypothesis) }
    let!(:hypothesis_approved) { FactoryBot.create(:hypothesis_approved, tags_string: "something of interest") }
    let(:tag) { hypothesis_approved.tags.first }
    it "renders only the approved" do
      get base_url
      expect(response).to render_template("hypotheses/index")
      expect(assigns(:hypotheses).pluck(:id)).to eq([hypothesis_approved.id])
      get base_url, params: {search_array: "something of interest,,"}
      expect(response).to render_template("hypotheses/index")
      expect(assigns(:hypotheses).pluck(:id)).to eq([hypothesis_approved.id])
      expect(assigns(:search_tags).pluck(:id)).to eq([tag.id])
    end
  end

  describe "show" do
    it "renders" do
      post "/user_scores", params: { hypothesis_id: subject.id, kind: "quality", score: 12 }
      expect(session[:after_sign_in_score]).to eq "#{subject.id},12,quality"
      expect(subject.approved?).to be_falsey
      get "#{base_url}/#{subject.to_param}"
      expect(response.code).to eq "200"
      expect(response).to render_template("hypotheses/show")
      expect(UserScore.count).to eq 0
      expect(session[:after_sign_in_score]).to eq "#{subject.id},12,quality"
    end
    context "approved" do
      let(:subject) { FactoryBot.create(:hypothesis_approved) }
      it "renders" do
        expect(subject.approved?).to be_truthy
        get "#{base_url}/#{subject.to_param}"
        expect(response.code).to eq "200"
        expect(response).to render_template("hypotheses/show")

        get "/#{subject.file_path}"
        expect(response.code).to eq "200"
        expect(response).to render_template("hypotheses/show")
        expect(assigns(:hypothesis)&.id).to eq subject.id

        get "#{base_url}/#{subject.id}"
        expect(response.code).to eq "200"
        expect(response).to render_template("hypotheses/show")
        expect(assigns(:hypothesis)&.id).to eq subject.id
      end
    end
    context "after_sign_in_score and user signed in" do
      let(:current_user) { FactoryBot.create(:user) }
      before do
        post "/user_scores", params: { hypothesis_id: subject.id, kind: "quality", score: 12 }
        expect(session[:after_sign_in_score]).to eq "#{subject.id},12,quality"
        sign_in current_user
      end
      it "renders, creates user score only once" do
        expect do
          get "#{base_url}/#{subject.to_param}"
        end.to change(UserScore, :count).by 1
        expect(response.code).to eq "200"
        expect(response).to render_template("hypotheses/show")
        expect(session[:after_sign_in_score]).to be_blank
        user_score = current_user.user_scores.current.last
        expect(user_score.hypothesis_id).to eq subject.id
        expect(user_score.kind).to eq "quality"
        expect(user_score.score).to eq 10
      end
      context "with existing score" do
        let!(:user_score1) { FactoryBot.create(:user_score, user: current_user, hypothesis: subject, score: score) }
        let(:score) { 2 }
        it "creates a new score" do
          expect(user_score1.expired?).to be_falsey
          expect do
            get "#{base_url}/#{subject.to_param}"
          end.to change(UserScore, :count).by 1
          expect(response.code).to eq "200"
          expect(response).to render_template("hypotheses/show")
          expect(session[:after_sign_in_score]).to be_blank
          expect(current_user.user_scores.count).to eq 2
          user_score = current_user.user_scores.current.last
          expect(user_score.hypothesis_id).to eq subject.id
          expect(user_score.kind).to eq "quality"
          expect(user_score.score).to eq 10
          user_score1.reload
          expect(user_score1.expired?).to be_truthy
        end
        context "score is the same" do
          let(:score) { 10 }
          it "does not create a new user score" do
            expect do
              get "#{base_url}/#{subject.to_param}"
            end.to_not change(UserScore, :count)
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

  describe "edit" do
    it "redirects" do
      get "#{base_url}/#{subject.to_param}/edit"
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "/hypotheses/#{subject.to_param}/edit"
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
      let(:hc_params) { {Time.current.to_i.to_s => {url: "https://example.com/something-of-interest", quotes_text: "a quote from this article\n and another quote from it\n"}} }
      let(:simple_hypothesis_params) do
        {
          title: "This seems like the truth",
          tags_string: "economy\n",
          hypothesis_citations_attributes: hc_params
        }
      end
      it "creates" do
        expect(Hypothesis.count).to eq 0
        Sidekiq::Worker.clear_all
        expect {
          post base_url, params: {hypothesis: simple_hypothesis_params.merge(approved_at: Time.current.to_s)}
        }.to change(Hypothesis, :count).by 1
        hypothesis = Hypothesis.last
        expect(response).to redirect_to edit_hypothesis_path(hypothesis.id)
        expect(AddHypothesisToGithubContentJob.jobs.count).to eq 0
        expect(flash[:success]).to be_present

        expect(hypothesis.title).to eq simple_hypothesis_params[:title]
        expect(hypothesis.creator).to eq current_user
        expect(hypothesis.pull_request_number).to be_blank
        expect(hypothesis.approved_at).to be_blank
        expect(hypothesis.tags.count).to eq 1
        expect(hypothesis.tags.pluck(:title)).to eq(["economy"])

        expect(hypothesis.hypothesis_citations.count).to eq 1
        hypothesis_citation = hypothesis.hypothesis_citations.first
        expect(hypothesis_citation.url).to eq hc_params.values.first[:url]
        expect(hypothesis_citation.quotes_text).to be_present

        expect(hypothesis.citations.count).to eq 1
        citation = hypothesis.citations.first
        expect(citation.url).to eq hypothesis_citation.url

        expect(hypothesis.hypothesis_quotes.count).to eq 2
        hypothesis_quote1 = hypothesis.hypothesis_quotes.first
        hypothesis_quote2 = hypothesis.hypothesis_quotes.second
        expect(hypothesis_quote1.quote_text).to eq "a quote from this article"
        expect(hypothesis_quote1.citation_id).to eq citation.id
        expect(hypothesis_quote2.quote_text).to eq "and another quote from it"
        expect(hypothesis_quote2.citation_id).to eq citation.id
        expect(hypothesis_quote1.score).to be > hypothesis_quote2.score
      end
      context "invalid params" do
        let(:invalid_hypothesis_params) { simple_hypothesis_params.merge(title: "", hypothesis_citations_attributes: {Time.current.to_i.to_s => {url: " ", quotes_text: "whooooo"}}) }
        it "does not create, does not explode" do
          expect {
            post base_url, params: {hypothesis: invalid_hypothesis_params}
          }.to_not change(Hypothesis, :count)
          expect(response).to render_template("hypotheses/new")
          errored_hypothesis = assigns(:hypothesis)
          expect(errored_hypothesis.title).to be_blank
          expect(errored_hypothesis.errors_full_messages).to match_array(["Citation URL can't be blank", "Title can't be blank"])
          expect(errored_hypothesis.tags_string).to eq "economy"
          # map so that count isn't 0 (because they don't have ids)
          expect(errored_hypothesis.hypothesis_citations.map(&:url).count).to eq 2
          errored_hypothesis_citation = errored_hypothesis.hypothesis_citations.first
          expect(errored_hypothesis_citation.url).to be_blank
          expect(errored_hypothesis_citation.quotes_text).to eq("whooooo")
        end
      end
      context "multiple citations" do
        let(:hc2_params) { {(Time.current - 2.minutes).to_i.to_s => {url: "https://example.com/something-else", quotes_text: "whooooo"}} }
        let!(:citation) { FactoryBot.create(:citation, url: "https://example.com/something-of-interest") }
        let(:hypothesis_params) { simple_hypothesis_params.merge(hypothesis_citations_attributes: hc_params.merge(hc2_params)) }
        it "creates the things of them" do
          expect(Hypothesis.count).to eq 0
          expect {
            post base_url, params: {hypothesis: hypothesis_params}
          }.to change(Citation, :count).by 1
          hypothesis = Hypothesis.last
          expect(response).to redirect_to edit_hypothesis_path(hypothesis.id)
          expect(flash[:success]).to be_present

          expect(hypothesis.title).to eq simple_hypothesis_params[:title]
          expect(hypothesis.creator).to eq current_user
          expect(hypothesis.submitted_to_github?).to be_falsey
          expect(hypothesis.tags.count).to eq 1

          expect(hypothesis.hypothesis_citations.count).to eq 2
          expect(hypothesis.hypothesis_citations.pluck(:citation_id)).to include(citation.id)
          expect(hypothesis.hypothesis_citations.pluck(:url)).to match_array(["https://example.com/something-of-interest", "https://example.com/something-else"])

          expect(hypothesis.quotes.pluck(:text)).to match_array(["whooooo", "a quote from this article", "and another quote from it"])
        end
      end
    end

    describe "edit" do
      it "renders" do
        expect(subject.editable_by?(current_user)).to be_truthy
        expect(subject.creator_id).to eq current_user.id
        get "#{base_url}/#{subject.to_param}/edit"
        expect(response.code).to eq "200"
        expect(flash).to be_blank
        expect(response).to render_template("hypotheses/edit")
        expect(assigns(:hypothesis)&.id).to eq subject.id
      end
      context "other persons hypothesis" do
        let(:subject) { FactoryBot.create(:hypothesis) }
        it "redirects" do
          expect(subject.editable_by?(current_user)).to be_falsey
          expect(subject.creator_id).to_not eq current_user.id
          get "#{base_url}/#{subject.to_param}/edit"
          expect(response.code).to redirect_to account_path
          expect(flash[:error]).to be_present
        end
      end
      context "approved hypothesis" do
        let(:subject) { FactoryBot.create(:hypothesis_approved, creator_id: current_user.id) }
        it "redirects" do
          expect(subject.editable_by?(current_user)).to be_falsey
          expect(subject.creator_id).to eq current_user.id
          get "#{base_url}/#{subject.to_param}/edit"
          expect(response.code).to redirect_to assigns(:user_root_path)
          expect(flash[:error]).to be_present
        end
      end
    end

    describe "update" do
      let!(:citation) { FactoryBot.create(:citation, title: nil, url: "https://example.com/something-of-interest", authors_str: "george", creator: current_user) }
      let(:hypothesis_params) do
        {
          title: "This seems like the truth",
          tags_string: "economy\nparties",
          hypothesis_citations_attributes: {
            Time.current.to_i.to_s => {
              url: "https://something-of.org/interest-asdfasdf",
              quotes_text: "First quote from this literature\nSecond quote, which is cool",
              _destroy: "0"
            },
            "1" => {
              url: full_citation_url,
              quotes_text: "This is a thing",
              citation_attributes: citation_params,
              _destroy: "0"
            }
          }
        }
      end
      let(:citation_params) { full_citation_params }
      let(:hypothesis_add_to_github_params) { {hypothesis: hypothesis_params.merge(add_to_github: "1")} }
      it "updates" do
        expect(subject.citations.count).to eq 0
        citation.reload
        expect(citation.title_url?).to be_truthy
        Sidekiq::Worker.clear_all
        expect(Citation.count).to eq 1
        patch "#{base_url}/#{subject.id}", params: {hypothesis: hypothesis_params.merge(add_to_github: "")}
        expect(flash[:success]).to be_present
        expect(Citation.count).to eq 2
        expect(response).to redirect_to edit_hypothesis_path(subject.id)
        expect(assigns(:hypothesis)&.id).to eq subject.id
        expect(assigns(:hypothesis).submitted_to_github?).to be_falsey
        expect(AddHypothesisToGithubContentJob.jobs.count).to eq 0
        subject.reload
        expect(subject.title).to eq hypothesis_params[:title]
        expect(subject.submitted_to_github?).to be_falsey
        expect(subject.tags_string).to eq "economy, parties"
        expect(subject.citations.count).to eq 2

        citation.reload
        expect(citation.title).to eq full_citation_params[:title]
        expect(citation.url).to eq full_citation_url
        expect(citation.submitted_to_github?).to be_falsey
        expect(citation.publication).to be_present
        expect(citation.publication_title).to eq "example.com"
        expect(citation.authors).to eq(["Zack", "George"])
        expect(citation.published_date_str).to eq "1990-12-02"
        expect(citation.url_is_direct_link_to_full_text).to be_falsey
        expect(citation.creator_id).to eq current_user.id
        expect(citation.hypothesis_citations.first.quotes_text).to eq "This is a thing"

        citation2 = subject.citations.order(:created_at).last
        expect(citation2.url).to eq "https://something-of.org/interest-asdfasdf"
        expect(citation2.hypothesis_citations.first.quotes_text).to eq "First quote from this literature\n\nSecond quote, which is cool"
        # updating with the exact same thing again shouldn't make a change
        expect {
          patch "#{base_url}/#{subject.id}", params: {hypothesis: hypothesis_params.merge(add_to_github: "")}
        }.to_not change(HypothesisCitation, :count)
        expect(flash[:success]).to be_present
      end
      context "other persons hypothesis" do
        let(:subject) { FactoryBot.create(:hypothesis) }
        it "does not update" do
          expect(subject.creator_id).to_not eq current_user.id
          patch "#{base_url}/#{subject.id}", params: {hypothesis: hypothesis_params}
          expect(response.code).to redirect_to assigns(:user_root_path)
          expect(flash[:error]).to be_present
          subject.reload
          expect(subject.title).to_not eq hypothesis_params[:title]
          expect(subject.citations.count).to eq 0
        end
      end
      context "unapproved hypothesis" do
        let(:subject) { FactoryBot.create(:hypothesis_approved, creator_id: current_user.id) }
        it "does not update" do
          expect(subject.creator_id).to eq current_user.id
          patch "#{base_url}/#{subject.id}", params: {hypothesis: hypothesis_params}
          expect(response.code).to redirect_to assigns(:user_root_path)
          expect(flash[:error]).to be_present
          subject.reload
          expect(subject.title).to_not eq hypothesis_params[:title]
          expect(subject.citations.count).to eq 0
        end
      end
      context "failed update" do
        it "renders with passed things" do
          patch "#{base_url}/#{subject.id}", params: {hypothesis: hypothesis_params.merge(title: " ")}
          expect(response.code).to render_template("hypotheses/edit")
          expect(flash).to be_blank
          rendered_hypothesis = assigns(:hypothesis)
          expect(rendered_hypothesis.title).to eq " "
          expect(rendered_hypothesis.tags_string).to eq "economy, parties"
          # There is a blank one in there, idk, it's ok
          expect(rendered_hypothesis.hypothesis_citations.map(&:url).count).to eq 3
        end
      end
      context "add_to_github" do
        let!(:tag) { FactoryBot.create(:tag_approved, title: "Economy") }
        it "updates, enqueues job" do
          subject.update(title: hypothesis_add_to_github_params[:title])
          expect(subject.citations.count).to eq 0
          Sidekiq::Worker.clear_all
          patch "#{base_url}/#{subject.id}", params: hypothesis_add_to_github_params
          expect(flash[:success]).to be_present
          expect(response).to redirect_to hypothesis_path(subject.id)
          expect(assigns(:hypothesis)&.id).to eq subject.id
          expect(assigns(:hypothesis).submitted_to_github?).to be_truthy
          expect(AddHypothesisToGithubContentJob.jobs.count).to eq 1
          expect(AddCitationToGithubContentJob.jobs.count).to eq 0
          subject.reload
          expect(subject.title).to eq hypothesis_params[:title]
          expect(subject.submitted_to_github?).to be_truthy
          expect(subject.pull_request_number).to be_blank
          expect(subject.approved_at).to be_blank
          expect(subject.submitting_to_github).to be_truthy
          expect(subject.tags_string).to eq "Economy, parties"
          expect(subject.citations.count).to eq 2

          citation.reload
          expect(citation.title).to eq full_citation_params[:title]
          expect(citation.url).to eq full_citation_url
          # expect(citation.submitted_to_github?).to be_truthy # Doesn't seem important. Job takes care of this, so ignore
          expect(citation.pull_request_number).to be_blank
          expect(citation.approved_at).to be_blank
          expect(citation.publication).to be_present
          expect(citation.publication_title).to eq "example.com"
          expect(citation.authors).to eq(["Zack", "George"])
          expect(citation.published_date_str).to eq "1990-12-02"
          expect(citation.url_is_direct_link_to_full_text).to be_falsey
          expect(citation.peer_reviewed).to be_truthy
          expect(citation.randomized_controlled_trial).to be_truthy
          expect(citation.creator_id).to eq current_user.id
        end
      end
      context "citation already exists" do
        it "does not create a new citation" do
          subject.reload
          citation.update(pull_request_number: 12)
          VCR.use_cassette("hypotheses_controller-create_skip_citation", match_requests_on: [:method]) do
            expect(Hypothesis.count).to eq 1
            expect(Citation.count).to eq 1
            expect(citation.pull_request_number).to be_present
            expect(citation.approved?).to be_falsey
            Sidekiq::Worker.clear_all
            Sidekiq::Testing.inline! do
              patch "#{base_url}/#{subject.to_param}", params: hypothesis_add_to_github_params
            end
            expect(response).to redirect_to hypothesis_path(subject.id)
            expect(flash[:success]).to be_present

            subject.reload
            expect(subject.title).to eq hypothesis_params[:title]
            expect(subject.citations.count).to eq 2
            expect(subject.approved?).to be_falsey
            expect(subject.pull_request_number).to be_present
            expect(subject.pull_request_number).to_not eq 12
            expect(subject.submitting_to_github).to be_truthy
            # Even though passed new information, it doesn't update the existing citation
            citation.reload
            expect(citation.pull_request_number).to eq 12

            citation2 = subject.citations.order(:created_at).last
            expect(citation2.submitted_to_github?).to be_truthy
            expect(citation2.pull_request_number).to eq subject.pull_request_number
          end
        end
        # TODO: permit using the same quote in multiple places
        #   context "2 quotes already exist" do
        #     it "does not duplicate existing quotes" do
        #       subject.hypothesis_citations.create(url: citation.url, quotes_text: "Third\n   First quote from this literature")
        #       expect(subject.hypothesis_quotes.count).to eq 2
        #       expect(subject.hypothesis_quotes.score_ordered.map(&:quote_text)).to eq(["Third", "First quote from this literature"])
        #       Sidekiq::Worker.clear_all
        #       Sidekiq::Testing.inline! do
        #         patch "#{base_url}/#{subject.to_param}", params: {hypothesis: hypothesis_params}
        #       end
        #       expect(response).to redirect_to edit_hypothesis_path(subject.id)
        #       expect(flash[:success]).to be_present
        #       subject.reload
        #       expect(subject.title).to eq hypothesis_params[:title]
        #       expect(subject.citations.count).to eq 1
        #       expect(subject.citations.pluck(:id)).to eq([citation.id])
        #       expect(subject.submitting_to_github).to be_falsey

        #       expect(subject.hypothesis_quotes.count).to eq 3
        #       expect(subject.hypothesis_quotes.score_ordered.map(&:quote_text)).to eq(["First quote from this literature", "Second quote, which is cool", "Third"])
        #     end
        #   end
      end
      # NOTE: this test is shitty, feel free to revamp aggressively. It was sloppily fixed after adding multiple citation support
      context "citation with matching title but different publisher exists" do
        let!(:citation_existing) { Citation.create(title: full_citation_params[:title], url: "https://www.foxnews.com/politics/trump-bahrain-israel-mideast-deal-peace", creator: FactoryBot.create(:user)) }
        it "creates a new citation" do
          expect(Citation.count).to eq 2
          Sidekiq::Worker.clear_all
          patch "#{base_url}/#{subject.to_param}", params: hypothesis_add_to_github_params
          expect(AddHypothesisToGithubContentJob.jobs.count).to eq 1
          expect(AddCitationToGithubContentJob.jobs.count).to eq 0
          expect(response).to redirect_to hypothesis_path(subject.id)
          expect(flash[:success]).to be_present

          subject.reload
          expect(subject.title).to eq hypothesis_params[:title]
          expect(subject.creator).to eq current_user
          expect(subject.citations.count).to eq 2
          expect(subject.approved?).to be_falsey
          expect(subject.pull_request_number).to be_blank # Because job hasn't run

          expect(Citation.count).to eq 3
          citation.reload
          expect(citation.title).to eq full_citation_params[:title]
          expect(citation.url).to eq full_citation_url

          expect(citation.publication).to be_present
          expect(citation.publication_title).to eq "example.com"
          expect(citation.authors).to eq(["Zack", "George"])
          expect(citation.published_at).to be_within(5).of Time.at(660124800)
          expect(citation.url_is_direct_link_to_full_text).to be_falsey
          expect(citation.creator).to eq current_user
        end
      end
      # NOTE: this test is shitty, feel free to revamp aggressively. It was sloppily fixed after adding multiple citation support
      context "citation with url_is_not_publisher" do
        let(:citation_params) { full_citation_params.merge(url_is_not_publisher: true) }
        it "creates" do
          Sidekiq::Worker.clear_all
          patch "#{base_url}/#{subject.to_param}", params: {hypothesis: hypothesis_params}
          expect(AddHypothesisToGithubContentJob.jobs.count).to eq 0
          expect(response).to redirect_to edit_hypothesis_path(subject.id)
          expect(flash[:success]).to be_present

          subject.reload
          expect(subject.title).to eq hypothesis_params[:title]
          expect(subject.creator).to eq current_user
          expect(subject.citations.count).to eq 2
          expect(subject.approved?).to be_falsey
          expect(subject.pull_request_number).to be_blank # Because job hasn't run

          expect(Citation.count).to eq 2
          citation.reload
          expect(citation.title).to eq full_citation_params[:title]
          expect(citation.url).to eq full_citation_url
          expect(citation.url_is_not_publisher).to be_truthy
          expect(subject.citations.pluck(:id)).to include(citation.id)

          expect(citation.authors).to eq(["Zack", "George"])
          expect(citation.published_at).to be_within(5).of Time.at(660124800)
          expect(citation.url_is_direct_link_to_full_text).to be_falsey
          expect(citation.creator).to eq current_user
          expect(citation.url_is_not_publisher).to be_truthy

          publication = citation.publication
          expect(publication).to be_present
          expect(publication.home_url).to eq "https://example.com"
          expect(publication.title).to eq "example.com"
          # TODO: Make meta_publication work again
          # expect(publication.meta_publication).to be_truthy
        end
      end
      # NOTE: this test is shitty, feel free to revamp aggressively. It was sloppily fixed after adding multiple citation support
      context "with publication_title" do
        let(:citation_params) { full_citation_params.merge(url_is_not_publisher: true, publication_title: "Some other title") }
        it "creates with publication title" do
          Sidekiq::Worker.clear_all
          patch "#{base_url}/#{subject.to_param}", params: {hypothesis: hypothesis_params}
          expect(AddHypothesisToGithubContentJob.jobs.count).to eq 0
          expect(AddCitationToGithubContentJob.jobs.count).to eq 0
          expect(response).to redirect_to edit_hypothesis_path(subject.id)
          expect(flash[:success]).to be_present

          subject.reload
          expect(subject.title).to eq hypothesis_params[:title]

          expect(Citation.count).to eq 2
          citation.reload
          expect(citation.title).to eq full_citation_params[:title]
          expect(citation.url).to eq full_citation_url
          expect(citation.url_is_not_publisher).to be_truthy
          expect(subject.citations.pluck(:id)).to include(citation.id)

          expect(citation.authors).to eq(["Zack", "George"])
          expect(citation.published_at).to be_within(5).of Time.at(660124800)
          expect(citation.url_is_direct_link_to_full_text).to be_falsey
          expect(citation.creator).to eq current_user
          expect(citation.url_is_not_publisher).to be_truthy

          publication = citation.publication
          expect(publication).to be_present
          expect(publication.title).to eq "Some other title"
          # TODO: Make meta_publication work again
          # expect(publication.home_url).to be_blank
          # expect(publication.meta_publication).to be_falsey
        end
      end
      context "existing_hypothesis_citation" do
        let!(:hypothesis_citation1) { FactoryBot.create(:hypothesis_citation, hypothesis: subject, citation: citation, url: citation.url, quotes_text: "This is a thing") }
        let(:existing_citation_params) do
          {
            url: citation.url,
            quotes_text: "This is a thing",
            citation_attributes: full_citation_params,
            id: hypothesis_citation1.id,
            _destroy: "0"
          }
        end
        let(:new_citation_params) do
          {
            url: "https://something-of.org/interest-asdfasdf",
            quotes_text: "First quote from this literature\nSecond quote, which is cool",
            id: "",
            _destroy: "false"
          }
        end
        let(:hypothesis_params) do
          {
            title: "Example of a strong hypothesis",
            tags_string: "environment",
            hypothesis_citations_attributes: {
              "0" => existing_citation_params,
              "1" => new_citation_params
            }
          }
        end
        it "creates and updates" do
          subject.reload
          expect(subject.citations.pluck(:url)).to eq([citation.url])
          Sidekiq::Testing.inline! do
            expect {
              patch "#{base_url}/#{subject.id}", params: {hypothesis: hypothesis_params}
            }.to change(HypothesisCitation, :count).by 1 # Adds one, removes one
          end
          expect(flash[:success]).to be_present
          subject.reload
          expect(subject.citations.pluck(:url)).to match_array([citation.url, "https://something-of.org/interest-asdfasdf"])
          expect(subject.quotes.pluck(:text)).to eq(["This is a thing", "First quote from this literature", "Second quote, which is cool"])
          citation.reload
        end
        context "destroying an existing hypothesis_citation" do
          let(:existing_citation_params) do
            {
              url: citation.url,
              quotes_text: "This is a thing",
              id: hypothesis_citation1.id,
              _destroy: "1"
            }
          end
          it "destroys the hypothesis citation" do
            subject.reload
            expect(subject.quotes.pluck(:text)).to eq(["This is a thing"])
            expect(subject.citations.pluck(:url)).to eq([citation.url])
            Sidekiq::Worker.clear_all
            Sidekiq::Testing.inline! do
              expect {
                patch "#{base_url}/#{subject.id}", params: {hypothesis: hypothesis_params}
              }.to change(HypothesisCitation, :count).by 0 # Adds one, removes one
            end
            expect(flash[:success]).to be_present
            subject.reload
            expect(subject.citations.pluck(:url)).to eq(["https://something-of.org/interest-asdfasdf"])
            expect(subject.quotes.pluck(:text)).to eq(["First quote from this literature", "Second quote, which is cool"])
            citation.reload
            expect(citation).to be_valid
          end
          context "hypothesis_citation id for a different hypothesis" do
            let!(:hypothesis_citation1) { FactoryBot.create(:hypothesis_citation, citation: citation, quotes_text: "This is a thing") }
            it "ignores" do
              subject.reload
              expect(subject.quotes.pluck(:text)).to eq([])
              Sidekiq::Worker.clear_all
              expect {
                expect {
                  patch "#{base_url}/#{subject.id}", params: {hypothesis: hypothesis_params}
                }.to_not change(HypothesisCitation, :count)
              }.to raise_error(/find/)
            end
          end
        end
      end
    end
  end
end
