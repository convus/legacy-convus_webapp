class CreateContentCommits < ActiveRecord::Migration[6.0]
  def change
    create_table :content_commits do |t|
      t.string :sha
      t.json :github_data

      t.string :author
      t.datetime :committed_at

      t.timestamps
    end
  end
end
