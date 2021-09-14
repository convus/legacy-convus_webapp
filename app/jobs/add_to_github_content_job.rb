class AddToGithubContentJob < ApplicationJob
  def perform(class_name, id)
    case class_name
    when "Explanation"
      explanation = Explanation.find id
      return true if explanation.approved? || explanation.pull_request_number.present?
      GithubIntegration.new.create_explanation_pull_request(explanation)
    when "Citation"
      citation = Citation.find id
      return true if citation.approved? || citation.pull_request_number.present?
      GithubIntegration.new.create_citation_pull_request(citation)
    else
      raise "Unprocessable type: #{class_name} - #{id}"
    end
  end
end
