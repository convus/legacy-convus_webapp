# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/webhooks", type: :request do
  describe "reconcile_content" do
    it "401s without correct password" do
      post "/webhooks/reconcile_content", headers: {"X-Hub-Signature" => "blah-blah-blah" }
      expect(response.code).to eq "401"
    end
    context "correct API token" do
      it "triggers ContentRedeployer request" do
        VCR.use_cassette("webhooks-reconcile_content", match_requests_on: [:method]) do
          post "/webhooks/reconcile_content", headers: { "X-Hub-Signature" => "xxxxxxxx" }
          expect(response.code).to eq "200"
          expect(json_result["success"]).to be_truthy
        end
      end
    end
  end
end
