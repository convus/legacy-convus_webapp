class Hypothesis < ApplicationRecord
  include TitleSluggable
  include FlatFileSerializable

  belongs_to :creator, class_name: "User"

  has_many :hypothesis_citations, dependent: :destroy
  has_many :citations, through: :hypothesis_citations
  has_many :hypothesis_tags
  has_many :tags, through: :hypothesis_tags

  accepts_nested_attributes_for :citations

  after_commit :add_to_github_content

  scope :direct_quotation, -> { where(has_direct_quotation: true) }
  scope :approved, -> { where.not(approved_at: nil) }
  scope :unapproved, -> { where(approved_at: nil) }

  def approved?
    approved_at.present?
  end

  def unapproved?
    !approved?
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

  # Required for FlatFileSerializable
  def file_pathnames
    ["hypotheses", "#{slug}.yml"]
  end

  # Required for FlatFileSerializable
  def flat_file_serialized
    HypothesisSerializer.new(self, root: false).as_json
  end

  def add_to_github_content
    return true if approved? || pull_request_number.present?
    AddHypothesisToGithubContentJob.perform_async(id)
  end
end
