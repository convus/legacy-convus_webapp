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
      .gsub(/-&-/, "-amp-").squeeze("-") # Remove lingering double -
      .delete_prefix("-").delete_suffix("-") # remove leading and trailing -
  end

  # Filenames are limited to 255 characters, so truncate the slug
  # ... Leave space for the extension by truncating at 250
  def self.filename_slugify(string)
    slugify(string)&.truncate(250, omission: "")
  end
end
