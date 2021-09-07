class AddTextNodesToExplanations < ActiveRecord::Migration[6.1]
  def change
    add_column :explanations, :text_nodes, :jsonb
  end
end
