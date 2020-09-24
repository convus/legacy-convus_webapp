class Publication < ApplicationRecord
  include TitleSluggable

  has_many :citations
  has_many :hypotheses, through: :citations

  before_validation :set_calculated_attributes

  scope :published_retractions, -> { where(has_published_retractions: true) }
  scope :alphabetical, -> { reorder("lower(title)") }

  def self.friendly_find(str)
    super || matching_base_domains(str).first
  end

  def self.matching_base_domains(str)
    return none unless UrlCleaner.looks_like_url?(str)
    where("base_domains @> ?", [UrlCleaner.base_domain_without_www(str)].to_json)
  end

  def self.find_or_create_by_params(title: nil, url: nil)
    matching = friendly_find(title) || friendly_find(url)
    if matching.present?
      matching.add_base_domain(url) if url.present?
      matching.title = title if title.present? && matching.title_url?
      matching.save if matching.changed? # Add any new base domains
      return matching
    end
    publication = new(title: title)
    if url.present?
      base_domains = UrlCleaner.base_domains(url)
      return nil if base_domains.none? && title.blank?
      # Use .first for url because it will include www.
      publication.home_url = url.split(base_domains.first).first + base_domains.first
      publication.title ||= base_domains.last
    end
    publication.save
    publication
  end

  def self.serialized_attrs
    %i[title id meta_publication has_published_retractions has_peer_reviewed_articles home_url].freeze
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
  end
end
