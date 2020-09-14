# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/publications", type: :request do
  let(:base_url) { "/publications" }

  it "renders" do
    get base_url
    expect(response.code).to eq "200"
    expect(response).to render_template("publications/index")
  end

  describe "show" do
    let(:subject) { FactoryBot.create(:publication) }
    it "renders" do
      get "#{base_url}/#{subject.to_param}"
      expect(response.code).to eq "200"
      expect(response).to render_template("publications/show")
    end
  end
end
