class ContentRedeployer
  ACCESS_TOKEN = ENV["REDEPLOYER_WEBHOOK_TOKEN"]
  CLOUD66_API_KEY = ENV["CLOUD66_API_KEY"]
  # CLOUD66_API_KEY = ENV["C66_JOB_TOKEN"] # ENV["CLOUD66_API_KEY"]

  STACK_ID = ENV["C66_STACK_UUID"]
  JOB_ID = ENV["CLOUD66_REDEPLOY_JOB_ID"]
  BASE_URL = "https://app.cloud66.com"


  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |conn|
      conn.headers["Content-Type"] = "application/json"
      conn.headers["Authorization"] = "Bearer #{CLOUD66_API_KEY}"
      conn.adapter Faraday.default_adapter
    end
  end

  # This is required to get the job id, so it can be put in CLOUD66_REDEPLOY_JOB_ID
  def get_jobs
    connection.get("/api/3/stacks.json")
    response = connection.get("/api/3/stacks/#{STACK_ID}/jobs")
    JSON.parse(response.body)
  end

  def redeploy
    "/stacks/#{STACK_ID}/jobs/#{JOB_ID}/run_now"
  end
end
