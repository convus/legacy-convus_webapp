# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "GithubSubmittable" do
  let(:model_sym) { subject.class.name.underscore.to_sym }

  describe "submitted_to_github?" do
    context "not submitted" do
      let!(:instance) { FactoryBot.create model_sym }
      it "is false" do
        expect(instance.submitted_to_github?).to be_falsey
        expect(instance.waiting_on_github?).to be_falsey
        expect(instance.not_submitted_to_github?).to be_truthy
        expect(instance.class.submitted_to_github.pluck(:id)).to eq([])
        expect(instance.class.not_submitted_to_github.pluck(:id)).to eq([instance.id])
      end
    end
    context "approved_at" do
      let!(:instance) { FactoryBot.create(model_sym, approved_at: Time.current) }
      it "is truthy" do
        expect(instance.submitted_to_github?).to be_truthy
        expect(instance.waiting_on_github?).to be_falsey
        expect(instance.not_submitted_to_github?).to be_falsey
        expect(instance.class.submitted_to_github.pluck(:id)).to eq([instance.id])
      end
    end
    context "pull request number" do
      let!(:instance) { FactoryBot.create(model_sym, pull_request_number: 12) }
      it "is truthy" do
        expect(instance.submitted_to_github?).to be_truthy
        expect(instance.waiting_on_github?).to be_truthy
        expect(instance.not_submitted_to_github?).to be_falsey
        expect(instance.class.submitted_to_github.pluck(:id)).to eq([instance.id])
      end
    end
    context "submitting_to_github" do
      let!(:instance) { FactoryBot.create(model_sym, submitting_to_github: true) }
      it "is truthy" do
        expect(instance.submitted_to_github?).to be_truthy
        expect(instance.waiting_on_github?).to be_truthy
        expect(instance.not_submitted_to_github?).to be_falsey
        expect(instance.class.submitted_to_github.pluck(:id)).to eq([instance.id])
        expect(instance.class.approved.pluck(:id)).to eq([])
        expect(instance.class.removed.pluck(:id)).to eq([])
        expect(instance.class.not_removed.pluck(:id)).to eq([instance.id])
      end
    end
    describe "removed?" do
      let(:instance) { FactoryBot.create(model_sym, pull_request_number: 133, removed_pull_request_number: 333) }
      it "is falsey" do
        expect(instance.submitted_to_github?).to be_falsey
        expect(instance.waiting_on_github?).to be_falsey
        expect(instance.not_submitted_to_github?).to be_falsey
        expect(instance.removed?).to be_truthy
        expect(instance.class.submitted_to_github.pluck(:id)).to eq([])
        expect(instance.class.removed.pluck(:id)).to eq([instance.id])
        expect(instance.class.not_removed.pluck(:id)).to eq([])
        expect(instance.approved?).to be_falsey
        expect(instance.unapproved?).to be_falsey
        expect(instance.class.approved.pluck(:id)).to eq([])
        expect(instance.class.unapproved.pluck(:id)).to eq([])
      end
    end
  end

  describe "editable_by? and shown" do
    let(:user) { FactoryBot.create(:user) }
    let(:instance) { FactoryBot.create model_sym }
    it "is false" do
      expect(instance.editable_by?).to be_falsey
      expect(instance.editable_by?(user)).to be_falsey
      expect(instance.shown?).to be_falsey
      expect(instance.shown?(user)).to be_falsey
      expect(subject.class.shown.pluck(:id)).to eq([])
      expect(subject.class.shown(user).pluck(:id)).to eq([])
    end
    context "user creator" do
      let(:instance) { FactoryBot.create(model_sym, creator: user) }
      it "is truthy" do
        expect(instance.editable_by?(user)).to be_truthy
        expect(instance.shown?).to be_falsey
        expect(instance.shown?(user)).to be_truthy
        expect(subject.class.shown.pluck(:id)).to eq([])
        expect(subject.class.shown(user).pluck(:id)).to eq([instance.id])
      end
      context "submitting_to_github" do
        let(:instance) { FactoryBot.create(model_sym, creator: user, submitting_to_github: true) }
        it "is falsey" do
          expect(instance.editable_by?(user)).to be_falsey
          expect(instance.shown?).to be_falsey
          expect(instance.shown?(user)).to be_truthy
          expect(subject.class.shown.pluck(:id)).to eq([])
          expect(subject.class.shown(user).pluck(:id)).to eq([instance.id])
        end
      end
    end
  end
end
