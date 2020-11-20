require "rails_helper"

RSpec.describe UpdateContentCommitsJob do
  let(:instance) { described_class.new }

  describe "perform" do
    it "creates a content commit, redeploys" do
      expect(instance).to receive(:trigger_reconcile_flat_file_database) { true }
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
        expect(instance).to_not receive(:trigger_reconcile_flat_file_database)
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

    context "passed commit" do
      let(:sha) { "d2015248d0ed910dd5533ed14f2020daf15d931a" }
      it "loads the given commit" do
        expect(instance).to_not receive(:trigger_reconcile_flat_file_database)
        VCR.use_cassette("update_content_commits_job-passed_sha", match_requests_on: [:method]) do
          expect {
            instance.perform(sha, true)
          }.to change(ContentCommit, :count).by 1
          content_commit = ContentCommit.last
          expect(content_commit.github_data).to be_present
          expect(content_commit.reconciler_update?).to be_falsey
          expect(content_commit.github_data["sha"]).to eq sha
          # And even passed a sha, it doesn't duplicate
          expect {
            instance.perform(sha)
          }.to_not change(ContentCommit, :count)
        end
      end
    end
  end

  describe "get_jobs" do
    it "gets the list of jobs" do
      VCR.use_cassette("update_content_commits_job-get_jobs", match_requests_on: [:method]) do
        result = instance.get_jobs
        expect(result["count"]).to be > 0
      end
    end
  end

  describe "trigger_reconcile_flat_file_database" do
    it "makes a request to the correct URL to trigger cloud66 job" do
      VCR.use_cassette("update_content_commits_job-trigger_reconcile_flat_file_database", match_requests_on: [:method]) do
        result = instance.trigger_reconcile_flat_file_database
        expect(result.dig("response", "started_at")).to be_present
      end
    end
  end
end
