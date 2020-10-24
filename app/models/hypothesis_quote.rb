class HypothesisQuote < ApplicationRecord
  DEFAULT_IMPORTANCE = 50

  belongs_to :hypothesis_citation
  belongs_to :hypothesis # added so we can join things, everything could be done off of hypothesis_citation
  belongs_to :quote # added so we can join things, everything could be done off of hypothesis_citation
  belongs_to :citation # added so we can join things, everything could be done off of hypothesis_citation

  validates :quote, presence: true, uniqueness: {scope: [:hypothesis_id]}

  before_validation :set_calculated_attributes

  scope :score_ordered, -> { order(importance: :desc) }

  def quote_text
    quote&.text
  end

  def quote_text=(val)
    set_associations
    self.quote = citation.quotes.friendly_find(val)
    self.quote ||= Quote.new(citation: citation, text: val)
  end

  def quote_text_index
    abs(DEFAULT_IMPORTANCE - importance)
  end

  def quote_text_index=(val)
    self.importance = DEFAULT_IMPORTANCE - val
  end

  def set_calculated_attributes
    set_associations

    if importance.blank?
      self.importance = DEFAULT_IMPORTANCE
    elsif importance < 1
      self.importance = 1
    elsif importance > 100
      self.importance = 100
    end
    self.score = calculated_score
  end

  def calculated_score
    citation_score = citation&.calculated_score || 0
    importance + (citation_score * 10)
  end

  private

  def set_associations
    self.citation ||= hypothesis_citation&.citation || quote&.citation
    self.hypothesis ||= hypothesis_citation&.hypothesis
  end
end
