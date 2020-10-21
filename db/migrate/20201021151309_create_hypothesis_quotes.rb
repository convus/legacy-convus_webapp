class CreateHypothesisQuotes < ActiveRecord::Migration[6.0]
  def change
    create_table :hypothesis_quotes do |t|
      t.references :hypothesis
      t.references :quote

      t.timestamps
    end
  end
end
