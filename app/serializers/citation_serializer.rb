class CitationSerializer < ApplicationSerializer
  attributes :title, :id, :url, :kind, :publication_title, :published_date, :authors, :url_is_publisher

  def published_date
    object.published_date_str
  end

  def url_is_publisher
    object.url_is_publisher?
  end
end
