class HypothesisRelation < ApplicationRecord
  include GithubSubmittable

  KIND_ENUM = {
    hypothesis_conflict: 0,
    citation_conflict: 1,
    # explanation_quote_conflict: 2
  }.freeze

  belongs_to :creator, class_name: "User"
  belongs_to :hypothesis_earlier, class_name: "Hypothesis"
  belongs_to :hypothesis_later, class_name: "Hypothesis"
  belongs_to :explanation_quote
  belongs_to :citation, class_name: "Citation"

  enum kind: KIND_ENUM

  before_validation :set_calculated_attributes

  # Method here because I hope there is a better way to do this?
  def self.hypothesis_ids
    distinct.pluck(:hypothesis_earlier_id, :hypothesis_later_id).flatten.uniq
  end

  def set_calculated_attributes
    self.kind = if citation_id.present?
      "citation_conflict"
    else
      "hypothesis_conflict"
    end
  end
end
