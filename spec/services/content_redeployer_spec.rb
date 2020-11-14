require "rails_helper"

RSpec.describe ContentRedeployer do
  let(:instance) { ContentRedeployer.new }

  describe "get_jobs" do
    it "gets the list of jobs" do
      VCR.use_cassette("content_redeployer-get_jobs", match_requests_on: [:method]) do
        result = instance.get_jobs
        expect(result["count"]).to be > 0
      end
    end
  end

  describe "redeploy" do
    it "makes a request to the correct URL to trigger cloud66 job" do
      VCR.use_cassette("content_redeployer-run_content_job", match_requests_on: [:method]) do
        result = instance.run_content_job
        expect(result.dig("response", "started_at")).to be_present
      end
    end
  end
end
