# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/citations", type: :request do
  let(:base_url) { "/citations" }

  it "renders" do
    get base_url
    expect(response).to render_template("citations/index")
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
        expect(response).to render_template("citations/index")
      end
    end

    describe "new" do
      it "renders" do
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("citations/new")
      end
    end

    describe "create" do
      let(:valid_citation_params) do
        {
          title: "Some cool new title",
          publication_name: "Some journal somewhere",
          assignable_kind: "peer_reviewed",
          authors_str: "\nZack\n George\n",
          published_at: "2020-1-22",
          url: "https://something.com"
        }
      end
      it "creates" do
        expect {
          post base_url, params: {citation: valid_citation_params}
        }.to change(Citation, :count).by 1
        expect(response).to redirect_to citations_path
        expect(flash[:success]).to be_present

        citation = Citation.last
        expect(citation.title).to eq valid_citation_params[:title]
        expect(citation.url).to eq valid_citation_params[:url]

        expect(citation.publication).to be_present
        expect(citation.publication_name).to eq valid_citation_params[:publication_name]
        expect(citation.authors).to eq(["Zack", "George"])
        expect(citation.published_at).to be_within(5).of Time.at(1579680000)
        expect(citation.creator).to eq current_user
      end
      context "invalid params" do
        # Real lazy ;)
        let(:invalid_citation_params) { valid_citation_params.except(:title) }
        it "does not create, does not explode" do
          expect {
            post base_url, params: {citation: invalid_citation_params}
          }.to_not change(Citation, :count)
        end
      end
    end
  end
end
