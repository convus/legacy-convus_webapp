class Hypothesis < ApplicationRecord
  include TitleSluggable

  belongs_to :creator, class_name: "User"
  belongs_to :family_tag, class_name: "Tag"

  has_many :hypothesis_citations
  has_many :citations, through: :hypothesis_citations
  has_many :hypothesis_tags
  has_many :tags, through: :hypothesis_tags

  validates_presence_of :creator_id, :family_tag

  accepts_nested_attributes_for :citations

  scope :direct_quotation, -> { where(has_direct_quotation: true) }

  def direct_quotation?
    has_direct_quotation || hypothesis_citations.direct_quotation.any?
  end


end
