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

  def self.find_or_create_for(kind:, hypotheses:, creator: nil)
    hypotheses_ordered = hypotheses.sort_by { |h| h.ref_number }
    find_by(kind: kind, hypothesis_earlier_id: hypotheses_ordered.first.id,
      hypothesis_later_id: hypotheses_ordered.last.id) ||
      create(kind: kind, creator: creator,
        hypothesis_earlier_id: hypotheses_ordered.first.id,
        hypothesis_later_id: hypotheses_ordered.last.id)
  end

  def self.matching_hypothesis(hypothesis_or_id)
    hypothesis_id = hypothesis_or_id.is_a?(Integer) ? hypothesis_or_id : hypothesis_or_id.id
    HypothesisRelation.where(hypothesis_earlier_id: hypothesis_id)
      .or(HypothesisRelation.where(hypothesis_later_id: hypothesis_id))
  end

  # Method here because I hope there is a better way to do this?
  def self.hypothesis_ids
    distinct.pluck(:hypothesis_earlier_id, :hypothesis_later_id).flatten.uniq
  end

  # ... Probably is a better way to do this too
  def self.hypotheses(skip_id_or_hypothesis = nil)
    skip_id = if skip_id_or_hypothesis.present?
      skip_id_or_hypothesis.is_a?(Hypothesis) ? skip_id_or_hypothesis.id : skip_id_or_hypothesis
    end
    Hypothesis.where(id: hypothesis_ids - [skip_id])
  end

  def self.kind_humanized(str = nil)
    return nil if str.blank?
    str.gsub("hypothesis_", "")
  end

  def kind_humanized
    self.class.kind_humanized(kind)
  end

  def set_calculated_attributes
    self.kind ||= if citation_id.present?
      "citation_conflict"
    else
      "hypothesis_conflict"
    end
    self.creator_id ||= hypothesis_later&.creator_id
  end
end
