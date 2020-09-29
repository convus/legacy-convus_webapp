class Citation < ApplicationRecord
  include FriendlyFindable
  include FlatFileSerializable
  include ApprovedAtable

  # NOTE: Kind is deprecated, and can be removed sometime soon
  KIND_ENUM = {
    article: 0,
    closed_access_peer_reviewed: 1,
    article_by_publication_with_retractions: 2,
    quote_from_involved_party: 3,
    open_access_peer_reviewed: 4
  }.freeze

  FETCH_WAYBACK_URL = false # TODO: make this actually work

  belongs_to :publication
  belongs_to :creator, class_name: "User"

  has_many :hypothesis_citations, dependent: :destroy
  has_many :hypotheses, through: :hypothesis_citations

  validates_presence_of :url
  validates :slug, presence: true, uniqueness: {scope: [:publication_id]}

  enum kind: KIND_ENUM

  before_validation :set_calculated_attributes
  after_commit :add_to_github_content

  scope :by_creation, -> { reorder(:created_at) }

  attr_accessor :assignable_kind, :skip_add_citation_to_github

  def self.kinds
    KIND_ENUM.keys.map(&:to_s)
  end

  def self.kinds_data
    {
      article: {score: 1, humanized: "Article"},
      article_by_publication_with_retractions: {score: 2, humanized: "Article from a publisher that has issued retractions"},
      closed_access_peer_reviewed: {score: 3, humanized: "Non-public access research (anything than can not be accessed directly via a URL)"},
      quote_from_involved_party: {score: 5, humanized: "Online accessible quote from applicable person (e.g. personal website, tweet, or video)"},
      open_access_peer_reviewed: {score: 20, humanized: "Peer reviewed open access study"}
    }.freeze
  end

  def self.assignable_kinds
    %w[article peer_reviewed quote_from_involved_party]
  end

  def self.find_by_slug_or_path_slug(str)
    return none unless str.present?
    slug = Slugifyer.slugify(str.gsub(/\.yml\z/i, "")) # remove .yml extension, just in case
    where(path_slug: slug).by_creation.first || # exact path_slug matching
      where("path_slug ILIKE ?", "#{slug.truncate(250, omission: "")}%").by_creation.first || # filename truncation
      where(slug: slug).by_creation.first
  end

  def self.friendly_find_slug(str)
    matched = find_by_slug_or_path_slug(str)
    return matched if matched.present?
    # Only try the URL matching if it looks like a URL
    if UrlCleaner.looks_like_url?(str)
      matched = where(url: UrlCleaner.without_utm(str)).first
      return matched if matched.present?
      matched = where("lower(url) ILIKE ?", str.to_s.downcase.strip).first
      # If the beginning of the URL is missing (eg no http) try to make that work
      matched ||= where("lower(url) ILIKE ?", "%#{str.to_s.downcase.strip}").first
      # TODO: remove https://www if still no match, as more fallback
      return matched if matched.present?
    end
    # Try short slug finding
    short_slug = Slugifyer.filename_slugify(str)
    where("slug ILIKE ?", "#{short_slug}%").by_creation.first ||
      where("slug ILIKE ?", "%#{short_slug}%").by_creation.first
  end

  def self.find_or_create_by_params(attrs)
    return nil unless (attrs || {}).dig(:url).present?
    friendly_find(attrs[:url]) || create(attrs)
  end

  def to_param
    path_slug
  end

  def url_is_publisher?
    !url_is_not_publisher
  end

  def authors_str
    (authors || []).join("; ")
  end

  def publication_title
    publication&.title || @publication_title
  end

  def authors_str=(val)
    self.authors = val.split(/\n/).map(&:strip).reject(&:blank?)
  end

  def publication_title=(val)
    @publication_title = val
    self.publication = Publication.friendly_find(val)
  end

  def published_date_str
    published_at&.to_date&.to_s
  end

  # We're rounding to date - if/when there is a need for additional specificity, handle that previously was just date
  def published_date_str=(val)
    self.published_at = TimeParser.parse(val)&.beginning_of_day
  end

  def peer_reviewed?
    closed_access_peer_reviewed? || open_access_peer_reviewed?
  end

  def kind_data
    kind.present? && self.class.kinds_data.dig(kind.to_sym) || {}
  end

  def kind_humanized
    kind_data[:humanized]
  end

  def kind_humanized_short
    kind_humanized&.gsub(/\([^)]*\)/, "")
  end

  def kind_score
    kind_data[:score]
  end

  def badges
    HypothesisScorer.citation_badges(self)
  end

  def calculated_score
    badges.values.sum
  end

  # Required for FlatFileSerializable
  def file_pathnames
    ["citations", publication&.slug, "#{slug}.yml"].compact
  end

  # Required for FlatFileSerializable
  def flat_file_serialized
    CitationSerializer.new(self, root: false).as_json
  end

  def title_url?
    url.match?(title)
  end

  def set_calculated_attributes
    self.url = UrlCleaner.with_http(UrlCleaner.without_utm(url))
    self.creator_id ||= hypotheses.first&.creator_id
    self.publication ||= Publication.find_or_create_by_params(title: @publication_title, url: url, url_is_not_publisher: url_is_not_publisher)
    self.title = UrlCleaner.without_base_domain(url) unless title.present?
    self.slug = Slugifyer.filename_slugify(title)
    self.path_slug = [publication&.slug, slug].compact.join("-")
    self.kind ||= calculated_kind(assignable_kind)
    self.score = calculated_score
    if FETCH_WAYBACK_URL && url_is_direct_link_to_full_text
      self.wayback_machine_url ||= WaybackMachineIntegration.fetch_current_url(url)
    end
  end

  def add_to_github_content
    return true if approved? || pull_request_number.present? ||
      skip_add_citation_to_github || GithubIntegration::SKIP_GITHUB_UPDATE
    AddCitationToGithubContentJob.perform_async(id)
  end

  private

  def calculated_kind(kind_val = nil)
    kind_val = "article" unless self.class.assignable_kinds.include?(kind_val)
    if kind_val == "article"
      publication&.published_retractions? ? "article_by_publication_with_retractions" : "article"
    elsif kind_val == "peer_reviewed"
      url_is_direct_link_to_full_text ? "open_access_peer_reviewed" : "closed_access_peer_reviewed"
    else
      kind_val
    end
  end
end
