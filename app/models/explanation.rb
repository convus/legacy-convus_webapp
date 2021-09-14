class Explanation < ApplicationRecord
  include FlatFileSerializable
  include GithubSubmittable
  include PgSearch::Model

  belongs_to :creator, class_name: "User"
  belongs_to :hypothesis

  has_many :explanation_quotes, dependent: :destroy
  has_many :citations, -> { distinct }, through: :explanation_quotes
  has_many :explanation_quotes_not_removed, -> { not_removed }, class_name: "ExplanationQuote"
  has_many :citations_not_removed, -> { distinct }, through: :explanation_quotes_not_removed, source: :citation
  has_many :user_scores

  before_validation :set_calculated_attributes
  after_commit :run_associated_tasks

  delegate :file_pathnames, to: :hypothesis, allow_nil: true

  accepts_nested_attributes_for :explanation_quotes, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :citations

  scope :with_body_html, -> { where.not(body_html: nil) }
  scope :listing_ordered, -> { reorder(:listing_order) }
  scope :hypothesis_approved, -> { joins(:hypothesis).merge(Hypothesis.approved) }
  scope :normal_user, -> { left_joins(:creator).where(users: {role: "normal_user"}) }

  attr_accessor :skip_associated_tasks

  def self.explanation_quotes
    ExplanationQuote.where(explanation_id: pluck(:id))
  end

  def remove_empty_quotes!
    explanation_quotes.each { |aq| aq.destroy if aq.removed? && aq.url.blank? }
  end

  def hypothesis_approved
    hypothesis&.approved?
  end

  def validate_can_add_to_github?
    if explanation_quotes.count == 0
      errors.add(:base, "must have at least one quote")
    elsif explanation_quotes.not_removed.no_url.any?
      errors.add(:base, "All quotes need to have URLs")
    end
    errors.full_messages.none?
  end

  def github_html_url
    approved? ? hypothesis&.github_html_url : pull_request_url
  end

  def run_associated_tasks
    update_ref_number if ref_number.blank?
    return false if skip_associated_tasks
    add_to_github_content
  end

  # Method to building from flat file content
  def update_from_text(passed_text)
    self.text = passed_text
    @text_nodes = parser(true).parse_text_nodes
    current_explanation_quote_ids = []
    quote_nodes.each_with_index do |q_node, index|
      if q_node[:url].present?
        # Make sure we don't grab the same quote multiple times
        matches = explanation_quotes.where.not(id: current_explanation_quote_ids).where(url: q_node[:url])
        # Try to grab the match by text
        explanation_quote = matches.where(text: q_node[:quote]).first
        # Fallback to just whatever is there
        explanation_quote ||= matches.first
      end
      explanation_quote ||= explanation_quotes.where.not(id: current_explanation_quote_ids).find_by_text(q_node[:quote])
      explanation_quote ||= explanation_quotes.build
      explanation_quote.update!(text: q_node[:quote], url: q_node[:url], ref_number: index + 1)
      current_explanation_quote_ids << explanation_quote.id
    end
    explanation_quotes.where.not(id: current_explanation_quote_ids).update_all(removed: true)
    remove_empty_quotes!
    self.text = parser.text_no_references # Remove references from the text
    update_body_html
  end

  def parser(reinitialize = false)
    return @parser unless reinitialize || @parser.blank?
    @parser = ExplanationParser.new(explanation: self)
  end

  def text_nodes
    @text_nodes ||= parser.parse_text_nodes
  end

  def quote_nodes
    text_nodes.reject { |t| t.is_a?(String) }
  end

  def text_with_references
    parser.text_with_references
  end

  def update_body_html
    update(body_html: calculated_body_html)
    self
  end

  def flat_file_serialized
    {id: ref_number, text: text_with_references}
  end

  # This isn't optimal and I don't think it handles nested blockquotes - but fuck them anyway
  def calculated_body_html
    html_output = ""
    quote_sources = explanation_quotes.not_removed.order(:ref_number).map(&:citation_ref_html)
    text_nodes.each do |node|
      html_output += if node.is_a?(String)
        ExplanationParser.text_to_html(node)
      else
        source = quote_sources.shift
        source = "<span class=\"source\">#{source}</span>" if source.present?
        # Open and closing tags, separated by a newline to make test parsing easier
        "\n<div class=\"explanation-quote-block\"><blockquote>\n" +
          ExplanationParser.text_to_html(node[:quote]) +
          "\n</blockquote>#{source}</div>\n"
      end
    end
    html_output
  end

  def set_calculated_attributes
    self.body_html = nil if body_html.blank? # Because we search by nil
  end

  private

  # Eventually will have a separate process for specifying listing_order, but...
  def update_ref_number
    new_ref_number = Explanation.where(hypothesis_id: hypothesis_id).where("id < ?", id).count
    # numbers start at 1, just to fuck with future you
    update_columns(ref_number: new_ref_number + 1, listing_order: new_ref_number)
  end
end
