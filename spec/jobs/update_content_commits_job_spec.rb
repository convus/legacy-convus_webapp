require "rails_helper"

RSpec.describe UpdateContentCommitsJob do
  let(:instance) { described_class.new }

  describe "perform" do
    it "creates a content commit, redeploys" do
      expect_any_instance_of(ContentRedeployer).to receive(:run_content_job) { true }
      VCR.use_cassette("update_content_commits_job", match_requests_on: [:method]) do
        expect {
          instance.perform
        }.to change(ContentCommit, :count).by 1
        content_commit = ContentCommit.last
        expect(content_commit.github_data).to be_present
        expect(content_commit.reconciler_update?).to be_falsey
        # Calling again doesn't change anything
        expect {
          instance.perform
        }.to_not change(ContentCommit, :count)
      end
    end
    context "reconciler_update? commit" do
      it "creates, does not redeploy" do
        expect_any_instance_of(ContentRedeployer).to_not receive(:run_content_job)
        expect_any_instance_of(GithubIntegration).to receive(:main_branch_sha) { "df11e5b3abc02939becc893861bf9934a96b8f59" }
        VCR.use_cassette("update_content_commits_job-reconciler", match_requests_on: [:method]) do
          expect {
            instance.perform
          }.to change(ContentCommit, :count).by 1
          content_commit = ContentCommit.last
          expect(content_commit.github_data).to be_present
          expect(content_commit.reconciler_update?).to be_truthy
        end
      end
    end
  end
end
