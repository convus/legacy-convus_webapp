class Argument < ApplicationRecord
  include ApprovedAtable
  include FlatFileSerializable
  include GithubSubmittable
  include PgSearch::Model

  belongs_to :creator, class_name: "User"
  belongs_to :hypothesis

  has_many :argument_quotes, dependent: :destroy
  has_many :citations, through: :argument_quotes
  has_many :user_scores

  before_validation :set_calculated_attributes
  after_commit :run_associated_tasks

  accepts_nested_attributes_for :argument_quotes, allow_destroy: true, reject_if: :all_blank

  scope :with_body_html, -> { where.not(body_html: nil) }
  scope :listing_ordered, -> { reorder(:listing_order) }
  scope :hypothesis_approved, -> { left_joins(:hypothesis).where.not(hypotheses: {approved_at: nil}) }

  attr_accessor :skip_associated_tasks

  def self.shown(user = nil)
    return approved unless user.present?
    approved.or(where(creator_id: user.id))
  end

  def shown?(user = nil)
    approved? || creator_id == user&.id
  end

  def remove_empty_quotes!
    argument_quotes.each { |aq| aq.destroy if aq.removed? && aq.url.blank? }
  end

  def hypothesis_approved
    hypothesis&.approved?
  end

  # This will definitely become more sophisticated later!
  def display_id
    "#{hypothesis&.display_id}: Argument-#{id}"
  end

  # Required for FlatFileSerializable
  def flat_file_serialized
    ArgumentSerializer.new(self, root: false).as_json
  end

  def run_associated_tasks
    update_ref_number if ref_number.blank?
    return false if skip_associated_tasks
    add_to_github_content
  end

  def argument_markdown
    Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(no_images: true, no_links: true, filter_html: true),
      {no_intra_emphasis: true, tables: true, fenced_code_blocks: true, strikethrough: true,
       superscript: true, lax_spacing: true}
    )
  end

  def update_body_html
    update(body_html: parse_text_with_blockquotes)
  end

  # Only for internal use, really
  def parse_text
    return "" unless text.present?
    argument_markdown.render(text.strip)
      .gsub(/(<\/?)h\d+/i, '\1p') # Remove header open brackets and close brackets
  end

  # This sucks and is brittle
  def parse_text_with_blockquotes
    html_output = ""
    # This is a dumb way of doing this, sorry, I'm tired (Also, I don't think it handles nested blockquotes - but fuck them anyway)
    quote_sources = argument_quotes.not_removed.order(:ref_number).map(&:citation_ref_html)
    opening_tag = "<div class=\"argument-quote-block\"><blockquote>"
    parse_text.gsub(/<blockquote>/i, "||QBLK||>>>>").split("||QBLK||").each do |quote_or_not|
      quote_or_not.gsub!(/>>>>/, opening_tag)
      # I think these are generally grouped with the quote? But not sure. So handling it this way
      if quote_or_not.match?(/<\/blockquote>/i)
        closing_tag = "</blockquote><span class=\"source\">#{quote_sources.shift}</span></div>"
        quote_or_not.gsub!(/<\/blockquote>/i, closing_tag)
      end
      html_output += quote_or_not
    end
    html_output
  end

  def set_calculated_attributes
    self.body_html = nil if body_html.blank? # Because we search by nil
  end

  private

  # Eventually will have a separate process for specifying listing_order, but...
  def update_ref_number
    new_ref_number = Argument.where(hypothesis_id: hypothesis_id).where("id < ?", id).count
    update_columns(ref_number: new_ref_number, listing_order: new_ref_number)
  end
end
