class WebhooksController < ApplicationController
  def reconcile_content
    # if signature_verified?
    if params[:ref] == "refs/heads/main"
      result = ContentRedeployer.new.run_content_job
      render json: {success: result.dig("response", "started_at").present?}
    else
      render json: {skipped: "not master, no update run"}
    end
    # else
    #   render json: {error: "Incorrect token"}, status: 401
    # end
  end

  private

  def signature_verified?
    return false unless request.headers["X-Hub-Signature-256"].present?
    signature = "sha256=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), ContentRedeployer::WEBHOOK_SECRET, request.body.read)
    Rack::Utils.secure_compare(signature, request.headers["X-Hub-Signature-256"])
  end
end
