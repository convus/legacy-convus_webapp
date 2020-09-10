class AssertionCitation < ApplicationRecord
  belongs_to :assertion
  belongs_to :citation

  before_create :set_calculated_attributes

  scope :direct_quotation, -> { where(has_direct_quotation: true) }

  def direct_quotation?
    has_direct_quotation
  end

  def set_calculated_attributes
    self.has_direct_quotation = assertion&.direct_quotation?
  end
end
