class Slugifyer
  def self.slugify(string)
    return nil unless string.present?
    # TODO: handle non-url permitted characters
    string.to_s.downcase
      .gsub(/(\s|-|\+|_)+/, "-") # Replace spaces and underscores with -
      .gsub(/-&-/, "-amp-").squeeze("-") # Remove any lingering double -
  end
end
