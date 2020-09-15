class CitationSerializer < ApplicationSerializer
  attributes :title, :slug, :id, :url, :kind, :publication_slug, :published_date, :authors

  def publication_slug
    object.publication&.slug
  end

  def published_date
    object.published_date_str
  end
end
