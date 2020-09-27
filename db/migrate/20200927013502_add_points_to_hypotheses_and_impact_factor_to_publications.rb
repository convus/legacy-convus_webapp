class AddPointsToHypothesesAndImpactFactorToPublications < ActiveRecord::Migration[6.0]
  def change
    add_column :hypotheses, :points, :integer
    add_column :publications, :impact_factor, :float
  end
end
