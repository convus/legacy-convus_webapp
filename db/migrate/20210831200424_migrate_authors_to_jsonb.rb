class MigrateAuthorsToJsonb < ActiveRecord::Migration[6.1]
  def change
    rename_column :citations, :authors, :authors_old
    add_column :citations, :authors, :jsonb
  end
end
