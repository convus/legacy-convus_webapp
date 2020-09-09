class CreateCitations < ActiveRecord::Migration[6.0]
  def change
    create_table :citations do |t|
      t.references :publication
      t.text :title
      t.text :slug
      t.json :authors
      t.datetime :published_at

      t.integer :kind, default: 0

      t.text :url
      t.text :archive_link

      t.references :creator

      t.timestamps
    end
  end
end
