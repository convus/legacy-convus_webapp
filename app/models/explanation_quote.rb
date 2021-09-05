class ExplanationQuote < ApplicationRecord
  belongs_to :explanation
  belongs_to :citation
  belongs_to :hypothesis # Added to make joins to hypothesis easier
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
      "<span title=\"#{url}\"><span class=\"source-pub\">#{citation.publication.title}:</span> <span class=\"source-title\">#{citation.title}</span></span>"
    else
      "<small title=\"#{url}\">#{url&.truncate(50)}</small>" || ""
    end
  end

  def set_calculated_attributes
    self.creator_id ||= explanation.creator_id
    self.ref_number ||= calculated_ref_number
    self.hypothesis_id ||= explanation&.hypothesis_id
    self.url = UrlCleaner.with_http(UrlCleaner.without_utm(url))
    self.citation_id = Citation.find_or_create_by_params({url: url, creator_id: creator_id})&.id

  end

  private

  def calculated_ref_number
    arg_quotes = ExplanationQuote.where(explanation_id: explanation_id)
    arg_quotes = arg_quotes.where("id < ?", id) if id.present?
    self.ref_number = arg_quotes.count + 1
  end
end
