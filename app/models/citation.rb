class Citation < ApplicationRecord
  include FriendlyFindable
  include FlatFileSerializable
  include GithubSubmittable
  include PgSearch::Model

  KIND_ENUM = {
    article: 0,
    official_document: 1, # Includes patents
    legal_citation: 2, # Court decisions?
    government_statistics: 3,
    non_governmental_statistics: 4,
    quote_from_involved_party: 5,
    research: 10,
    research_with_rct: 11,
    research_review: 12,
    research_meta_analysis: 13,
    research_comment: 14
    # maybe case_study?
  }.freeze

  FETCH_WAYBACK_URL = false # TODO: make this actually work

  belongs_to :publication
  belongs_to :creator, class_name: "User"

  has_many :explanation_quotes
  has_many :explanation_quotes_not_removed, -> { not_removed }, class_name: "ExplanationQuote"
  has_many :explanation_quotes_approved, -> { approved }, class_name: "ExplanationQuote"
  has_many :hypotheses, through: :explanation_quotes_not_removed

  validates_presence_of :url
  validates :slug, presence: true, uniqueness: {scope: [:publication_id]}

  enum kind: KIND_ENUM

  before_validation :set_calculated_attributes
  after_commit :add_to_github_content

  scope :by_creation, -> { reorder(:created_at) }

  pg_search_scope :text_search, against: %i[title slug] # TODO: Create tsvector indexes for performance (issues/92)

  def self.kinds
    KIND_ENUM.keys.map(&:to_s)
  end

  def self.kinds_research
    %w[research_comment research_review research_meta_analysis research research_with_rct].freeze
  end

  def self.kinds_data
    {
      article: {humanized: "article"},
      official_document: {humanized: "official document"},
      legal_citation: {humanized: "legal citation"},
      government_statistics: {humanized: "government statistics"},
      non_governmental_statistics: {humanized: "non governmental statistics"},
      quote_from_involved_party: {humanized: "quote from involved party"},
      research: {humanized: "original research"},
      research_with_rct: {humanized: "research with randomized controlled trial"},
      research_review: {humanized: "research review"},
      research_meta_analysis: {humanized: "research meta analysis"},
      research_comment: {humanized: "published research comment"}
    }.freeze
  end

  # Used in flat file import and in controller, so define here
  def self.permitted_attrs
    %i[title authors_str kind url url_is_direct_link_to_full_text published_date_str doi
      url_is_not_publisher publication_title peer_reviewed randomized_controlled_trial]
  end

  def self.kind_humanized(kind)
    kinds_data.dig(kind&.to_sym, :humanized)
  end

  def self.friendly_find_kind(str)
    return nil unless str.present?
    str = str.to_s.strip
    return str.tr(" ", "_") if kinds.include?(str.tr(" ", "_"))
    KIND_ENUM.keys.find do |k, v|
      kinds_data.dig(k, :humanized) == str
    end&.to_s
  end

  def self.find_by_slug_or_path_slug(str)
    return none unless str.present?
    slug = Slugifyer.slugify(str.gsub(/\.yml\z/i, "")) # remove .yml extension, just in case
    where(path_slug: slug).by_creation.first || # exact path_slug matching
      where("path_slug ILIKE ?", "#{slug.truncate(240, omission: "")}%").by_creation.first || # filename truncation
      where(slug: slug).by_creation.first
  end

  def self.friendly_find_slug(str)
    matched = find_by_slug_or_path_slug(str)
    return matched if matched.present?
    # Only try the URL matching if it looks like a URL
    if UrlCleaner.looks_like_url?(str)
      matched = where(url: UrlCleaner.without_utm(str)).first
      return matched if matched.present?
      matched = where("lower(citations.url) ILIKE ?", str.to_s.downcase.strip).first
      # If the beginning of the URL is missing (eg no http) try to make that work
      matched ||= where("lower(citations.url) ILIKE ?", "%#{str.to_s.downcase.strip}").first
      # TODO: remove https://www if still no match, as more fallback
      return matched if matched.present?
    end
    # Try short slug finding
    short_slug = Slugifyer.filename_slugify(str)
    where("slug ILIKE ?", "#{short_slug}%").by_creation.first ||
      where("slug ILIKE ?", "%#{short_slug}%").by_creation.first
  end

  def self.find_or_create_by_params(attrs)
    existing = friendly_find(attrs[:url]) if (attrs || {}).dig(:url).present?
    return create(attrs) if existing.blank?
    existing
  end

  def to_param
    path_slug
  end

  def url_is_publisher?
    !url_is_not_publisher
  end

  def wikipedia?
    publication&.wikipedia?
  end

  def authors_str
    (authors || []).join("; ")
  end

  def publication_title
    publication&.title || @publication_title
  end

  def display_title
    [publication_title, title].uniq.join(": ")
  end

  def authors_str=(val)
    self.authors = val.split(/\n|;/).map(&:strip).reject(&:blank?)
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
    self.class.kind_humanized(kind)
  end

  def kind_humanized_short
    kind_humanized&.gsub(/\([^)]*\)/, "")
  end

  def kind_selectable?
    true # Should be false if the URL is wikipedia, probably some other publishers too
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

  def quotes
    explanation_quotes_not_removed.ref_ordered.pluck(:text).uniq
  end

  def quotes_approved
    explanation_quotes_approved.ref_ordered.pluck(:text).uniq
  end

  def skip_author_field?
    wikipedia?
  end

  def skip_published_at_field?
    wikipedia?
  end

  def skip_url_is_direct_link_to_full_text_field?
    wikipedia?
  end

  def set_calculated_attributes
    self.url = UrlCleaner.with_http(UrlCleaner.without_utm(url))
    self.creator_id ||= explanation_quotes.first&.creator_id
    self.publication ||= Publication.find_or_create_by_params(title: @publication_title, url: url, url_is_not_publisher: url_is_not_publisher)
    self.title = UrlCleaner.without_base_domain(url) unless title.present?
    self.slug = Slugifyer.filename_slugify(title)
    self.path_slug = [publication&.slug, slug].compact.join("-")
    self.kind ||= "article" # default to article for now
    self.authors ||= []
    self.url_is_direct_link_to_full_text = true if wikipedia?
    if FETCH_WAYBACK_URL && url_is_direct_link_to_full_text
      self.wayback_machine_url ||= WaybackMachineIntegration.fetch_current_url(url)
    end
  end
end
