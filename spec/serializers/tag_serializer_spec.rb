# frozen_string_literal: true

require "rails_helper"

describe TagSerializer, type: :lib do
  let(:obj) { FactoryBot.create(:tag) }
  let(:serializer) { described_class.new(obj, root: false) }

  it "makes a hash" do
    expect(serializer.as_json.is_a?(Hash)).to be_truthy
  end
end