class CreateArguments < ActiveRecord::Migration[6.1]
  def change
    create_table :arguments do |t|
      t.references :hypothesis, index: true
      t.references :creator, index: true

      t.text :text
      t.text :body_html

      t.integer :score

      t.string :reference_id

      t.datetime :approved_at
      t.integer :pull_request_number
      t.boolean :submitting_to_github, default: false

      t.timestamps
    end

    add_reference :user_scores, :argument, index: true
  end
end
