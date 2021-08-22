class CreateArgumentQuotes < ActiveRecord::Migration[6.1]
  def change
    create_table :argument_quotes do |t|
      t.references :argument, index: true
      t.references :citation, index: true
      t.references :creator, index: true

      t.integer :ref_number

      t.text :text
      t.text :url

      t.timestamps
    end
  end
end

