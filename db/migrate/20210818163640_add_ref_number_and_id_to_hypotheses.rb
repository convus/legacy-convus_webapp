class AddRefNumberAndIdToHypotheses < ActiveRecord::Migration[6.1]
  def change
    add_column :hypotheses, :ref_number, :bigint
    add_column :hypotheses, :ref_id, :string
    add_index :hypotheses, :ref_id, unique: true
  end
end
