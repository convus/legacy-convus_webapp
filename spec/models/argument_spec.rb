require "rails_helper"

RSpec.describe Argument, type: :model do
  it_behaves_like "GithubSubmittable"

  describe "factory" do
    let(:argument) { FactoryBot.create(:argument) }
    it "is valid" do
      expect(argument).to be_valid
      expect(argument.id).to be_present
      expect(argument.hypothesis).to be_present
      expect(argument.approved?).to be_falsey
    end
    context "approved" do
      let(:argument) { FactoryBot.create(:argument_approved) }
      it "is valid" do
        expect(argument).to be_valid
        expect(argument.id).to be_present
        expect(argument.hypothesis).to be_present
        expect(argument.approved?).to be_truthy
      end
    end
  end
end
