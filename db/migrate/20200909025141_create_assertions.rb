class CreateAssertions < ActiveRecord::Migration[6.0]
  def change
    create_table :assertions do |t|
      t.text :body
      t.text :slug
      t.json :previous_slugs
      t.references :creator

      t.timestamps
    end
  end
end
