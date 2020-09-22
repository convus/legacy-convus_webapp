class AddPathSlugToCitations < ActiveRecord::Migration[6.0]
  def change
    add_column :citations, :path_slug, :text
  end
end
