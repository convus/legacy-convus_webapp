class CreateRefutations < ActiveRecord::Migration[6.0]
  def change
    create_table :refutations do |t|
      t.references :refuted_hypothesis, index: true
      t.references :refuter_hypothesis, index: true

      t.timestamps
    end
    add_column :hypotheses, :refuted_at, :datetime
    remove_column :hypotheses, :has_direct_quotation, :boolean # Doesn't really fit in this migration but whatever
  end
end
