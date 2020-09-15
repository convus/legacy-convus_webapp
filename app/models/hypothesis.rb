class Hypothesis < ApplicationRecord
  include TitleSluggable

  belongs_to :creator, class_name: "User"

  has_many :hypothesis_citations
  has_many :citations, through: :hypothesis_citations
  has_many :hypothesis_tags
  has_many :tags, through: :hypothesis_tags

  validates_presence_of :creator_id

  accepts_nested_attributes_for :citations

  scope :direct_quotation, -> { where(has_direct_quotation: true) }

  def direct_quotation?
    has_direct_quotation || hypothesis_citations.direct_quotation.any?
  end

  def tags_string
    tags.alphabetical.pluck(:title).join(", ")
  end

  def tags_string=(val)
    new_tags = (val.is_a?(Array) ? val : val.split(/,|\n/)).reject(&:blank?)
    new_ids = new_tags.map do |string|
      hypothesis_tags.build(tag_id: Tag.find_or_create_for_title(string)&.id)
    end
    hypothesis_tags.where.not(tag_id: new_ids).destroy_all
    tags
  end
end
