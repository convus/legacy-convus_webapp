class CreateAssertions < ActiveRecord::Migration[6.0]
  def change
    create_table :assertions do |t|
      t.text :title
      t.text :slug
      t.references :creator

      t.timestamps
    end
  end
end
