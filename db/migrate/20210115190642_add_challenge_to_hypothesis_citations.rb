class AddChallengeToHypothesisCitations < ActiveRecord::Migration[6.0]
  def change
    add_column :hypothesis_citations, :kind, :integer
    add_reference :hypothesis_citations, :challenged_hypothesis_citation, index: true
  end
end
