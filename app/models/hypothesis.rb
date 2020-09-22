class Hypothesis < ApplicationRecord
  include TitleSluggable

  belongs_to :creator, class_name: "User"

  has_many :hypothesis_citations
  has_many :citations, through: :hypothesis_citations
  has_many :hypothesis_tags
  has_many :tags, through: :hypothesis_tags

  accepts_nested_attributes_for :citations

  scope :direct_quotation, -> { where(has_direct_quotation: true) }
  scope :approved, -> { where.not(approved_at: nil) }

  def approved?
    approved_at.present?
  end

  def direct_quotation?
    has_direct_quotation || hypothesis_citations.direct_quotation.any?
  end

  def tags_string
    tags.alphabetical.pluck(:title).join(", ")
  end

  def tags_string=(val)
    new_tags = (val.is_a?(Array) ? val : val.to_s.split(/,|\n/)).reject(&:blank?)
    new_ids = new_tags.map { |string|
      tag_id = Tag.find_or_create_for_title(string)&.id
      hypothesis_tags.build(tag_id: tag_id)
      tag_id
    }
    hypothesis_tags.where.not(tag_id: new_ids).destroy_all
    tags
  end

  def citation_urls
    citations.pluck(:url)
  end

  def citation_urls=(val)
    new_citations = (val.is_a?(Array) ? val : val.to_s.split(/,|\n/)).reject(&:blank?)
    new_ids = new_citations.map { |string|
      citation_id = Citation.find_or_create_by_params({url: string})&.id
      hypothesis_citations.build(citation_id: citation_id)
      citation_id
    }
    hypothesis_citations.where.not(citation_id: new_ids).destroy_all
    citations
  end

  def file_pathnames
    ["hypotheses", "#{slug}.yml"]
  end

  def file_path
    file_pathnames.join("/")
  end

  def flat_file_name(root_path)
    File.join(root_path, *file_pathnames)
  end

  def github_html_url
    approved? ? GithubIntegration.content_html_url(file_path) : pull_request_url
  end

  def pull_request_url
    GithubIntegration.pull_request_html_url(pull_request_id)
  end
end
