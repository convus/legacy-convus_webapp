class HypothesisRelation < ApplicationRecord
  include GithubSubmittable

  KIND_ENUM = {
    hypothesis_conflict: 0,
    citation_conflict: 1,
    hypothesis_support: 5
    # explanation_quote_conflict: 2
  }.freeze

  belongs_to :creator, class_name: "User"
  belongs_to :hypothesis_earlier, class_name: "Hypothesis"
  belongs_to :hypothesis_later, class_name: "Hypothesis"
  belongs_to :explanation_quote
  belongs_to :citation, class_name: "Citation"

  enum kind: KIND_ENUM

  before_validation :set_calculated_attributes

  scope :conflicting, -> { where(kind: conflicting_kinds) }
  scope :supporting, -> { where(kind: supporting_kinds) }

  def self.kinds
    KIND_ENUM.keys.map(&:to_s)
  end

  def self.conflicting_kinds
    %w[hypothesis_conflict citation_conflict].freeze
  end

  def self.supporting_kinds
    %w[hypothesis_support].freeze
  end

  # Method here because I hope there is a better way to do this?
  def self.hypothesis_ids
    distinct.pluck(:hypothesis_earlier_id, :hypothesis_later_id).flatten.uniq
  end

  # Might let creating multiple at once, if that's useful
  def self.find_or_create_for(kind:, hypotheses:)
    hypotheses_ordered = hypotheses.sort_by { |h| h.ref_number }
    find_or_create_by(kind: kind, hypothesis_earlier: hypotheses_ordered.first, hypothesis_later: hypotheses_ordered.last)
  end

  def set_calculated_attributes
    self.kind ||= if citation_id.present?
      "citation_conflict"
    else
      "hypothesis_conflict"
    end
  end
end
