class CreateCitations < ActiveRecord::Migration[6.0]
  def change
    create_table :citations do |t|
      t.references :publisher
      t.text :title
      t.text :slug
      t.text :authors
      t.integer :kind

      t.text :url
      t.datetime :published_at

      t.references :creator

      t.timestamps
    end
  end
end
