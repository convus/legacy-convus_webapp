class RemoveHasDirectQuotationFromHypothesisCitations < ActiveRecord::Migration[6.0]
  def change
    remove_column :hypothesis_citations, :has_direct_quotation, :boolean
  end
end
