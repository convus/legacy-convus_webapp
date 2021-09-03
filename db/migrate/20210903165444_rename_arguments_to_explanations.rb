class RenameArgumentsToExplanations < ActiveRecord::Migration[6.1]
  def change
    rename_table :arguments, :explanations
    rename_table :argument_quotes, :explanation_quotes
    rename_column :explanation_quotes, :argument_id, :explanation_id
    rename_column :user_scores, :argument_id, :explanation_id
  end
end
