class Hypothesis < ApplicationRecord
  include TitleSluggable
  include FlatFileSerializable
  include ApprovedAtable

  belongs_to :creator, class_name: "User"

  has_many :hypothesis_citations, dependent: :destroy
  has_many :citations, through: :hypothesis_citations
  has_many :publications, through: :citations
  has_many :hypothesis_tags
  has_many :tags, through: :hypothesis_tags

  accepts_nested_attributes_for :citations

  before_validation :set_calculated_attributes
  after_commit :add_to_github_content

  scope :direct_quotation, -> { where(has_direct_quotation: true) }

  def self.with_tags(string_or_array)
    with_tag_ids(Tag.matching_tags(string_or_array).pluck(:id))
  end

  def self.with_tag_ids(tag_ids_array)
    joins(:hypothesis_tags).distinct.where(hypothesis_tags: {tag_id: tag_ids_array})
      .group("hypotheses.id").having("count(*) = ?", tag_ids_array.count)
  end

  def direct_quotation?
    has_direct_quotation
  end

  def tag_titles
    tags.alphabetical.pluck(:title)
  end

  def tags_string
    tag_titles.join(", ")
  end

  def tags_string=(val)
    new_tags = (val.is_a?(Array) ? val : val.to_s.split(/,|\n/)).reject(&:blank?)
    new_ids = new_tags.map { |string|
      tag_id = Tag.find_or_create_for_title(string)&.id
      unless hypothesis_tags.find_by_tag_id(tag_id).present?
        hypothesis_tags.build(tag_id: tag_id)
      end
      tag_id
    }
    hypothesis_tags.where.not(tag_id: new_ids).destroy_all
    tags
  end

  def citation_for_score
    citations.approved.first # TODO: Make this grab the citation with the highest score (and add tests)
  end

  def citation_urls
    citations.pluck(:url)
  end

  def citation_urls=(val)
    new_citations = (val.is_a?(Array) ? val : val.to_s.split(/,|\n/)).reject(&:blank?)
    new_ids = new_citations.map { |string|
      citation_id = Citation.find_or_create_by_params({url: string})&.id
      unless hypothesis_citations.find_by_citation_id(citation_id).present?
        hypothesis_citations.build(citation_id: citation_id)
      end
      citation_id
    }
    hypothesis_citations.where.not(citation_id: new_ids).destroy_all
    citations
  end

  def badges
    HypothesisScorer.citation_badges(self)
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

  def set_calculated_attributes
    self.points = badges.values.sum
  end
end
