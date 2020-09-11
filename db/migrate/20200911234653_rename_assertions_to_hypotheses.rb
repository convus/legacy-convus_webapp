class RenameAssertionsToHypotheses < ActiveRecord::Migration[6.0]
  def change
    rename_table :assertions, :hypotheses
    rename_table :assertion_citations, :hypothesis_citations
    rename_column :hypothesis_citations, :assertion_id, :hypothesis_id
  end
end
