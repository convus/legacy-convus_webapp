class CreateCitations < ActiveRecord::Migration[6.0]
  def change
    create_table :citations do |t|
      t.references :publication
      t.text :title
      t.text :slug
      t.json :authors
      t.datetime :published_at

      t.integer :kind

      t.text :url
      t.boolean :url_is_direct_link_to_full_text, default: false
      t.text :wayback_machine_url

      t.references :creator

      t.timestamps
    end
  end
end
