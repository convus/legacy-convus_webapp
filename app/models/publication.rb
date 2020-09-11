class Publication < ApplicationRecord
  include TitleSluggable

  before_validation :set_calculated_attributes

  scope :published_retractions, -> { where(has_published_retractions: true) }

  def self.friendly_find(str)
    super || matching_base_domains(str).first
  end

  def self.matching_base_domains(str)
    where("base_domains @> ?", base_domains_for_url(str).to_json)
  end

  def self.base_domains_for_url(str)
    str = "http://#{str}" unless str.match?(/\Ahttp/i) # uri parse doesn't work without protocol
    uri = URI.parse(str)
    base_domain = uri.host&.downcase
    # unless the base_domain has "." and some characters, assume it's not a domain
    return [] unless base_domain.present? && base_domain.match?(/\..+/)
    base_domain.match?(/\Awww/) ? [base_domain, base_domain.gsub(/\Awww\./, "")] : [base_domain]
  rescue URI::InvalidURIError
    return []
  end

  def self.create_for_url(str)
    return nil unless str.present?
    matching = friendly_find(str)
    return matching if matching.present?
    base_domains = base_domains_for_url(str)
    return nil unless base_domains.any?
    home_url = str.split(base_domains.first).first + base_domains.first # Use .first because it will get with www.
    home_url = "http://#{home_url}" unless home_url.match?(/\Ahttp/i) # We need a protocol for home_url
    create(title: base_domains.last, home_url: home_url)
  end

  def published_retractions?
    has_published_retractions
  end

  def add_base_domain(str)
    bds = base_domains || []
    self.base_domains = (bds + self.class.base_domains_for_url(str)).uniq.sort
  end

  def set_calculated_attributes
    add_base_domain(home_url) if home_url.present?
  end
end
