class UpdateMetaPublicationJob < ApplicationJob
  def perform(id)
    publication = Publication.find(id)
  end
end
