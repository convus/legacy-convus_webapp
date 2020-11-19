class WebhooksController < ApplicationController
  def reconcile_content
    if request.headers["X-Hub-Signature"] == ContentRedeployer::WEBHOOK_SECRET
      result = ContentRedeployer.new.run_content_job
      render json: {success: result.dig("response", "started_at").present?}
    else
      render json: {error: "Incorrect token"}, status: 401
    end
  end
end
