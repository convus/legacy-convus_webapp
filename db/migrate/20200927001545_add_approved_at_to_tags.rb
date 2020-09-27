class AddApprovedAtToTags < ActiveRecord::Migration[6.0]
  def change
    add_column :tags, :approved_at, :datetime
  end
end
