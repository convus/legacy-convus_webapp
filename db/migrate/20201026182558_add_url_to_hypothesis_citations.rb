class AddUrlToHypothesisCitations < ActiveRecord::Migration[6.0]
  def change
    add_column :hypothesis_citations, :url, :text
  end
end
