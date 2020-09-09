class CreatePublications < ActiveRecord::Migration[6.0]
  def change
    create_table :publications do |t|
      t.text :title
      t.text :slug
      t.boolean :has_issued_retractions, default: false
      t.text :home_url

      t.timestamps
    end
  end
end
