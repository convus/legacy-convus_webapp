class CreateAssertionCitations < ActiveRecord::Migration[6.0]
  def change
    create_table :assertion_citations do |t|
      t.references :assertion
      t.references :citation
      t.boolean :direct_quotation, default: false

      t.timestamps
    end
  end
end
