class HypothesisCitation < ApplicationRecord
  belongs_to :hypothesis
  belongs_to :citation

  before_create :set_calculated_attributes

  validates :citation_id, presence: true, uniqueness: {scope: [:hypothesis_id]}

  scope :direct_quotation, -> { where(has_direct_quotation: true) }

  def direct_quotation?
    has_direct_quotation
  end

  def set_calculated_attributes
    self.has_direct_quotation = hypothesis&.direct_quotation?
  end
end
