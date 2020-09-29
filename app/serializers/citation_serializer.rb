class CitationSerializer < ApplicationSerializer
  attributes :title,
    :id,
    :peer_reviewed,
    :randomized_controlled_trial,
    :url_is_direct_link_to_full_text,
    :url,
    :url_is_not_publisher,
    :publication_title,
    :published_date,
    :authors

  def published_date
    object.published_date_str
  end
end
