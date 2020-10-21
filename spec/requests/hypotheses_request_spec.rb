# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/hypotheses", type: :request do
  let(:base_url) { "/hypotheses" }
  let(:full_citation_params) do
    {
      title: "Testing hypothesis creation is very important",
      assignable_kind: "article",
      url_is_direct_link_to_full_text: "0",
      authors_str: "\nZack\n George\n",
      published_date_str: "1990-12-2",
      url_is_not_publisher: false,
      url: "https://example.com/something-of-interest"
    }
  end

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
    let(:subject) { FactoryBot.create(:hypothesis_approved) }
    it "renders" do
      expect(subject.approved?).to be_truthy
      get "#{base_url}/#{subject.to_param}"
      expect(response.code).to eq "200"
      expect(response).to render_template("hypotheses/show")

      get "/#{subject.file_path}"
      expect(response.code).to eq "200"
      expect(response).to render_template("hypotheses/show")
      expect(assigns(:hypothesis)).to eq subject

      get "#{base_url}/#{subject.id}"
      expect(response.code).to eq "200"
      expect(response).to render_template("hypotheses/show")
      expect(assigns(:hypothesis)).to eq subject
    end
    context "unapproved" do
      let(:subject) { FactoryBot.create(:hypothesis) }
      it "renders" do
        expect(subject.approved?).to be_falsey
        get "#{base_url}/#{subject.to_param}"
        expect(response.code).to eq "200"
        expect(response).to render_template("hypotheses/show")
      end
    end
  end

  describe "new" do
    it "redirects" do
      get "#{base_url}/new"
      expect(response).to redirect_to user_github_omniauth_authorize_path
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
      let(:simple_hypothesis_params) { {title: "This seems like the truth", tags_string: "economy\n", citations_attributes: citation_params} }
      let(:citation_params) do
        {
          url: "https://example.com/something-of-interest",
          quotes_text: "a quote from this article\n and another quote from it\n"
        }
      end
      it "creates" do
        expect(Hypothesis.count).to eq 0
        Sidekiq::Worker.clear_all
        Sidekiq::Testing.inline! do
          expect {
            post base_url, params: {hypothesis: simple_hypothesis_params.merge(approved_at: Time.current.to_s)}
          }.to change(Hypothesis, :count).by 1
        end
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

        expect(hypothesis.citations.count).to eq 1
        citation = hypothesis.citations.first
        expect(citation.url).to eq citation_params[:url]

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
        # TODO: test that this deals with multiple citations
        let(:invalid_hypothesis_params) { simple_hypothesis_params.merge(title: "", citations_attributes: citation_params.merge(url: " ")) }
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
          expect(errored_hypothesis.hypothesis_citations.map(&:quotes_text).count).to eq 2
          errored_citation = errored_hypothesis.hypothesis_citations.first.citation
          expect(errored_citation.url).to be_blank
          expect(errored_citation.quotes_text).to eq("a quote from this article\n\nand another quote from it")
        end
      end

      # NOTE: IRL hypotheses will be created before they are add_to_github, but this is illustrative
      # context "full_citation_params and add_to_github" do
      #   let!(:tag) { FactoryBot.create(:tag_approved, title: "Economy") }
      #   let(:valid_hypothesis_params) { {title: "This seems like the truth", tags_string: "economy\n", add_to_github: true} }
      #   it "creates" do
      #     VCR.use_cassette("hypotheses_controller-create_with_citation", match_requests_on: [:method]) do
      #       expect(Hypothesis.count).to eq 0
      #       Sidekiq::Worker.clear_all
      #       Sidekiq::Testing.inline! do
      #         expect {
      #           post base_url, params: {hypothesis: valid_hypothesis_params.merge(approved_at: Time.current.to_s)}
      #         }.to change(Hypothesis, :count).by 1
      #       end
      #       expect(response).to redirect_to hypothesis_path(Hypothesis.last.to_param)
      #       expect(flash[:success]).to be_present

      #       hypothesis = Hypothesis.last
      #       expect(hypothesis.title).to eq valid_hypothesis_params[:title]
      #       expect(hypothesis.creator).to eq current_user
      #       expect(hypothesis.citations.count).to eq 0
      #       expect(hypothesis.pull_request_number).to be_present
      #       expect(hypothesis.approved?).to be_falsey
      #       expect(hypothesis.tags.pluck(:id)).to eq([tag.id])
      #     end
      #   end

      #   context "with citation" do
      #     let(:hypothesis_with_citation_params) do
      #       {
      #         title: "Testing party time is now",
      #         tags_string: "parties, Economy",
      #         citations_attributes: full_citation_params,
      #         add_to_github: true
      #       }
      #     end
      #     it "creates with citation" do
      #       VCR.use_cassette("hypotheses_controller-create_with_citation", match_requests_on: [:method]) do
      #         expect(Hypothesis.count).to eq 0
      #         expect(Citation.count).to eq 0
      #         Sidekiq::Worker.clear_all
      #         Sidekiq::Testing.inline! do
      #           expect {
      #             post base_url, params: {hypothesis: hypothesis_with_citation_params.merge()}
      #           }.to change(Hypothesis, :count).by 1
      #         end
      #         expect(response).to redirect_to hypothesis_path(Hypothesis.last.to_param)
      #         expect(flash[:success]).to be_present

      #         hypothesis = Hypothesis.last
      #         expect(hypothesis.title).to eq hypothesis_with_citation_params[:title]
      #         expect(hypothesis.creator).to eq current_user
      #         expect(hypothesis.citations.count).to eq 1
      #         expect(hypothesis.tags_string).to eq "Economy, parties"
      #         expect(hypothesis.pull_request_number).to be_present
      #         expect(hypothesis.approved?).to be_falsey
      #         expect(tag.approved?).to be_truthy
      #         expect(Tag.friendly_find("parties").approved?).to be_falsey

      #         expect(Citation.count).to eq 1
      #         citation = Citation.last
      #         expect(citation.title).to eq full_citation_params[:title]
      #         expect(citation.url).to eq full_citation_params[:url]
      #         expect(hypothesis.citations.pluck(:id)).to eq([citation.id])
      #         expect(citation.approved?).to be_falsey
      #         expect(citation.pull_request_number).to eq hypothesis.pull_request_number # Because they're created together

      #         expect(citation.publication).to be_present
      #         expect(citation.publication_title).to eq "example.com"
      #         expect(citation.authors).to eq(["Zack", "George"])
      #         expect(citation.published_date_str).to eq "1990-12-02"
      #         expect(citation.url_is_direct_link_to_full_text).to be_falsey
      #         expect(citation.creator).to eq current_user
      #       end
      #     end
      #     context "peer_reviewed and randomized_controlled_trial, not assignable_kind" do
      #       it "creates" do
      #         expect(Hypothesis.count).to eq 0
      #         expect(Citation.count).to eq 0
      #         Sidekiq::Worker.clear_all
      #         expect {
      #           post base_url, params: {hypothesis: hypothesis_with_citation_params}
      #         }.to change(Hypothesis, :count).by 1
      #         expect(AddHypothesisToGithubContentJob.jobs.count).to eq 1
      #         expect(response).to redirect_to hypothesis_path(Hypothesis.last.to_param)
      #         expect(flash[:success]).to be_present

      #         hypothesis = Hypothesis.last
      #         expect(hypothesis.title).to eq hypothesis_with_citation_params[:title]
      #         expect(hypothesis.creator).to eq current_user
      #         expect(hypothesis.citations.count).to eq 1
      #         expect(hypothesis.tags_string).to eq "Economy, parties"
      #         expect(hypothesis.pull_request_number).to be_blank
      #         expect(hypothesis.approved?).to be_falsey
      #         expect(tag.approved?).to be_truthy
      #         expect(Tag.friendly_find("parties").approved?).to be_falsey

      #         expect(Citation.count).to eq 1
      #         citation = Citation.last
      #         expect(citation.title).to eq full_citation_params[:title]
      #         expect(citation.url).to eq full_citation_params[:url]
      #         expect(hypothesis.citations.pluck(:id)).to eq([citation.id])
      #         expect(citation.approved?).to be_falsey

      #         expect(citation.publication).to be_present
      #         expect(citation.publication_title).to eq "example.com"
      #         expect(citation.authors).to eq(["Zack", "George"])
      #         expect(citation.published_date_str).to eq "1990-12-02"
      #         expect(citation.url_is_direct_link_to_full_text).to be_falsey
      #         expect(citation.peer_reviewed).to be_truthy
      #         expect(citation.randomized_controlled_trial).to be_truthy
      #         expect(citation.creator).to eq current_user
      #       end
      #     end

      #     context "citation already exists" do
      #       let!(:citation) { Citation.create(url: full_citation_params[:url], creator: FactoryBot.create(:user), pull_request_number: 12) }
      #       it "does not create a new citation" do
      #         VCR.use_cassette("hypotheses_controller-create_skip_citation", match_requests_on: [:method]) do
      #           expect(Hypothesis.count).to eq 0
      #           expect(Citation.count).to eq 1
      #           expect(citation.title).to eq "something-of-interest"
      #           expect(citation.pull_request_number).to be_present
      #           expect(citation.approved?).to be_falsey
      #           Sidekiq::Worker.clear_all
      #           Sidekiq::Testing.inline! do
      #             expect {
      #               post base_url, params: {hypothesis: hypothesis_with_citation_params}
      #             }.to change(Hypothesis, :count).by 1
      #           end
      #           expect(response).to redirect_to hypothesis_path(Hypothesis.last.to_param)
      #           expect(flash[:success]).to be_present

      #           hypothesis = Hypothesis.last
      #           expect(hypothesis.title).to eq hypothesis_with_citation_params[:title]
      #           expect(hypothesis.creator).to eq current_user
      #           expect(hypothesis.citations.count).to eq 1
      #           expect(hypothesis.citations.pluck(:id)).to eq([citation.id])
      #           expect(hypothesis.approved?).to be_falsey
      #           expect(hypothesis.pull_request_number).to be_present
      #           expect(hypothesis.pull_request_number).to_not eq 12
      #           # Even though passed new information, it doesn't update the existing citation
      #           citation.reload
      #           expect(citation.title).to eq "something-of-interest"
      #           expect(citation.pull_request_number).to eq 12
      #         end
      #       end
      #     end
      #     context "citation with matching title but different publisher exists" do
      #       let!(:citation) { Citation.create(title: full_citation_params[:title], url: "https://www.foxnews.com/politics/trump-bahrain-israel-mideast-deal-peace", creator: FactoryBot.create(:user)) }
      #       it "creates a new citation" do
      #         expect(Hypothesis.count).to eq 0
      #         expect(Citation.count).to eq 1
      #         Sidekiq::Worker.clear_all
      #         expect {
      #           post base_url, params: {hypothesis: hypothesis_with_citation_params}
      #         }.to change(Hypothesis, :count).by 1
      #         expect(AddHypothesisToGithubContentJob.jobs.count).to eq 1
      #         expect(AddCitationToGithubContentJob.jobs.count).to eq 0
      #         expect(response).to redirect_to hypothesis_path(Hypothesis.last.to_param)
      #         expect(flash[:success]).to be_present

      #         hypothesis = Hypothesis.last
      #         expect(hypothesis.title).to eq hypothesis_with_citation_params[:title]
      #         expect(hypothesis.creator).to eq current_user
      #         expect(hypothesis.citations.count).to eq 1
      #         expect(hypothesis.approved?).to be_falsey
      #         expect(hypothesis.pull_request_number).to be_blank # Because job hasn't run

      #         expect(Citation.count).to eq 2
      #         citation = Citation.last
      #         expect(citation.title).to eq full_citation_params[:title]
      #         expect(citation.url).to eq full_citation_params[:url]
      #         expect(hypothesis.citations.pluck(:id)).to eq([citation.id])

      #         expect(citation.publication).to be_present
      #         expect(citation.publication_title).to eq "example.com"
      #         expect(citation.authors).to eq(["Zack", "George"])
      #         expect(citation.published_at).to be_within(5).of Time.at(660124800)
      #         expect(citation.url_is_direct_link_to_full_text).to be_falsey
      #         expect(citation.creator).to eq current_user
      #       end
      #     end
      #     context "citation with url_is_not_publisher" do
      #       let(:citation_params) { full_citation_params.merge(url_is_not_publisher: true) }
      #       let(:citation_url_not_publisher_params) { hypothesis_with_citation_params.merge(citations_attributes: citation_params) }
      #       it "creates" do
      #         expect(Hypothesis.count).to eq 0
      #         expect(Citation.count).to eq 0
      #         Sidekiq::Worker.clear_all
      #         expect {
      #           post base_url, params: {hypothesis: citation_url_not_publisher_params}
      #         }.to change(Hypothesis, :count).by 1
      #         expect(AddHypothesisToGithubContentJob.jobs.count).to eq 1
      #         expect(AddCitationToGithubContentJob.jobs.count).to eq 0
      #         expect(response).to redirect_to hypothesis_path(Hypothesis.last.to_param)
      #         expect(flash[:success]).to be_present

      #         hypothesis = Hypothesis.last
      #         expect(hypothesis.title).to eq citation_url_not_publisher_params[:title]
      #         expect(hypothesis.creator).to eq current_user
      #         expect(hypothesis.citations.count).to eq 1
      #         expect(hypothesis.approved?).to be_falsey
      #         expect(hypothesis.pull_request_number).to be_blank # Because job hasn't run

      #         expect(Citation.count).to eq 1
      #         citation = Citation.last
      #         expect(citation.title).to eq full_citation_params[:title]
      #         expect(citation.url).to eq full_citation_params[:url]
      #         expect(citation.url_is_not_publisher).to be_truthy
      #         expect(hypothesis.citations.pluck(:id)).to eq([citation.id])

      #         expect(citation.authors).to eq(["Zack", "George"])
      #         expect(citation.published_at).to be_within(5).of Time.at(660124800)
      #         expect(citation.url_is_direct_link_to_full_text).to be_falsey
      #         expect(citation.creator).to eq current_user

      #         publication = citation.publication
      #         expect(publication).to be_present
      #         expect(publication.meta_publication).to be_truthy
      #         expect(publication.home_url).to eq "https://example.com"
      #         expect(publication.title).to eq "example.com"
      #       end
      #       context "with publication_title" do
      #         let(:citation_params) { full_citation_params.merge(url_is_not_publisher: true, publication_title: "Some other title") }
      #         it "creates with publication title" do
      #           expect(Hypothesis.count).to eq 0
      #           expect(Citation.count).to eq 0
      #           Sidekiq::Worker.clear_all
      #           expect {
      #             post base_url, params: {hypothesis: citation_url_not_publisher_params}
      #           }.to change(Hypothesis, :count).by 1
      #           expect(AddHypothesisToGithubContentJob.jobs.count).to eq 1
      #           expect(AddCitationToGithubContentJob.jobs.count).to eq 0
      #           expect(response).to redirect_to hypothesis_path(Hypothesis.last.to_param)
      #           expect(flash[:success]).to be_present

      #           hypothesis = Hypothesis.last
      #           expect(hypothesis.title).to eq citation_url_not_publisher_params[:title]

      #           expect(Citation.count).to eq 1
      #           citation = Citation.last
      #           expect(citation.title).to eq full_citation_params[:title]
      #           expect(citation.url).to eq full_citation_params[:url]
      #           expect(citation.url_is_not_publisher).to be_truthy
      #           expect(hypothesis.citations.pluck(:id)).to eq([citation.id])

      #           expect(citation.authors).to eq(["Zack", "George"])
      #           expect(citation.published_at).to be_within(5).of Time.at(660124800)
      #           expect(citation.url_is_direct_link_to_full_text).to be_falsey
      #           expect(citation.creator).to eq current_user

      #           publication = citation.publication
      #           expect(publication).to be_present
      #           expect(publication.meta_publication).to be_falsey
      #           expect(publication.home_url).to be_blank
      #           expect(publication.title).to eq "Some other title"
      #         end
      #       end
      #     end
      #   end
      # end
    end
  end
end
