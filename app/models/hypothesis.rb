class Hypothesis < ApplicationRecord
  include TitleSluggable
  include FlatFileSerializable
  include GithubSubmittable
  include PgSearch::Model

  belongs_to :creator, class_name: "User"

  has_many :previous_titles
  has_many :publications, through: :citations
  has_many :hypothesis_tags, dependent: :destroy
  has_many :tags, through: :hypothesis_tags
  has_many :explanations
  has_many :explanation_quotes
  has_many :explanation_quotes_not_removed, -> { not_removed }, class_name: "ExplanationQuote"
  has_many :citations, -> { distinct }, through: :explanation_quotes_not_removed
  has_many :user_scores

  before_validation :set_calculated_attributes
  after_commit :run_associated_tasks

  attr_accessor :skip_associated_tasks, :additional_serialized_explanation

  scope :normal_user, -> { left_joins(:creator).where(users: {role: "normal_user"}) }

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

  def self.punctuate_title(str)
    return nil unless str.present?
    str.strip!
    str.match?(/(\.|!|\?)\z/) ? str : "#{str}."
  end

  def relations
    HypothesisRelation.matching_hypothesis(id)
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

  def citation_urls
    citations.pluck(:url)
  end

  def title_with_ref_id
    "#{ref_id}: #{title}"
  end

  # Required for FlatFileSerializable
  def file_pathnames
    ["hypotheses", "#{ref_id}_#{slug}.md"]
  end

  # used in testing
  def flat_file_serialized(passed_explanations: nil)
    markdown_serializer(passed_explanations: passed_explanations).as_json
  end

  def flat_file_content(passed_explanations: nil)
    markdown_serializer(passed_explanations: passed_explanations).to_markdown
  end

  def run_associated_tasks
    update_ref_number if ref_id.blank?
    self.ref_number ||= ref_id.to_i(36) # In case this was created via external things
    # Always try to create previous titles - even if skip_associated_tasks
    if approved? && title_previous_change.present?
      StorePreviousHypothesisTitleJob.perform_async(id, title_previous_change.first)
    end
    return false if skip_associated_tasks
    add_to_github_content
  end

  def set_calculated_attributes
    self.title = self.class.punctuate_title(title)
  end

  private

  def update_ref_number
    # NOTE: eventually manage ref_number with Redis, to enable external creation
    new_ref_number = ref_number || id
    update_columns(ref_number: new_ref_number, ref_id: new_ref_number.to_s(36).upcase)
  end

  def markdown_serializer(passed_explanations: nil)
    HypothesisMarkdownSerializer.new(hypothesis: self, explanations: passed_explanations)
  end
end
