# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/citations", type: :request do
  let(:base_url) { "/citations" }

  it "renders" do
    get base_url
    expect(response).to render_template("citations/index")
  end

  describe "show" do
    let!(:subject) { FactoryBot.create(:citation, publication_title: "Fox News", title: "some research into things") }
    it "renders" do
      expect(subject.unapproved?).to be_truthy
      get "#{base_url}/#{subject.slug}"
      expect(response.code).to eq "200"
      expect(response).to render_template("citations/show")
      expect(assigns(:citation)).to eq subject
      # Test that it sets the right title
      title_tag = response.body[/<title.*<\/title>/]
      expect(title_tag).to eq "<title>#{subject.publication_title}: #{subject.title}</title>"

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
    context "approved" do
      let(:subject) { FactoryBot.create(:citation_approved) }
      it "renders" do
        expect(subject.approved?).to be_truthy
        get "#{base_url}/#{subject.path_slug}"
        expect(response.code).to eq "200"
        expect(response).to render_template("citations/show")
        expect(assigns(:citation)).to eq subject
      end
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
  end
end
