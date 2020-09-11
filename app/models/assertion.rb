class Assertion < ApplicationRecord
  include TitleSluggable

  belongs_to :creator, class_name: "User"

  has_many :assertion_citations
  has_many :citations, through: :assertion_citations

  validates_presence_of :creator_id

  accepts_nested_attributes_for :citations

  scope :direct_quotation, -> { where(has_direct_quotation: true) }

  def direct_quotation?
    has_direct_quotation || assertion_citations.direct_quotation.any?
  end
end
