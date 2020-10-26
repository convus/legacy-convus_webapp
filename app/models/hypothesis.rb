class Hypothesis < ApplicationRecord
  include TitleSluggable
  include FlatFileSerializable
  include ApprovedAtable
  include GithubSubmittable

  belongs_to :creator, class_name: "User"

  has_many :hypothesis_citations, autosave: true, dependent: :destroy
  has_many :citations, through: :hypothesis_citations
  has_many :publications, through: :citations
  has_many :hypothesis_tags
  has_many :tags, through: :hypothesis_tags
  has_many :hypothesis_quotes, -> { score_ordered }
  has_many :quotes, through: :hypothesis_quotes

  accepts_nested_attributes_for :hypothesis_citations, allow_destroy: true, reject_if: :all_blank

  before_validation :set_calculated_attributes
  after_commit :add_to_github_content

  scope :direct_quotation, -> { where(has_direct_quotation: true) }

  attr_accessor :add_to_github

  def self.with_tags(string_or_array)
    with_tag_ids(Tag.matching_tags(string_or_array).pluck(:id))
  end

  def self.with_tag_ids(tag_ids_array)
    joins(:hypothesis_tags).distinct.where(hypothesis_tags: {tag_id: tag_ids_array})
      .group("hypotheses.id").having("count(*) = ?", tag_ids_array.count)
  end

  # We're saving hypothesis with a bunch of associations, make it easier to override the errors
  # So that association errors are less annoying.
  def errors_full_messages
    # autosave: true makes this slightly less annoying
    messages = hypothesis_citations.map { |hc|
      next ["Citation URL can't be blank"] if hc.errors&.full_messages&.include?("Url can't be blank")
      next [] unless hc.errors.full_messages.any?
      if hc.errors.full_messages.include?("Citation can't be blank")
        ["Citation URL can't be blank"]
      else
        hc.errors.full_messages
      end
    }.flatten
    ignored_messages = ["Hypothesis citations url can't be blank"]
    (messages + errors.full_messages).compact.uniq - ignored_messages
  end

  def direct_quotation?
    has_direct_quotation
  end

  def tag_titles
    tags.alphabetical.pluck(:title)
  end

  def tags_string
    if defined?(@updated_tags)
      @updated_tags.sort_by(&:downcase).compact.uniq.join(", ")
    else
      tag_titles.join(", ")
    end
  end

  def tags_string=(val)
    new_tags = (val.is_a?(Array) ? val : val.to_s.split(/,|\n/)).reject(&:blank?)
    @updated_tags = []
    new_ids = new_tags.map { |string|
      tag = Tag.find_or_create_for_title(string)
      @updated_tags << tag.title
      unless hypothesis_tags.find_by_tag_id(tag.id).present?
        hypothesis_tags.build(tag_id: tag.id)
      end
      tag.id
    }
    hypothesis_tags.where.not(tag_id: new_ids).destroy_all
    tags
  end

  def citation_for_score
    citations.approved.order(:score).last
  end

  def citation_urls
    citations.pluck(:url)
  end

  def badges
    HypothesisScorer.hypothesis_badges(self, citation_for_score)
  end

  def unapproved_badges
    HypothesisScorer.hypothesis_badges(self, citations.order(:score).last)
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
    return true if submitted_to_github? || GithubIntegration::SKIP_GITHUB_UPDATE
    return false unless ParamsNormalizer.boolean(add_to_github)
    AddHypothesisToGithubContentJob.perform_async(id)
    # Because we've enqueued, and we want the fact that it is submitted to be reflected instantly
    update(submitting_to_github: true)
  end

  def set_calculated_attributes
    self.score = calculated_score
  end

  def calculated_score
    badges.values.sum
  end

  def unapproved_score
    unapproved_badges.values.sum
  end
end
