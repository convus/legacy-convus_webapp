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
    where("base_domains @> ?", [UrlCleaner.base_domain_without_www(str)].to_json)
  end

  def self.create_for_url(str)
    return nil unless str.present?
    matching = friendly_find(str)
    if matching.present?
      matching.add_base_domain(str)
      matching.save if matching.changed? # Add any new base domains
      return matching
    end
    base_domains = UrlCleaner.base_domains(str)
    return nil unless base_domains.any?
    home_url = str.split(base_domains.first).first + base_domains.first # Use .first because it will get with www.
    create(title: base_domains.last, home_url: home_url)
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
