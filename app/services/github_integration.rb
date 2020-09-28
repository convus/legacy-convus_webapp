class GithubIntegration
  CONTENT_REPO = ENV["CONTENT_REPO"].presence || "convus/convus_content"
  ACCESS_TOKEN = ENV["OCTOKIT_ACCESS_TOKEN"]

  def self.content_html_url(file_path)
    ["https://github.com", CONTENT_REPO, "blob/main", file_path].join("/")
  end

  def self.pull_request_html_url(pull_request_number)
    return nil unless pull_request_number.present?
    ["https://github.com", CONTENT_REPO, "pull", pull_request_number].join("/")
  end

  attr_accessor :current_branch

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
    current_branch.ref.delete_prefix("refs/heads/")
  end

  def create_branch(branch_name)
    client.create_ref(CONTENT_REPO, "heads/#{branch_name}", main_branch_sha)
  end

  # Maybe someday this will update files rather than just creating them
  def create_file_on_current_branch(file_path, file_content, message)
    client.create_contents(CONTENT_REPO, file_path, message, file_content, branch: current_branch_name)
  end

  def create_hypothesis_pull_request(hypothesis)
    branch_name = "proposed-hypothesis-#{hypothesis.id}"
    @current_branch = create_branch(branch_name)
    commit_message = "Hypothesis: #{hypothesis.title}"
    create_file_on_current_branch(hypothesis.file_path, hypothesis.flat_file_content, commit_message)
    # If there is a citation that hasn't been added to github yet, add it to this PR
    citation = hypothesis.citations.unapproved.first
    add_citation = citation.present? && citation.pull_request_number.blank?
    if add_citation
      create_file_on_current_branch(citation.file_path, citation.flat_file_content, "Citation: #{citation.title}")
    end
    pr_body = "View [Hypothesis on Convus](https://convus.org/hypotheses/#{hypothesis.id})"
    pull_request = client.create_pull_request(CONTENT_REPO, "main", current_branch_name, commit_message, pr_body)
    number = pull_request.url.split("/pulls/").last
    hypothesis.update(pull_request_number: number)
    citation.update(pull_request_number: number) if add_citation
    pull_request
  end

  def create_citation_pull_request(citation)
    branch_name = "proposed-citation-#{citation.id}"
    @current_branch = create_branch(branch_name)
    message = "Citation: #{citation.title}"
    create_file_on_current_branch(citation.file_path, citation.flat_file_content, message)
    pull_request = client.create_pull_request(CONTENT_REPO, "main", current_branch_name, message)
    number = pull_request.url.split("/pulls/").last
    citation.update(pull_request_number: number)
    pull_request
  end
end
