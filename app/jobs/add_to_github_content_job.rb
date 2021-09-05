class AddToGithubContentJob < ApplicationJob
  def perform(class_name, id)
    case class_name
    when "Hypothesis"
      hypothesis = Hypothesis.find id
      return true if hypothesis.approved? || hypothesis.pull_request_number.present?
      GithubIntegration.new.create_hypothesis_pull_request(hypothesis)
    when "Explanation"
      explanation = Explanation.find id
      return true if explanation.approved? || explanation.pull_request_number.present?
      GithubIntegration.new.create_explanation_pull_request(explanation)
    when "Citation"
      citation = Citation.find id
      return true if citation.approved? || citation.pull_request_number.present?
      GithubIntegration.new.create_citation_pull_request(citation)
    end
  end
end
