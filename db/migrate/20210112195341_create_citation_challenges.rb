class CreateCitationChallenges < ActiveRecord::Migration[6.0]
  def change
    create_table :citation_challenges do |t|
      t.references :creator, index: true
      t.references :hypothesis_citation, index: true
      t.references :supporting_citation, index: true
      t.integer :kind
      t.string :reason

      t.datetime :approved_at

      t.boolean :submitting_to_github, default: false
      t.integer :pull_request_number

      t.timestamps
    end
  end
end
