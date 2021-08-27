class AddDoiToCitations < ActiveRecord::Migration[6.1]
  def change
    add_column :citations, :doi, :text
  end
end
