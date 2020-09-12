class CreateHypothesisTags < ActiveRecord::Migration[6.0]
  def change
    create_table :hypothesis_tags do |t|
      t.references :hypothesis
      t.references :tag

      t.timestamps
    end

    add_reference :hypotheses, :family_tag
  end
end
