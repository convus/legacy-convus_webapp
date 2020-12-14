class CreatePreviousTitles < ActiveRecord::Migration[6.0]
  def change
    create_table :previous_titles do |t|
      t.references :hypothesis
      t.text :title
      t.text :slug

      t.timestamps
    end
  end
end
