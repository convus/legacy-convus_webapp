class AddRemovedPullRequestNumber < ActiveRecord::Migration[6.1]
  def change
    add_column :arguments, :removed_pull_request_number, :integer
    add_column :citations, :removed_pull_request_number, :integer
    add_column :hypotheses, :removed_pull_request_number, :integer
    add_column :hypothesis_citations, :removed_pull_request_number, :integer
  end
end
