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
  # ... Leave space for the extension (and ref_id) by truncating at 240
  # NOTE: if updating, also update Citation#find_by_slug_or_path_slug
  def self.filename_slugify(string)
    return nil if string.blank?
    # Remove filename parts, because we don't want to slugify them
    string = string.to_s.strip.downcase
      .gsub(/\A(hypotheses\/)?[0-z]+_/, "") # Remove leading hypotheses/{ref_id}_
      .gsub(/\Acitations\//, "") # Remove citations folder
      .gsub(/\.yml\z/, "") # Remove trailing .yml
      .gsub(/\.md\z/, "") # Remove trailing .md
    slugify(string)&.truncate(240, omission: "")
      &.delete_suffix("-") # Remove trailing -
  end
end
