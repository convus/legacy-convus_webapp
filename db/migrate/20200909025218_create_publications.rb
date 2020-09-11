class CreatePublications < ActiveRecord::Migration[6.0]
  def change
    create_table :publications do |t|
      t.text :title
      t.text :slug
      t.boolean :has_published_retractions, default: false
      t.boolean :has_peer_reviewed_articles, default: false
      t.text :home_url

      t.timestamps
    end
  end
end
