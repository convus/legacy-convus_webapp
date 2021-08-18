class AddReferenceIdToQuotes < ActiveRecord::Migration[6.1]
  def change
    add_column :hypotheses, :reference_id, :string
    add_column :quotes, :reference_id, :string
  end
end
