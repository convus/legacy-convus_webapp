class HypothesisChallenge < ApplicationRecord
  include GithubSubmittable

  KIND_ENUM = {
    challenge: 0,
    citation_challenge: 1,
    quote_challenge: 2
  }.freeze

  belongs_to :creator, class_name: "User"
  belongs_to :hypothesis
  belongs_to :challenged_hypothesis, class_name: "Hypothesis"
  belongs_to :challenged_explanation_quote, class_name: "ExplanationQuote"
  belongs_to :challenged_citation, class_name: "Citation"

  before_validation :set_calculated_attributes


  def set_calculated_attributes
    self.kind = if challenged_citation_id.present?
      "citation_challenge"
    elsif challenged_explanation_quote_id.present?
      "quote_challenge"
    else
      "challenge"
    end
  end
end
