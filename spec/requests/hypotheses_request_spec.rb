# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/hypotheses", type: :request do
  let(:base_url) { "/hypotheses" }

  it "renders" do
    get base_url
    expect(response).to render_template("hypotheses/index")
  end

  describe "show" do
    let(:subject) { FactoryBot.create(:hypothesis) }
    it "renders" do
      get "#{base_url}/#{subject.to_param}"
      expect(response.code).to eq "200"
      expect(response).to render_template("hypotheses/show")
    end
  end

  describe "new" do
    it "redirects" do
      get "#{base_url}/new"
      expect(response).to redirect_to user_github_omniauth_authorize_path
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
      let(:tag) { FactoryBot.create(:tag, "Economy") }
      let(:valid_hypothesis_params) { {title: "This seems like the truth", tags_string: "economy\n"} }
      let(:valid_citation_params) do
        {
          title: "This citation is very important",
          assignable_kind: "article",
          url_is_direct_link_to_full_text: "0",
          authors_str: "\nZack\n George\n",
          published_date_str: "1990-12-2",
          url: "https://example.com/something-of-interest"
        }
      end
      it "creates" do
        expect(Hypothesis.count).to eq 0
        expect {
          post base_url, params: {hypothesis: valid_hypothesis_params}
        }.to change(Hypothesis, :count).by 1
        expect(response).to redirect_to hypotheses_path
        expect(flash[:success]).to be_present

        hypothesis = Hypothesis.last
        expect(hypothesis.title).to eq valid_hypothesis_params[:title]
        expect(hypothesis.creator).to eq current_user
        expect(hypothesis.citations.count).to eq 0
        expect(hypothesis.direct_quotation?).to be_falsey
      end
      context "invalid params" do
        # Real lazy ;)
        let(:invalid_hypothesis_params) { valid_hypothesis_params.merge(title: "") }
        it "does not create, does not explode" do
          expect {
            post base_url, params: {hypothesis: invalid_hypothesis_params}
          }.to_not change(Citation, :count)
        end
      end

      context "with citation" do
        let(:hypothesis_with_citation_params) do
          {
            title: "party time is now",
            has_direct_quotation: "1",
            tags_string: "parties, Economy",
            citations_attributes: valid_citation_params
          }
        end
        it "creates with citation" do
          expect(Hypothesis.count).to eq 0
          expect(Citation.count).to eq 0
          expect {
            post base_url, params: {hypothesis: hypothesis_with_citation_params}
          }.to change(Hypothesis, :count).by 1
          expect(response).to redirect_to hypotheses_path
          expect(flash[:success]).to be_present

          hypothesis = Hypothesis.last
          expect(hypothesis.title).to eq hypothesis_with_citation_params[:title]
          expect(hypothesis.creator).to eq current_user
          expect(hypothesis.citations.count).to eq 1
          expect(hypothesis.has_direct_quotation).to be_truthy
          expect(hypothesis.direct_quotation?).to be_truthy
          expect(hypothesis.tags_string).to eq "Economy, parties"

          expect(Citation.count).to eq 1
          citation = Citation.last
          expect(citation.title).to eq valid_citation_params[:title]
          expect(citation.url).to eq valid_citation_params[:url]
          expect(hypothesis.citations.pluck(:id)).to eq([citation.id])

          expect(citation.publication).to be_present
          expect(citation.publication_title).to eq "example.com"
          expect(citation.authors).to eq(["Zack", "George"])
          expect(citation.published_date_str).to eq "1990-12-02"
          expect(citation.url_is_direct_link_to_full_text).to be_falsey
          expect(citation.creator).to eq current_user
        end

        context "citation already exists" do
          let!(:citation) { Citation.create(url: valid_citation_params[:url], creator: FactoryBot.create(:user)) }
          it "does not create a new citation" do
            expect(Hypothesis.count).to eq 0
            expect(Citation.count).to eq 1
            expect(citation.title).to eq "something-of-interest"
            expect {
              post base_url, params: {hypothesis: hypothesis_with_citation_params}
            }.to change(Hypothesis, :count).by 1
            expect(response).to redirect_to hypotheses_path
            expect(flash[:success]).to be_present

            hypothesis = Hypothesis.last
            expect(hypothesis.title).to eq hypothesis_with_citation_params[:title]
            expect(hypothesis.creator).to eq current_user
            expect(hypothesis.citations.count).to eq 1
            expect(hypothesis.has_direct_quotation).to be_truthy
            expect(hypothesis.direct_quotation?).to be_truthy
            expect(hypothesis.citations.pluck(:id)).to eq([citation.id])
            # Even though passed new information, it doesn't update the existing citation
            citation.reload
            expect(citation.title).to eq "something-of-interest"
          end
        end
        context "citation with matching title but different publisher exists" do
          let!(:citation) { Citation.create(title: valid_citation_params[:title], url: "https://www.foxnews.com/politics/trump-bahrain-israel-mideast-deal-peace", creator: FactoryBot.create(:user)) }
          it "creates a new citation" do
            expect(Hypothesis.count).to eq 0
            expect(Citation.count).to eq 1
            expect {
              post base_url, params: {hypothesis: hypothesis_with_citation_params}
            }.to change(Hypothesis, :count).by 1
            expect(response).to redirect_to hypotheses_path
            expect(flash[:success]).to be_present

            hypothesis = Hypothesis.last
            expect(hypothesis.title).to eq hypothesis_with_citation_params[:title]
            expect(hypothesis.creator).to eq current_user
            expect(hypothesis.citations.count).to eq 1
            expect(hypothesis.has_direct_quotation).to be_truthy
            expect(hypothesis.direct_quotation?).to be_truthy

            expect(Citation.count).to eq 2
            citation = Citation.last
            expect(citation.title).to eq valid_citation_params[:title]
            expect(citation.url).to eq valid_citation_params[:url]
            expect(hypothesis.citations.pluck(:id)).to eq([citation.id])

            expect(citation.publication).to be_present
            expect(citation.publication_title).to eq "example.com"
            expect(citation.authors).to eq(["Zack", "George"])
            expect(citation.published_at).to be_within(5).of Time.at(660124800)
            expect(citation.url_is_direct_link_to_full_text).to be_falsey
            expect(citation.creator).to eq current_user
          end
        end
      end
    end
  end
end
