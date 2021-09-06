class CreateHypothesisRelationships < ActiveRecord::Migration[6.1]
  def change
    create_table :hypothesis_relationships do |t|

      t.timestamps
    end
  end
end
