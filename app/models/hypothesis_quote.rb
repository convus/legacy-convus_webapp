class HypothesisQuote < ApplicationRecord
  DEFAULT_IMPORTANCE = 5

  belongs_to :hypothesis
  belongs_to :quote

  validates_presence_of :quote_id, :hypothesis_id

  before_validation :set_calculated_attributes

  delegate :citation, to: :quote, allow_nil: true

  def set_calculated_attributes
    if importance.blank?
      self.importance = DEFAULT_IMPORTANCE
    elsif importance < 1
      self.importance = 1
    elsif importance > 10
      self.importance = 10
    end
    self.score = calculated_score
  end

  def calculated_score
    citation_score = citation&.calculated_score || 0
    citation_score + importance
  end
end
