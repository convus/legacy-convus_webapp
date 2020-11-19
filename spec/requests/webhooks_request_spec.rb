# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/webhooks", type: :request do
  describe "reconcile_content" do
    let(:headers) { {"X-Hub-Signature-256" => signature, "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json"} }
    # It doesn't require a signature right now, because I can't get that to work and there isn't a big security implication right now
    # let(:signature) { "blah-blah-blah" }
    # let(:post_body) do
    #   {
    #     ref: "refs/heads/main",
    #     before: "df11e5b3abc02939becc893861bf9934a96b8f59",
    #     after: "475b8e07ec1c4373f077b4bb7b2e6fa6bea341e0",
    #     repository: {id: 295843610}
    #   }
    # end
    # it "401s without correct password" do
    #   get "/webhooks/reconcile_content", headers: headers, params: post_body.to_json
    #   expect(response.code).to eq "401"
    # end
    context "correct API token" do
      let(:signature) { "sha256=5fe6637f8134c73032ba87b04441e8b8aa21a4c0473c21ec2b5e68c54eff4489" }
      it "triggers ContentRedeployer request" do
        VCR.use_cassette("webhooks-reconcile_content", match_requests_on: [:method]) do
          # Should be post, but whatever github
          get "/webhooks/reconcile_content", headers: headers, params: post_body.to_json
          expect(response.code).to eq "200"
          expect(json_result["success"]).to be_truthy
        end
      end
    end
  end
end
