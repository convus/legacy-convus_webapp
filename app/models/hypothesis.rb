class Hypothesis < ApplicationRecord
  include TitleSluggable

  belongs_to :creator, class_name: "User"

  has_many :hypothesis_citations
  has_many :citations, through: :hypothesis_citations

  validates_presence_of :creator_id

  accepts_nested_attributes_for :citations

  scope :direct_quotation, -> { where(has_direct_quotation: true) }

  def direct_quotation?
    has_direct_quotation || hypothesis_citations.direct_quotation.any?
  end
end
