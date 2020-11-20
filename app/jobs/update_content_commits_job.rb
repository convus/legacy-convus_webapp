class UpdateContentCommitsJob < ApplicationJob
  def perform
    commit = GithubIntegration.new.last_main_commit
    sha = commit["sha"]
    return true if ContentCommit.find_by_sha(sha).present?
    content_commit = ContentCommit.create!(sha: sha, github_data: commit)
    trigger_reconcile_flat_file_database unless content_commit.reconciler_update?
    content_commit
  end

  # Below here is for triggering reconcile job on C66
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

  def trigger_reconcile_flat_file_database
    response = connection.post("/api/3/stacks/#{STACK_ID}/jobs/#{JOB_ID}/run_now")
    JSON.parse(response.body)
  end

  # This is required to get the job id, so it can be put in CLOUD66_REDEPLOY_JOB_ID
  # Doesn't actually get run in production
  def get_jobs
    response = connection.get("/api/3/stacks/#{STACK_ID}/jobs")
    JSON.parse(response.body)
  end
end
