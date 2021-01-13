class HypothesisCitation < ApplicationRecord
  include ApprovedAtable
  include GithubSubmittable

  belongs_to :creator, class_name: "User"
  belongs_to :hypothesis
  belongs_to :citation

  has_many :hypothesis_quotes, -> { score_ordered }, dependent: :destroy
  has_many :quotes, through: :hypothesis_quotes

  accepts_nested_attributes_for :citation

  validates :url, presence: true, uniqueness: {scope: [:hypothesis_id]}
  validates :hypothesis, presence: true

  before_validation :set_calculated_attributes
  after_commit :update_hypothesis

  scope :hypothesis_approved, -> { left_joins(:hypothesis).where.not(hypotheses: {approved_at: nil}) }

  attr_accessor :add_to_github, :skip_associated_tasks

  # There were some issues with legacy hypothesis_citations having duplicates
  # leaving method around until certain they're resolved
  def duplicates
    HypothesisCitation.where(citation_id: citation_id, hypothesis_id: hypothesis_id)
      .where.not(id: id)
  end

  def quotes_text_array
    return [] unless quotes_text.present?
    quotes_text.split(/\n/).reject(&:blank?).map { |t| Quote.normalize(t) }
  end

  def update_hypothesis_quotes(text_array)
    return true unless citation.present?
    ids_for_removal = hypothesis_quotes.map(&:id).reject(&:blank?)

    text_array.each_with_index do |quote_text, indx|
      hypothesis_quote = hypothesis_quotes.find { |hq| hq.quote_text == quote_text }
      if hypothesis_quote.present?
        hypothesis_quote.quote_text_index = indx
        hypothesis_quote.save if hypothesis_quote.changed? && id.present?
        ids_for_removal -= [hypothesis_quote.id]
      else
        hypothesis_quotes.build(hypothesis_citation: self, quote_text: quote_text, quote_text_index: indx)
      end
    end
    ids_for_removal.each { |i| hypothesis_quotes.where(id: i).first&.destroy }
    hypothesis_quotes
  end

  def title
    if citation.present?
      citation.title
    else
      "Citation"
    end
  end

  def set_calculated_attributes
    self.quotes_text = quotes_text_array.join("\n\n")
    self.quotes_text = nil if quotes_text.blank?
    self.url = UrlCleaner.with_http(UrlCleaner.without_utm(url))
    self.citation_id = Citation.find_or_create_by_params({url: url, creator_id: hypothesis.creator_id})&.id
    update_hypothesis_quotes(quotes_text_array)
  end

  def update_hypothesis
    # Ensure we don't call this in a loop, or during creation
    return false if skip_associated_tasks || (hypothesis.present? && hypothesis.created_at > Time.current - 5.seconds)
    # Only update the hypothesis if it isn't destroyed
    hypothesis&.update(updated_at: Time.current) unless hypothesis.destroyed?
  end
end
