# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/citations", type: :request do
  let(:base_url) { "/citations" }

  it "renders" do
    get base_url
    expect(response).to render_template("citations/index")
  end

  describe "new" do
    it "redirects" do
      get "#{base_url}/new"
      expect(response).to redirect_to user_github_omniauth_authorize_path
    end
  end

  describe "show" do
    let!(:subject) { FactoryBot.create(:citation, publication_title: "Fox News", title: "some research into things") }
    it "renders" do
      get "#{base_url}/#{subject.slug}"
      expect(response.code).to eq "200"
      expect(response).to render_template("citations/show")
      expect(assigns(:citation)).to eq subject

      get "#{base_url}/#{subject.path_slug}"
      expect(response.code).to eq "200"
      expect(response).to render_template("citations/show")
      expect(assigns(:citation)).to eq subject

      get "#{base_url}/fox-news/#{subject.slug}"
      expect(response.code).to eq "200"
      expect(response).to render_template("citations/show")
      expect(assigns(:citation)).to eq subject

      get "#{base_url}/fox-news/#{subject.slug}.yml"
      expect(response.code).to eq "200"
      expect(response).to render_template("citations/show")
      expect(assigns(:citation)).to eq subject
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
      let!(:publication) { FactoryBot.create(:publication, title: "Fox News", home_url: "foxnews.com") }
      let(:valid_citation_params) do
        {
          title: "The Atlantic calls to 'end the Nobel Peace Prize' following Trump nominations",
          assignable_kind: "article",
          url_is_direct_link_to_full_text: "1",
          authors_str: " Joseph A. Wulfsohn",
          published_date_str: "2020-09-11",
          url: "https://www.foxnews.com/media/the-atlantic-end-nobel-peace-prize-trump"
        }
      end
      it "creates" do
        expect(Citation.count).to eq 0
        expect {
          post base_url, params: {citation: valid_citation_params}
        }.to change(Citation, :count).by 1
        citation = Citation.last
        expect(flash[:success]).to be_present
        expect(response).to redirect_to citation_path(citation.to_param)

        expect(citation.title).to eq valid_citation_params[:title]
        expect(citation.url).to eq valid_citation_params[:url]
        expect(citation.authors).to eq(["Joseph A. Wulfsohn"])
        expect(citation.published_date_str).to eq "2020-09-11"
        expect(citation.url_is_direct_link_to_full_text).to be_truthy
        expect(citation.creator).to eq current_user

        publication.reload
        expect(citation.publication).to eq publication
        expect(publication.base_domains).to eq(["foxnews.com", "www.foxnews.com"])
      end
    end
  end
end
