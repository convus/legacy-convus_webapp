class RemoveRefutations < ActiveRecord::Migration[6.1]
  def change
    drop_table :refutations
    remove_column :hypotheses, :refuted_at, :datetime
  end
end
