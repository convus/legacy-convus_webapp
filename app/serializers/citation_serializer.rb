class CitationSerializer < ApplicationSerializer
  attributes :title, :id, :url, :kind, :publication_title, :published_date, :authors

  def published_date
    object.published_date_str
  end
end
