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
  has_many :refuting_refutations, class_name: "Refutation", foreign_key: :refuted_hypothesis_id
  has_many :refuted_by_hypotheses, through: :refuting_refutations, source: :refuter_hypothesis
  has_many :refuter_refutations, class_name: "Refutation", foreign_key: :refuter_hypothesis_id
  has_many :refutes_hypotheses, through: :refuter_refutations, source: :refuted_hypothesis

  accepts_nested_attributes_for :hypothesis_citations, allow_destroy: true, reject_if: :all_blank

  before_validation :set_calculated_attributes
  after_commit :run_associated_tasks

  scope :unrefuted, -> { where(refuted_at: nil) }
  scope :refuted, -> { where.not(refuted_at: nil) }

  attr_accessor :add_to_github, :skip_associated_tasks

  pg_search_scope :text_search, against: :title

  def self.with_tags(string_or_array)
    with_tag_ids(Tag.matching_tags(string_or_array).pluck(:id))
  end

  def self.with_tag_ids(tag_ids_array)
    joins(:hypothesis_tags).distinct.where(hypothesis_tags: {tag_id: tag_ids_array})
      .group("hypotheses.id").having("count(*) = ?", tag_ids_array.count)
  end

  def self.matching_previous_titles(str)
    PreviousTitle.friendly_matching(str)
  end

  def self.friendly_find(str)
    super || matching_previous_titles(str).last&.hypothesis
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

  def refuted?
    refuted_at.present?
  end

  def unrefuted?
    !refuted?
  end

  def refuted_by_hypotheses_str=(val)
    # Hypothesis titles can have commas and line breaks - so we can't actually split the string. Really should pass an array
    refuted_arr = val.is_a?(Array) ? val : [val.to_s]
    new_ids = refuted_arr.map { |string|
      refuting_hypothesis = Hypothesis.friendly_find(string)
      next if refuting_hypothesis.blank?
      if refuting_refutations.where(refuter_hypothesis_id: refuting_hypothesis.id).blank?
        refuting_refutations.build(refuter_hypothesis: refuting_hypothesis)
      end
      refuting_hypothesis.id
    }
    refuting_refutations.where.not(refuter_hypothesis_id: new_ids).destroy_all
    refuting_refutations
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
    ["hypotheses", "#{slug}.yml"]
  end

  # Required for FlatFileSerializable
  def flat_file_serialized
    HypothesisSerializer.new(self, root: false).as_json
  end

  def run_associated_tasks
    # Always try to create previous titles - even if skip_associated_tasks
    if approved? && title_previous_change.present?
      StorePreviousHypothesisTitleJob.perform_async(id, title_previous_change.first)
    end
    return false if skip_associated_tasks
    citations.pluck(:id).each { |i| UpdateCitationQuotesJob.perform_async(i) }
    add_to_github_content
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
    if refuted_at.present?
      self.refuted_at = nil if refuted_by_hypotheses.none?
    elsif refuted_by_hypotheses.any?
      self.refuted_at = Time.current
    end
  end

  def calculated_score
    badges.values.sum
  end

  def unapproved_score
    unapproved_badges.values.sum
  end
end
