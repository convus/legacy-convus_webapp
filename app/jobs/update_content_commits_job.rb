class UpdateContentCommitsJob < ApplicationJob
  def perform
    commit = GithubIntegration.new.last_main_commit
    sha = commit["sha"]
    return true if ContentCommit.find_by_sha(sha).present?
    content_commit = ContentCommit.create!(sha: sha, github_data: commit)
    ContentRedeployer.new.run_content_job unless content_commit.reconciler_update?
    content_commit
  end
end
