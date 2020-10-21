class CreateHypothesisQuotes < ActiveRecord::Migration[6.0]
  def change
    create_table :hypothesis_quotes do |t|
      t.references :hypothesis_citation
      t.references :hypothesis
      t.references :quote
      t.references :citation
      t.integer :importance
      t.integer :score

      t.timestamps
    end

    # Also add this here, because it goes with hypothesis_quotes
    add_column :hypothesis_citations, :quotes_text, :text
  end
end
