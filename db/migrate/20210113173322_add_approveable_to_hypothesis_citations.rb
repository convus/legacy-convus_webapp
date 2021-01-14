class AddApproveableToHypothesisCitations < ActiveRecord::Migration[6.0]
  def change
    add_column :hypothesis_citations, :pull_request_number, :integer
    add_column :hypothesis_citations, :approved_at, :datetime
    add_column :hypothesis_citations, :submitting_to_github, :boolean, default: false
    add_reference :hypothesis_citations, :creator, index: true
  end
end
