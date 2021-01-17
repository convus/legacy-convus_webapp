class HypothesisCitation < ApplicationRecord
  include ApprovedAtable
  include GithubSubmittable

  KIND_ENUM = {
    hypothesis_supporting: 0,
    challenge_citation_quotation: 3,
    challenge_by_another_citation: 4
  }.freeze

  belongs_to :creator, class_name: "User"
  belongs_to :hypothesis
  belongs_to :citation
  belongs_to :challenged_hypothesis_citation, class_name: "HypothesisCitation"

  has_many :hypothesis_quotes, -> { score_ordered }, dependent: :destroy
  has_many :quotes, through: :hypothesis_quotes

  accepts_nested_attributes_for :citation

  enum kind: KIND_ENUM

  validates :url, presence: true, uniqueness: {
    scope: [:hypothesis_id, :kind, :challenged_hypothesis_citation_id]
  }
  validates :hypothesis, presence: true

  before_validation :set_calculated_attributes
  after_commit :update_hypothesis

  scope :hypothesis_approved, -> { left_joins(:hypothesis).where.not(hypotheses: {approved_at: nil}) }
  scope :challenge, -> { where(kind: challenge_kinds) }

  attr_accessor :add_to_github, :skip_associated_tasks

  def self.kinds
    KIND_ENUM.keys.map(&:to_s)
  end

  def self.challenge_kinds
    kinds - ["hypothesis_supporting"]
  end

  def self.challenge_same_citation_kinds
    challenge_kinds - ["challenge_by_another_citation"]
  end

  def self.kinds_data
    {
      hypothesis_supporting: {humanized: "Supporting citation"},
      challenge_citation_quotation: {humanized: "Challenge quotation's accuracy in piece"},
      challenge_by_another_citation: {humanized: "Challenge based on another citation"}
    }
  end

  def self.kind_humanized(str)
    kinds_data.dig(str&.to_sym, :humanized)
  end

  def kind_humanized
    self.class.kind_humanized(kind)
  end

  def challenge?
    !hypothesis_supporting?
  end

  def challenge_same_citation_kind?
    self.class.challenge_same_citation_kinds.include?(kind)
  end

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

  # TODO: make this not a stupid stub
  def title
    citation.present? ? citation.title : "Citation"
  end

  def set_calculated_attributes
    self.quotes_text = quotes_text_array.join("\n\n")
    self.quotes_text = nil if quotes_text.blank?
    self.kind ||= "hypothesis_supporting"
    if challenged_hypothesis_citation.present?
      self.hypothesis_id = challenged_hypothesis_citation.hypothesis_id
      self.url = challenged_hypothesis_citation.url if challenge_same_citation_kind?
    end
    self.url = UrlCleaner.with_http(UrlCleaner.without_utm(url))
    self.creator_id ||= hypothesis.creator_id
    self.citation_id = Citation.find_or_create_by_params({url: url, creator_id: creator_id})&.id
    update_hypothesis_quotes(quotes_text_array)
  end

  def update_hypothesis
    # Ensure we don't call this in a loop, or during creation
    return false if skip_associated_tasks || (hypothesis.present? && hypothesis.created_at > Time.current - 5.seconds)
    # Only update the hypothesis if it isn't destroyed
    hypothesis&.update(updated_at: Time.current) unless hypothesis.destroyed?
    add_to_github_content
  end

  # Serialized into hypothesis flat files, but need to access this from multiple places so...
  def flat_file_serialized
    {
      url: citation.url,
      quotes: hypothesis_quotes.map(&:quote_text)
    }
  end
end
