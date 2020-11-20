class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def github
    # We don't care about validating the payload, we just run the job
    # (there were some issues with the request being a GET not a POST, so skipping it for now)
    UpdateContentCommitsJob.perform_async
    render json: {success: "Running update content commits job"}
  end
end
