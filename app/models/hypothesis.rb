class Hypothesis < ApplicationRecord
  include TitleSluggable
  include FlatFileSerializable
  include ApprovedAtable
  include GithubSubmittable
  include PgSearch::Model

  belongs_to :creator, class_name: "User"

  has_many :previous_titles
  has_many :hypothesis_citations, autosave: true, dependent: :destroy
  has_many :citations, through: :hypothesis_citations
  has_many :publications, through: :citations
  has_many :hypothesis_tags, dependent: :destroy
  has_many :tags, through: :hypothesis_tags
  has_many :hypothesis_quotes, -> { score_ordered }
  has_many :quotes, through: :hypothesis_quotes
  has_many :user_scores

  accepts_nested_attributes_for :hypothesis_citations, allow_destroy: true, reject_if: :all_blank

  before_validation :set_calculated_attributes
  after_commit :run_associated_tasks

  attr_accessor :add_to_github, :skip_associated_tasks, :included_unapproved_hypothesis_citation

  pg_search_scope :text_search, against: :title # TODO: Create tsvector indexes for performance (issues/92)

  def self.with_tags(string_or_array)
    with_tag_ids(Tag.matching_tags(string_or_array).pluck(:id))
  end

  def self.with_tag_ids(tag_ids_array)
    joins(:hypothesis_tags).distinct.where(hypothesis_tags: {tag_id: tag_ids_array})
      .group("hypotheses.id").having("count(*) = ?", tag_ids_array.count)
  end

  def self.matching_previous_titles(str)
    PreviousTitle.friendly_matching(str).map(&:hypothesis)
  end

  def self.find_ref_id(str)
    str.present? ? find_by_ref_id(str.to_s.upcase.strip) : nil
  end

  def self.friendly_find(str)
    found = find_ref_id(str)
    # Preference ref_id lookup (in filepath or in id:)
    if found.blank? && str.is_a?(String)
      found = if str.match?(/\A(hypotheses\/)?[0-z]+_/i)
        find_ref_id(str.gsub("hypotheses/", "").split("_").first)
      elsif str.match?(/\A[0-z]+:/) # Looks like a base36 ID string!
        find_ref_id(str.split(":").first)
      end
    end
    found || super || matching_previous_titles(str).last
  end

  # We're saving hypothesis with a bunch of associations, make it easier to override the errors
  # So that association errors are clearer
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
    ignored_messages = [
      "Hypothesis citations url can't be blank",
      "Hypothesis quotes is invalid",
      "Hypothesis citations hypothesis has already been taken"
    ]
    (messages + errors.full_messages).compact.uniq - ignored_messages
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
    CitationScorer.hypothesis_badges(self, citation_for_score)
  end

  def unapproved_badges
    CitationScorer.hypothesis_badges(self, citations.order(:score).last)
  end

  # Required for FlatFileSerializable
  def file_pathnames
    ["hypotheses", "#{ref_id}_#{slug}.yml"]
  end

  # Required for FlatFileSerializable
  def flat_file_serialized
    HypothesisSerializer.new(self, root: false).as_json
  end

  def run_associated_tasks
    update_ref_number if ref_id.blank?
    # Always try to create previous titles - even if skip_associated_tasks
    if approved? && title_previous_change.present?
      StorePreviousHypothesisTitleJob.perform_async(id, title_previous_change.first)
    end
    return false if skip_associated_tasks
    citations.pluck(:id).each { |i| UpdateCitationQuotesJob.perform_async(i) }
    add_to_github_content
  end

  def set_calculated_attributes
    self.title = title&.strip
    self.score = calculated_score
  end

  def calculated_score
    badges.values.sum
  end

  def unapproved_score
    unapproved_badges.values.sum
  end

  private

  def update_ref_number
    # NOTE: eventually manage ref_number with Redis, to enable external creation
    new_ref_number = ref_number || id
    update_columns(ref_number: new_ref_number, ref_id: new_ref_number.to_s(36).upcase)
  end
end
