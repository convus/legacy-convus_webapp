class Citation < ApplicationRecord
  include FriendlyFindable

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

  has_many :assertion_citations
  has_many :assertions, through: :assertion_citations

  validates_presence_of :creator_id, :url

  enum kind: KIND_ENUM

  before_validation :set_calculated_attributes

  attr_accessor :assignable_kind

  def self.kinds
    KIND_ENUM.keys.map(&:to_s)
  end

  def self.kinds_data
    {
      article: {score: 1, humanized: "Article"},
      closed_access_peer_reviewed: {score: 2, humanized: "Non-public access research (anything than can not be accessed directly via a URL)"},
      article_by_publication_with_retractions: {score: 3, humanized: "Article from a publisher which has issued retractions"},
      quote_from_involved_party: {score: 10, humanized: "Online accessible quote from applicable person (e.g. personal website, tweet, or video)"},
      open_access_peer_reviewed: {score: 20, humanized: "Peer reviewed open access study"}
    }.freeze
  end

  def self.assignable_kinds
    %w[article peer_reviewed quote_from_involved_party]
  end

  def self.friendly_find(str)
    super || friendly_find_fallback(str)
  end

  def self.friendly_find_fallback(str)
    matched = where("lower(url) ILIKE ?", str.to_s.downcase.strip).first
    return matched if matched.present?
    slugged = Slugifyer.slugify(str)
    where("slug ILIKE ?", "#{slugged}%").first || where("slug ILIKE ?", "%#{slugged}%").first
  end

  def self.find_or_create_by_params(attrs)
    friendly_find(attrs[:url]) || create(attrs)
  end

  def authors_str
    (authors || []).join("; ")
  end

  def publication_name
    publication&.title
  end

  def authors_str=(val)
    self.authors = val.split(/\n/).map(&:strip).reject(&:blank?)
  end

  def published_at_str
    published_at&.to_s
  end

  def published_at_str=(val)
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

  def kind_score
    kind_data[:score]
  end

  def set_calculated_attributes
    self.creator_id ||= assertions.first&.creator_id
    self.publication ||= Publication.create_for_url(url)
    self.title ||= title_from_url(url)
    self.slug = Slugifyer.slugify([publication_name, title].compact.join("-"))
    self.kind ||= calculated_kind(assignable_kind)
    if FETCH_WAYBACK_URL && url_is_direct_link_to_full_text
      self.wayback_machine_url ||= WaybackMachineIntegration.fetch_current_url(url)
    end
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

  def title_from_url(str)
    return nil unless str.present?
    base_domain = Publication.base_domains_for_url(str).first
    return str unless base_domain.present?
    str.split(base_domain).last&.gsub(/\A\//, "")&.gsub(/\/\z/, "")
  end
end
