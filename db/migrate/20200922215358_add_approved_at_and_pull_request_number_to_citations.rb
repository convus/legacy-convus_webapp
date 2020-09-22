class AddApprovedAtAndPullRequestNumberToCitations < ActiveRecord::Migration[6.0]
  def change
    add_column :citations, :approved_at, :datetime
    add_column :citations, :pull_request_number, :integer
  end
end
