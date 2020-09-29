class AddScoreToCitations < ActiveRecord::Migration[6.0]
  def change
    add_column :citations, :score, :integer
  end
end
