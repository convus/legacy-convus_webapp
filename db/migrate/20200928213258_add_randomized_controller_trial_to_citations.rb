class AddRandomizedControllerTrialToCitations < ActiveRecord::Migration[6.0]
  def change
    add_column :citations, :randomized_controlled_trial, :boolean, default: false
    add_column :citations, :peer_reviewed, :boolean, default: false
  end
end
