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

  before_validation :set_calculated_attributes

  def direct_quotation?
    has_direct_quotation || hypothesis_citations.direct_quotation.any?
  end

  def set_calculated_attributes
    if family_tag.present? && family_tag.slug != "family-uncategorized"
      hypothesis_tags.build(tag_id: family_tag_id) unless tags.map(&:title).include?(family_tag.title)
    end
  end
end
