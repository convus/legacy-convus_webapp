class CreateAssertions < ActiveRecord::Migration[6.0]
  def change
    create_table :assertions do |t|
      t.text :title
      t.text :slug
      t.references :creator
      t.boolean :has_direct_quotation, default: false

      t.timestamps
    end
  end
end
