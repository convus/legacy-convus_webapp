# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "GithubSubmittable" do
  let(:model_sym) { subject.class.name.underscore.to_sym }

  describe "submitted_to_github?" do
    context "not submitted" do
      let!(:instance) { FactoryBot.create model_sym }
      it "is false" do
        expect(instance.submitted_to_github?).to be_falsey
        expect(instance.not_submitted_to_github?).to be_truthy
        expect(instance.class.submitted_to_github.pluck(:id)).to eq([])
        expect(instance.class.not_submitted_to_github.pluck(:id)).to eq([instance.id])
      end
    end
    context "approved_at" do
      let!(:instance) { FactoryBot.create(model_sym, approved_at: Time.current) }
      it "is truthy" do
        expect(instance.submitted_to_github?).to be_truthy
        expect(instance.not_submitted_to_github?).to be_falsey
        expect(instance.class.submitted_to_github.pluck(:id)).to eq([instance.id])
      end
    end
    context "pull request number" do
      let!(:instance) { FactoryBot.create(model_sym, pull_request_number: 12) }
      it "is truthy" do
        expect(instance.submitted_to_github?).to be_truthy
        expect(instance.not_submitted_to_github?).to be_falsey
        expect(instance.class.submitted_to_github.pluck(:id)).to eq([instance.id])
      end
    end
    context "submitting_to_github" do
      let!(:instance) { FactoryBot.create(model_sym, submitting_to_github: true) }
      it "is truthy" do
        expect(instance.submitted_to_github?).to be_truthy
        expect(instance.not_submitted_to_github?).to be_falsey
        expect(instance.class.submitted_to_github.pluck(:id)).to eq([instance.id])
      end
    end
  end
end
