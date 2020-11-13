require "rails_helper"

RSpec.describe ContentRedeployer do
  let(:instance) { ContentRedeployer.new }

  describe "get_jobs" do
    it "gets the list of jobs" do
      VCR.use_cassette("content_redeployer-get_jobs", match_requests_on: [:method]) do
        result = instance.get_jobs
        expect(response["count"]).to be > 0
      end
    end
  end

  describe "redeploy" do
    it "makes a request to the correct URL to trigger cloud66 job" do
    end
  end
end
