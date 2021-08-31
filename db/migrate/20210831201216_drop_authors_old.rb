class DropAuthorsOld < ActiveRecord::Migration[6.1]
  def change
    remove_column :citations, :authors_old, :json
  end
end
