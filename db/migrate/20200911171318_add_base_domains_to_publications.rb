class AddBaseDomainsToPublications < ActiveRecord::Migration[6.0]
  def change
    add_column :publications, :base_domains, :jsonb
  end
end
