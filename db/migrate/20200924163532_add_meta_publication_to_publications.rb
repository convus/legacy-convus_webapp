class AddMetaPublicationToPublications < ActiveRecord::Migration[6.0]
  def change
    add_column :publications, :meta_publication, :boolean, default: false
    add_column :citations, :url_is_not_publisher, :boolean, default: :false
  end
end
