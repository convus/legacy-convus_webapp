class CreateHypothesisChallenges < ActiveRecord::Migration[6.1]
  def change
    create_table :hypothesis_challenges do |t|
      t.references :creator, index: true
      t.references :hypothesis, index: true
      t.references :challenged_hypothesis, index: true
      t.references :challenged_citation, index: true
      t.references :challenged_explanation_quote, index: true

      t.integer :kind

      t.datetime :approved_at
      t.integer :pull_request_number
      t.integer :removed_pull_request_number
      t.boolean :submitting_to_github, default: false

      t.timestamps
    end
  end
end
