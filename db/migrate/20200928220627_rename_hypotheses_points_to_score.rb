class RenameHypothesesPointsToScore < ActiveRecord::Migration[6.0]
  def change
    rename_column :hypotheses, :points, :score
  end
end
