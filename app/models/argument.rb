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
  scope :normal_user, -> { left_joins(:creator).where(users: {role: "normal_user"}) }

  attr_accessor :skip_associated_tasks

  def self.shown(user = nil)
    return approved unless user.present?
    approved.or(where(creator_id: user.id))
  end

  # Duplicates parseArgumentQuotes in argument_form.js
  def self.parse_quotes(text)
    matching_lines = []
    last_quote_line = nil
    text.split("\n").each_with_index do |line, index|
      # match lines that are blockquotes
      if line.match?(/\A\s*>/)
        # remove the >, trim the string,
        quote_text = line.gsub(/\A\s*>\s*/, "").strip
        # We need to group consecutive lines, because that's how markdown parses
        # So check if the last line was a quote and if so, update it
        if last_quote_line == (index - 1)
          quote_text = [matching_lines.pop, quote_text].join(" ")
        end
        matching_lines.push(quote_text)
        last_quote_line = index
      end
    end
    # - remove duplicates & ignore any empty quotes
    matching_lines.uniq.reject(&:blank?)
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

  def validate_can_add_to_github?
    if argument_quotes.count == 0
      errors.add(:base, "must have at least one quote")
    elsif argument_quotes.not_removed.no_url.any?
      errors.add(:base, "All quotes need to have URLs")
    end
    errors.full_messages.none?
  end

  # Actually serialized into hypothesis files, using a serializer to make it easier to manage
  def flat_file_serialized
    ArgumentSerializer.new(self, root: false).as_json
  end

  def run_associated_tasks
    update_ref_number if ref_number.blank?
    return false if skip_associated_tasks
    add_to_github_content
  end

  # Method to building from flat file content
  def update_from_text(passed_text, quote_urls: [])
    update(text: passed_text)
    quotes_from_text = self.class.parse_quotes(text)
    current_argument_quote_ids = []
    quotes_from_text.each_with_index do |quote, index|
      url = quote_urls[index]
      if url.present?
        # Make sure we don't grab the same quote multiple times
        matches = argument_quotes.where.not(id: current_argument_quote_ids).where(url: url)
        # Try to grab the match by text
        argument_quote = matches.where(text: quote).first
        # Fallback to just whatever is there
        argument_quote ||= matches.first
      end
      argument_quote ||= argument_quotes.where.not(id: current_argument_quote_ids).find_by_text(quote)
      argument_quote ||= argument_quotes.build
      argument_quote.update!(text: quote, url: url, ref_number: index + 1)
      current_argument_quote_ids << argument_quote.id
    end
    argument_quotes.where.not(id: current_argument_quote_ids).update_all(removed: true)
    remove_empty_quotes!
    reload
    update_body_html
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
    self
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
    # This is a dumb way of doing this, sorry, I'm tired (also, I don't think it handles nested blockquotes - but fuck them anyway)
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
    # numbers start at 1, just to fuck with future you
    update_columns(ref_number: new_ref_number + 1, listing_order: new_ref_number)
  end
end
