class GithubIntegration
  CONTENT_REPO = ENV["CONTENT_REPO"].presence || "convus/convus_content"
  ACCESS_TOKEN = ENV["OCTOKIT_ACCESS_TOKEN"]
  SKIP_GITHUB_UPDATE = ENV["SKIP_GITHUB_UPDATE"].present?

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

  def commit(sha)
    client.commit(CONTENT_REPO, sha).to_h.as_json
  end

  def pull_requests(state: "open")
    client.pull_requests(CONTENT_REPO, state: state)
  end

  def last_main_commit
    commit(main_branch_sha)
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

  def create_pull_request(commit_message, pr_body)
    client.create_pull_request(CONTENT_REPO, "main", current_branch_name, commit_message, pr_body)
  end

  def get_file_sha(file_path)
    file_content = client.contents(CONTENT_REPO, path: file_path, branch: current_branch_name)
    file_content.sha
  rescue Octokit::NotFound
    nil
  end

  def upsert_file_on_current_branch(file_path, file_content, message)
    # Find the file_sha first -
    # Because if there is a file at the file_path, you have to pass the file sha to update
    file_sha = get_file_sha(file_path)
    if file_sha.present?
      # I can't figure out how to update without creating merge conflicts, so FUCK IT
      # Just delete the file
      client.delete_contents(CONTENT_REPO, file_path, "Deleting file", file_sha, branch: current_branch_name)
    end
    # TODO: make this an else, and use update
    # ... We're always creating now ;)
    client.create_contents(CONTENT_REPO, file_path, message, file_content, branch: current_branch_name)
  end

  def create_hypothesis_pull_request(hypothesis)
    branch_name = "proposed-hypothesis-#{hypothesis.id}"
    @current_branch = create_branch(branch_name)
    commit_message = "Hypothesis: #{hypothesis.title}"
    upsert_file_on_current_branch(hypothesis.file_path, hypothesis.flat_file_content, commit_message)
    # If there is a citation that hasn't been added to github yet, add it to this PR
    citation_ids_added = []
    hypothesis.citations.unapproved.each do |citation|
      next unless citation.present? && citation.unapproved?
      citation_ids_added << citation.id
      upsert_file_on_current_branch(citation.file_path, citation.flat_file_content, "Citation: #{citation.title}")
    end
    pr_body = "View [hypothesis on Convus](https://convus.org/hypotheses/#{hypothesis.id})"
    pull_request = create_pull_request(commit_message, pr_body)
    number = pull_request.url.split("/pulls/").last
    hypothesis.update(pull_request_number: number)
    citation_ids_added.each do |id|
      hypothesis.citations.find(id).update(pull_request_number: number)
    end
    pull_request
  end

  def create_citation_pull_request(citation)
    branch_name = "proposed-citation-#{citation.id}"
    @current_branch = create_branch(branch_name)
    commit_message = "Citation: #{citation.title}"
    upsert_file_on_current_branch(citation.file_path, citation.flat_file_content, commit_message)
    pull_request = create_pull_request(commit_message, "")
    number = pull_request.url.split("/pulls/").last
    citation.update(pull_request_number: number)
    pull_request
  end

  # AKA add a new citation to an existing hypothesis
  def create_hypothesis_citation_pull_request(hypothesis_citation)
    hypothesis = hypothesis_citation.hypothesis
    branch_name = "update-hypothesis-#{hypothesis.id}-with-#{hypothesis_citation.id}"
    @current_branch = create_branch(branch_name)
    commit_message = "Add citation to hypothesis: #{hypothesis.title}"
    # put hypothesis_citation in the new_cited_url in the serializer (added as a new field to ward off merge conflicts)
    hypothesis.included_unapproved_hypothesis_citation = hypothesis_citation
    upsert_file_on_current_branch(hypothesis.file_path, hypothesis.flat_file_content, commit_message)

    # If there is a citation that hasn't been added to github yet, add it to this PR
    citation = hypothesis_citation.citation
    if citation.unapproved?
      upsert_file_on_current_branch(citation.file_path, citation.flat_file_content, "Citation: #{citation.title}")
    end
    pr_body = "Added citation #{hypothesis_citation.challenge? ? 'challenging' : ''} to: "
    pr_body += "[#{hypothesis.title}](https://convus.org/hypotheses/#{hypothesis.id}?hypothesis_citation_id=#{hypothesis_citation.id})"
    pull_request = create_pull_request(commit_message, pr_body)
    number = pull_request.url.split("/pulls/").last
    hypothesis_citation.update(pull_request_number: number)
    citation.update(pull_request_number: number) if citation.unapproved?
    pull_request
  end
end
