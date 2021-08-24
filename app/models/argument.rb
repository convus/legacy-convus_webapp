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

  attr_accessor :skip_associated_tasks

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
  end
end
