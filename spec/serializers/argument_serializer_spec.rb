# frozen_string_literal: true

require "rails_helper"

describe ArgumentSerializer, type: :lib do
  let(:obj) { FactoryBot.create(:argument, text: text) }
  let(:serializer) { described_class.new(obj, root: false) }

  describe "output" do
    let(:text) { "something that I'm arguing about and other stuff,\nhere is something else\n\n> Quote to stuff\n\n"}
    let!(:argument_quote1) { FactoryBot.create(:argument_quote, argument: obj, url: "https://stuff.com") }
    let(:target) do
      {
        id: obj.ref_number,
        text: text,
        quote_urls: [
          "https://stuff.com"
        ]
      }
    end
    it "returns the expected output" do
      expect(serializer.as_json).to eq target
    end
  end
end
