class CreateHypothesisQuotes < ActiveRecord::Migration[6.0]
  def change
    create_table :hypothesis_quotes do |t|
      t.references :hypothesis
      t.references :quote
      t.integer :importance
      t.integer :score

      t.timestamps
    end
  end
end
