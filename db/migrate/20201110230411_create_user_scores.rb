class CreateUserScores < ActiveRecord::Migration[6.0]
  def change
    create_table :user_scores do |t|
      t.references :user, index: true
      t.references :hypothesis, index: true
      t.integer :score
      t.integer :kind
      t.boolean :expired, default: false


      t.timestamps
    end
  end
end
