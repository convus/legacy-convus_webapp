# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/assertions", type: :request do
  let(:base_url) { "/assertions" }

  it "renders" do
    get base_url
    expect(response).to render_template("assertions/index")
  end

  describe "new" do
    it "renders" do
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
        expect(response).to render_template("assertions/index")
      end
    end

    describe "new" do
      it "renders" do
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("assertions/new")
      end
    end

    describe "create" do
      let(:valid_assertion_params) { { title: "This seems like the truth" } }
      let(:valid_citation_params) do
        {
          title: "This citation is very important",
          publication_name: "A friends blog",
          assignable_kind: "article",
          url_is_direct_link_to_full_text: "0",
          authors_str: "\nZack\n George\n",
          published_at_str: "1990-12-2",
          url: "https://example.com"
        }
      end
      it "creates" do
        expect(Assertion.count).to eq 0
        expect {
          post base_url, params: {assertion: valid_assertion_params}
        }.to change(Assertion, :count).by 1
        expect(response).to redirect_to assertions_path
        expect(flash[:success]).to be_present

        assertion = Assertion.last
        expect(assertion.title).to eq valid_assertion_params[:title]
        expect(assertion.creator).to eq current_user
        expect(assertion.citations.count).to eq 0
        expect(assertion.direct_quotation?).to be_falsey
      end
      context "invalid params" do
        # Real lazy ;)
        let(:invalid_assertion_params) { valid_assertion_params.merge(title: "") }
        it "does not create, does not explode" do
          expect {
            post base_url, params: {assertion: invalid_assertion_params}
          }.to_not change(Citation, :count)
        end
      end

      context "with citation" do
        let(:assertion_with_citation_params) do
          {
            title: "party time is now",
            has_direct_quotation: "1",
            citations_attributes: {
              Time.current.to_i.to_s => valid_citation_params
            }
          }
        end
        it "creates with citation" do
          expect(Assertion.count).to eq 0
          expect(Citation.count).to eq 0
          expect {
            post base_url, params: {assertion: assertion_with_citation_params}
          }.to change(Assertion, :count).by 1
          expect(response).to redirect_to assertions_path
          expect(flash[:success]).to be_present

          assertion = Assertion.last
          expect(assertion.title).to eq assertion_with_citation_params[:title]
          expect(assertion.creator).to eq current_user
          expect(assertion.citations.count).to eq 1
          expect(assertion.has_direct_quotation).to be_truthy
          expect(assertion.direct_quotation?).to be_truthy

          expect(Citation.count).to eq 1
          citation = Citation.last
          expect(citation.title).to eq valid_citation_params[:title]
          expect(citation.url).to eq valid_citation_params[:url]
          expect(assertion.citations.pluck(:id)).to eq([citation.id])

          expect(citation.publication).to be_present
          expect(citation.publication_name).to eq valid_citation_params[:publication_name]
          expect(citation.authors).to eq(["Zack", "George"])
          expect(citation.published_at).to be_within(5).of Time.at(660124800)
          expect(citation.url_is_direct_link_to_full_text).to be_falsey
          expect(citation.creator).to eq current_user
        end
      end
    end
  end
end
