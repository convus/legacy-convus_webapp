# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/", type: :request do
  describe "root" do
    it "renders" do
      get "/"
      expect(response.code).to eq "200"
      expect(response).to render_template("hypotheses/index")
    end
  end

  describe "/about" do
    it "renders" do
      get "/about"
      expect(response.code).to eq "200"
      expect(response).to render_template("static/about")
    end
  end
end
