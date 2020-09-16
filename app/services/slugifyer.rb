class Slugifyer
  def self.slugify(string)
    return nil unless string.present?
    # First, remove diacritics, downcase and strip
    I18n.transliterate(string.to_s.downcase).strip
      .gsub(/\(|\)/, "").strip # Remove parentheses
      .gsub(/https?:\/\//, "") # remove http://
      .gsub(/(\s|-|\+|_)+/, "-") # Replace spaces with -
      .gsub(/-&-/, "-amp-") # Replace singular & with amp - since we permit & in names
      .gsub(/([^A-Za-z0-9_\-]+)/, "-").squeeze("-") # Remove any lingering double -
      .gsub(/(\s|-|\+|_)+/, "-") # Replace spaces and underscores with -
      .gsub(/-&-/, "-amp-").squeeze("-") # Remove any lingering double -
      .gsub(/-\z/, "") # Remove trailing - ... this might cause problems down the road
  end
end
