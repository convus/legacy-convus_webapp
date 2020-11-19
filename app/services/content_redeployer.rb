class ContentRedeployer
  WEBHOOK_SECRET = ENV["GITHUB_WEBHOOK_SECRET"]
  CLOUD66_API_KEY = ENV["C66_API_TOKEN"]
  STACK_ID = ENV["C66_STACK_UUID"]
  JOB_ID = ENV["C66_REDEPLOY_JOB_ID"]

  def connection
    @connection ||= Faraday.new(url: "https://app.cloud66.com") { |conn|
      conn.headers["Content-Type"] = "application/json"
      conn.headers["Authorization"] = "Bearer #{CLOUD66_API_KEY}"
      conn.adapter Faraday.default_adapter
    }
  end

  # This is required to get the job id, so it can be put in CLOUD66_REDEPLOY_JOB_ID
  def get_jobs
    response = connection.get("/api/3/stacks/#{STACK_ID}/jobs")
    JSON.parse(response.body)
  end

  def run_content_job
    response = connection.post("/api/3/stacks/#{STACK_ID}/jobs/#{JOB_ID}/run_now")
    JSON.parse(response.body)
  end
end
