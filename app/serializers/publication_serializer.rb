class PublicationSerializer < ApplicationSerializer
  attributes :slug, :id, :title, :has_published_retractions, :has_peer_reviewed_articles, :url

  def url
    object.home_url
  end
end
