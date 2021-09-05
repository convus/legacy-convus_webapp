class RemoveHypothesisCitations < ActiveRecord::Migration[6.1]
  def change
    drop_table :quotes
    drop_table :hypothesis_quotes
    drop_table :hypothesis_citations
    add_reference :explanation_quotes, :hypothesis, index: true
    remove_column :explanations, :score, :integer
    remove_column :citations, :score, :integer
    remove_column :hypotheses, :score, :integer
  end
end
