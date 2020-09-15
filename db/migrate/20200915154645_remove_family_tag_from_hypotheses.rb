class RemoveFamilyTagFromHypotheses < ActiveRecord::Migration[6.0]
  def change
    remove_column :hypotheses, :family_tag_id, :integer
  end
end
