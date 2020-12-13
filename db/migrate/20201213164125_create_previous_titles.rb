class CreatePreviousTitles < ActiveRecord::Migration[6.0]
  def change
    create_table :previous_titles do |t|
      t.references :hypothesis
      t.string :title
      t.string :slug

      t.timestamps
    end
  end
end
