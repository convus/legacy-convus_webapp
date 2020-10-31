class CitationSerializer < ApplicationSerializer
  attributes :title,
    :id,
    :peer_reviewed,
    :randomized_controlled_trial,
    :url_is_not_publisher,
    :url_is_direct_link_to_full_text,
    :url,
    :publication_title,
    :published_date,
    :authors,
    :quotes

  def published_date
    object.published_date_str
  end

  def quotes
    object.quotes.map(&:text)
  end
end
