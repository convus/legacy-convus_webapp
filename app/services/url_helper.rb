class UrlHelper
  def self.base_domains(str)
    str = "http://#{str}" unless str.match?(/\Ahttp/i) # uri parse doesn't work without protocol
    uri = URI.parse(str)
    base_domain = uri.host&.downcase
    # Unless the base_domain has "." and some characters, assume it's not a domain
    return [] unless base_domain.present? && base_domain.match?(/\..+/)
    # If the domain starts with www. add both that and the bare domain
    base_domain.start_with?(/www\./) ? [base_domain, base_domain.delete_prefix("www.")] : [base_domain]
  rescue URI::InvalidURIError
    []
  end

  def self.base_domain_without_www(str)
    base_domains(str).last # Last in array will not have www
  end

  # Might not really be doing too much, but... leaves room for doing more later - e.g. stripping query params
  def self.pretty_url(str)
    return str unless str.present?
    str.gsub(/\Ahttps?:\/\//i, "").gsub(/\/\z/, "")
  end


  def self.without_base_domain(str)
    return nil unless str.present?
    # Get the first domain - which will be the actual base domain passed in
    base_domain = base_domains(str).first
    return str unless base_domain.present?
    str.split(base_domain).last&.gsub(/\A\//, "")&.gsub(/\/\z/, "")
  end
end
