class AssertionCitation < ApplicationRecord
  belongs_to :assertion
  belongs_to :citation

  scope :direct_quotation, -> { where(has_direct_quotation: true) }

  def direct_quotation?
    has_direct_quotation
  end
end
