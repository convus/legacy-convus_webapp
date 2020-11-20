# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/webhooks", type: :request do
  describe "reconcile_content" do
    let(:post_body) do
      {
        ref: "refs/heads/main",
        before: "df11e5b3abc02939becc893861bf9934a96b8f59",
        after: "475b8e07ec1c4373f077b4bb7b2e6fa6bea341e0",
        repository: {id: 295843610}
      }
    end
    it "enqueues job" do
      expect do
        # Somehow, this comes in as a get request on production - just deal with it
        get "/webhooks/github", headers: json_headers, params: post_body.to_json
      end.to change(UpdateContentCommitsJob.jobs, :count).by 1
      expect(response.code).to eq "200"
    end
    context "running jobs" do
      # it "triggers ContentRedeployer request" do
      #   VCR.use_cassette("webhooks-reconcile_content", match_requests_on: [:method]) do
      #     expect_any_instance_of(ContentRedeployer).to receive(:run_content_job)
      #     Sidekiq::Worker.clear_all
      #     Sidekiq::Testing.inline! do
      #       expect do
      #         post "/webhooks/github", headers: json_headers, params: post_body.to_json
      #       end.to change(ContentCommit, :count).by 1
      #       expect(response.code).to eq "200"
      #       expect(json_result["success"]).to be_present
      #     end
      #     content_commit = ContentCommit.last
      #     expect(content_commit.github_data).to be_present
      #     expect(content_commit.sha).to be_present
      #     # This is probably truthy? whatever
      #     expect(content_commit.reconciler_update?).to be_falsey
      #   end
      # end
    end
  end
end
