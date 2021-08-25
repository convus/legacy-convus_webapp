class Argument < ApplicationRecord
  include ApprovedAtable
  include GithubSubmittable
  include PgSearch::Model

  belongs_to :creator, class_name: "User"
  belongs_to :hypothesis

  has_many :argument_quotes, dependent: :destroy
  has_many :citations, through: :argument_quotes
  has_many :user_scores

  after_commit :run_associated_tasks

  accepts_nested_attributes_for :argument_quotes, allow_destroy: true, reject_if: :all_blank

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
    argument_quotes.each { |aq| aq.destroy if aq.removed? && aq.text.blank? && aq.url.blank? }
  end

  def hypothesis_approved
    hypothesis&.approved?
  end

  # This will definitely become more sophisticated later!
  def display_id
    "#{hypothesis&.display_id}: Argument-#{id}"
  end

  def run_associated_tasks
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
    # This is a dumb hack, sorry, I'm tired (Also, I don't think it handles nested blockquotes - but fuck them anyway)
    quote_sources = argument_quotes.not_removed.order(:ref_number).map(&:citation_ref_html)
    opening_tag = "<div class=\"argument-quote-block\"><blockquote>"
    parse_text.gsub(/<blockquote>/i, "||QBLK||>>>>").split("||QBLK||").each do |quote_or_not|
      quote_or_not.gsub!(/>>>>/, opening_tag)
      # I think these are generally grouped with the quote? But not sure. So handling it this way
      if quote_or_not.match?(/<\/blockquote>/i)
        closing_tag = "</blockquote><span class=\"source\">#{quote_sources.shift}</span></div>"
        quote_or_not.gsub!(/<\/blockquote>/i, closing_tag)
      end
      # pp "SECONDARILY: #{quote_or_not.gsub("\n", "")}"

      html_output += quote_or_not

      # pp quote_and_text, "11111111111212"
      # # If there wasn't a blockquote closing tag, skip it
      # next quote_and_text if quote_and_text.length == 1
      # # This sucks
      # argument_quote = argument_quotes.not_removed.where(text: quote_and_text[0]).first

      # quote_body = if argument_quote.present?
      #   "<blockquote>#{argument_quote}</blockquote><span class=\"source\">#{argument_quote.citation_ref_html}</span>"
      # else
      #   "<blockquote>#{quote_and_text[0]}</blockquote>"
      # end
      # ["<div class=\"argument-quote-block\">#{quote_body}</div>", quote_and_text[1]]
    end
    html_output
  end
end
