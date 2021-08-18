# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "ReferenceIdable" do
  let(:model_sym) { subject.class.name.underscore.to_sym }

  it "sets reference_id" do
    subject = FactoryBot.create(model_sym, reference_id: nil)
    expect(subject).to be_valid
    expect(subject.id).to be_present
    expect(subject.reference_id).to be_present
    expect(subject.provisional_reference_id).to eq subject.reference_id
  end

  # describe "provisional_id" do
  #   let(:subject) { FactoryBot.new(model_sym, provisional_reference_id: "ab-12") }
  #   it "is accessable" do
  #     expect(subject.provisional_reference_id).to eq "ab-12"
  #     subject.save
  #     expect(subject.provisional_reference_id).to eq "ab-12"
  #     expect(subject.reference_id).to be_present
  #     expect(subject.reference_id).to_not eq "ab-12"
  #     expect(subject.reload.provisional_reference_id).to eq subject.reference_id
  #   end
  # end
end
