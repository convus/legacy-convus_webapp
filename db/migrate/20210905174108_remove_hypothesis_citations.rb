class RemoveHypothesisCitations < ActiveRecord::Migration[6.1]
  def change
    drop_table :quotes
    drop_table :hypothesis_quotes
    drop_table :hypothesis_citations
    add_reference :explanation_quotes, :hypothesis, index: true
  end
end
