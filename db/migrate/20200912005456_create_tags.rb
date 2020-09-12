class CreateTags < ActiveRecord::Migration[6.0]
  def change
    create_table :tags do |t|
      t.text :title
      t.text :slug
      t.integer :taxonomy

      t.timestamps
    end
  end
end
