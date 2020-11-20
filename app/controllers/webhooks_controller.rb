class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def github
    # We don't care about validating the signature, because we just run the job against the API instead
    UpdateContentCommitsJob.perform_async
    render json: {success: "Running update content commits job"}
  end
end
