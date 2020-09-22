class GithubIntegration
  CONTENT_GIT_PATH = ENV["CONTENT_GIT_PATH"].presence || "convus/convus_content"
  ACCESS_TOKEN = ENV["OCTOKIT_ACCESS_TOKEN"]

  def self.content_html_url(file_path)
    ["https://github.com", CONTENT_GIT_PATH, "blob/main", file_path].join("/")
  end

  def self.pull_request_html_url(pull_request_id)
    return nil unless pull_request_id.present?
    ["https://github.com", CONTENT_GIT_PATH, "pull", pull_request_id].join("/")
  end

  def client
    @client ||= Octokit::Client.new(access_token: ACCESS_TOKEN)
  end

  def main_branch_sha
    client.refs(CONTENT_GIT_PATH).find do |reference|
      reference.ref == "refs/heads/main"
    end&.object&.sha
  end
end
