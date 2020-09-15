class PublicationSerializer < ApplicationSerializer
  attributes :title, :slug, :id, :has_published_retractions, :has_peer_reviewed_articles, :url

  def url
    object.home_url
  end
end
