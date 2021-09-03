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
    when "HypothesisCitation"
      hypothesis_citation = HypothesisCitation.find id
      return true if hypothesis_citation.approved? || hypothesis_citation.pull_request_number.present?
      GithubIntegration.new.create_hypothesis_citation_pull_request(hypothesis_citation)
    end
  end
end
