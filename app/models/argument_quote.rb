class ArgumentQuote < ApplicationRecord
  belongs_to :argument
  belongs_to :citation
  belongs_to :creator, class_name: "User"

  before_validation :set_calculated_attributes

  scope :ref_ordered, -> { reorder(:ref_number) }
  scope :removed, -> { where(removed: true) }
  scope :not_removed, -> { where(removed: false) }
  scope :no_url, -> { where(url: nil) } # UrlCleaner returns nil if empty

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
    self.ref_number ||= calculated_ref_number
  end

  private

  def calculated_ref_number
    arg_quotes = ArgumentQuote.where(argument_id: argument_id)
    arg_quotes = arg_quotes.where("id < ?", id) if id.present?
    self.ref_number = arg_quotes.count + 1
  end
end
