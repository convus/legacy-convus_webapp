class AddApprovedAtAndPullRequestNumberToHypotheses < ActiveRecord::Migration[6.0]
  def change
    remove_column :hypotheses, :refuted, :boolean # It isn't used yet, and adds clutter
    add_column :hypotheses, :approved_at, :datetime
    add_column :hypotheses, :pull_request_id, :integer
  end
end
