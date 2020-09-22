class AddCitationToGithubContentJob < ApplicationJob
  def perform(id)
    citation = Citation.find id
    return true if citation.approved? || citation.pull_request_number.present?
    if citation.creator&.directly_merge_citation?
      GithubIntegration.new.create_citation_directly(citation)
    else
      GithubIntegration.new.create_citation_pull_request(citation)
    end
  end
end
