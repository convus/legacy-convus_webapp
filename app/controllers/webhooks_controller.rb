class WebhooksController < ApplicationController
  def reconcile_content
    pp params
    if request.headers["X-Hub-Signature"] == ContentRedeployer::WEBHOOK_SECRET
      if params[:ref] == "refs/heads/main"
        result = ContentRedeployer.new.run_content_job
        render json: {success: result.dig("response", "started_at").present?}
      else
        render json: {skipped: "not master, no update run"}
      end
    else
      render json: {error: "Incorrect token"}, status: 401
    end
  end
end
