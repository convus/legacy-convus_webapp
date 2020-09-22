# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "TitleSluggable" do
  let(:model_sym) { subject.class.name.underscore.to_sym }
  let(:instance) { FactoryBot.create model_sym }

  it "has callback for set_slug" do
    expect(subject.class._validation_callbacks.select { |cb| cb.kind.eql?(:before) }
      .map(&:raw_filter).include?(:set_slug)).to be_truthy
  end

  describe "friendly_find" do
    before { expect(instance).to be_present }
    context "integer_slug" do
      it "finds integers and fails without error" do
        expect(subject.class.friendly_find("#{instance.id} ")).to eq instance
        expect(subject.class.friendly_find("12812812812")).to be_blank # Doesn't raise
      end
    end

    context "not integer slug" do
      it "finds by the slug and fails without error" do
        str = " #{instance.title.upcase}\n"
        expect(subject.class.friendly_find(str)).to eq instance
        expect(subject.class.friendly_find("gasdfa87")).to be_blank # Doesn't raise
      end
    end

    context "bang method vs non-bang" do
      it "returns nil or raises" do
        expect(subject.class.friendly_find("666-party")).to be_nil
        expect {
          subject.class.friendly_find!("666-party")
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
