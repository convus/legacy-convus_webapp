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
    approved || creator_id == user&.id
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

  def parse_text
    return "" unless text.present?
    argument_markdown.render(text.strip)
      .gsub(/(<\/?)h\d+/i, '\1p') # Remove header open brackets and close brackets
  end
end
