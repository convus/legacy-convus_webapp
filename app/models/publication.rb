class Publication < ApplicationRecord
  include TitleSluggable

  has_many :citations
  has_many :hypotheses, through: :citations

  before_validation :set_calculated_attributes
  after_commit :update_associations

  scope :published_retractions, -> { where(has_published_retractions: true) }
  scope :alphabetical, -> { reorder("lower(title)") }

  def self.friendly_find(str)
    super || matching_base_domains(str).first
  end

  def self.matching_base_domains(str)
    return none unless UrlCleaner.looks_like_url?(str)
    where("base_domains @> ?", [UrlCleaner.base_domain_without_www(str)].to_json)
  end

  # TODO: Re-factor, because this is confusing. This is well tested, so have at it!
  # IN REALITY this method is find_or_create_by_citation_params
  def self.find_or_create_by_params(title: nil, url: nil, url_is_not_publisher: false)
    meta_publication = title.blank? && url_is_not_publisher
    matching = friendly_find(title) || friendly_find(url)
    if matching.present? && matching.meta_publication
      # as a meta_publication, if passed a publication title, that is the title (not the meta_publication's title)
      return matching if title.blank? || Slugifyer.slugify(title) == matching.slug
      # otherwise, we want to create a new publication without a URL (since the URL is the meta_publication's URL)
      url_is_not_publisher = true
    elsif matching.present?
      matching.home_url ||= url # If assigning here, publication probably created with a meta_publication URL
      matching.add_base_domain(url) if url.present?
      matching.title = title if title.present? && matching.title_url?
      matching.meta_publication = meta_publication if meta_publication # Ignore false meta_publication
      matching.save if matching.changed? # Add any new base domains
      return matching
    end
    publication = new(title: title, meta_publication: meta_publication)
    if url.present?
      if !url_is_not_publisher || meta_publication
        base_domains = UrlCleaner.base_domains(url)
        return nil if base_domains.none? && title.blank?
        # Use .first for url because it will include www.
        publication.home_url = url.split(base_domains.first).first + base_domains.first
        publication.title ||= base_domains.last
      end
    end
    publication.save
    publication
  end

  def self.serialized_attrs
    %i[title id meta_publication has_published_retractions has_peer_reviewed_articles impact_factor home_url].freeze
  end

  def badges
    HypothesisScorer.publication_badges(self)
  end

  def score
    badges.values.sum
  end

  def title_url?
    ((base_domains || []) + [home_url]).compact.any? { |url| url.match?(title) }
  end

  def published_retractions?
    has_published_retractions
  end

  def add_base_domain(str)
    bds = base_domains || []
    self.base_domains = (bds + UrlCleaner.base_domains(str)).uniq.sort
  end

  def set_calculated_attributes
    if home_url.present?
      self.home_url = "http://#{home_url}" unless home_url.start_with?(/http/i) # We need a protocol for home_url
      add_base_domain(home_url)
    end
    self.impact_factor = nil if impact_factor.to_i <= 0
    @update_citations_for_meta_publication = meta_publication_changed?(from: false, to: true)
  end

  def update_associations
    # We're only updating on changing meta_publication from false to true
    return true unless @update_citations_for_meta_publication
    citations.update_all(url_is_not_publisher: true)
  end
end
