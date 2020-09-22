class CreateHypothesisPullRequestJob < ApplicationJob
  def perform(id)
    hypothesis = Hypothesis.find id
    return true if hypothesis.approved? || hypothesis.pull_request_number.present?
    GithubIntegration.new.create_hypothesis_pull_request(hypothesis)
  end
end
