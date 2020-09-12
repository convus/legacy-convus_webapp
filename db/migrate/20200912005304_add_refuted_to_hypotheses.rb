class AddRefutedToHypotheses < ActiveRecord::Migration[6.0]
  def change
    add_column :hypotheses, :refuted, :boolean, default: false
  end
end
