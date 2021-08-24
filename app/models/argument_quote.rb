class ArgumentQuote < ApplicationRecord
  belongs_to :argument
  belongs_to :citation
  belongs_to :creator, class_name: "User"

  before_validation :set_calculated_attributes

  scope :ref_ordered, -> { reorder(:ref_number) }
  scope :removed, -> { where(removed: true) }
  scope :not_removed, -> { where(removed: false) }

  def ref_number_display
    ref_number + 1 # Off by 1
  end

  def removed?
    removed
  end

  def not_removed?
    !removed?
  end

  def citation_ref_text
    if citation.present?
      [citation&.publication&.title, citation.title].join(" - ")
    else
      url&.truncate(50) || ""
    end
  end

  def citation_ref_html
    return "" unless citation.present? || url.present?
    if citation.present?
      "<span title=\"#{url}\"><span class=\"less-strong\">#{citation.publication.title}:</span> #{citation.title}</span>"
    else
      "<small title=\"#{url}\">#{url&.truncate(50)}</small>" || ""
    end
  end

  def set_calculated_attributes
    self.url = UrlCleaner.with_http(UrlCleaner.without_utm(url))
    self.creator_id ||= argument.creator_id
    self.citation_id = Citation.find_or_create_by_params({url: url, creator_id: creator_id})&.id
    # make sure ref_number is set, or things break
    self.ref_number ||= (argument&.argument_quotes&.maximum(:ref_number) || 0) + 1
  end
end
