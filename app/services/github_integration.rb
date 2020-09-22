class GithubIntegration
  CONTENT_REPO = ENV["CONTENT_REPO"].presence || "convus/convus_content"
  ACCESS_TOKEN = ENV["OCTOKIT_ACCESS_TOKEN"]

  def self.content_html_url(file_path)
    ["https://github.com", CONTENT_REPO, "blob/main", file_path].join("/")
  end

  def self.pull_request_html_url(pull_request_id)
    return nil unless pull_request_id.present?
    ["https://github.com", CONTENT_REPO, "pull", pull_request_id].join("/")
  end

  attr_accessor :current_branch, :main_branch_sha

  def client
    @client ||= Octokit::Client.new(access_token: ACCESS_TOKEN)
  end

  def refs
    client.refs(CONTENT_REPO)
  end

  def pull_requests(state: "open")
    client.pull_requests(CONTENT_REPO, state: state)
  end

  def main_branch_sha
    @main_branch_sha ||= refs.find do |reference|
      reference.ref == "refs/heads/main"
    end&.object&.sha
  end

  def current_branch_name
    return nil unless current_branch.present?
    current_branch.ref.gsub(/\Arefs\/heads\//, "")
  end

  def create_branch(branch_name)
    client.create_ref(CONTENT_REPO, "heads/#{branch_name}", main_branch_sha)
  end

  # Maybe someday this will update files rather than just creating them
  def create_file_on_current_branch(file_path, file_content, message)
    client.create_contents(CONTENT_REPO, file_path, message, file_content, branch: current_branch_name)
  end

  def create_hypothesis_pull_request(hypothesis)
    return hypothesis.pull_request_id if hypothesis.pull_request_id.present?
    branch_name = "proposed-hypothesis-#{hypothesis.id}"
    @current_branch = create_branch(branch_name)
    message = "Hypothesis: #{hypothesis.title}"
    create_file_on_current_branch(hypothesis.file_path, FlatFileSerializer.hypothesis_file_content(hypothesis), message)
    client.create_pull_request(CONTENT_REPO, "main", current_branch_name, message)
  end
end
