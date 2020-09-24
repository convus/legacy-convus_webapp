class Tag < ApplicationRecord
  include TitleSluggable

  TAXONOMY_ENUM = {
    domain_rank: 0,
    family_rank: 5,
    niche_rank: 10
  }.freeze

  has_many :hypothesis_tags, dependent: :destroy
  has_many :hypotheses, through: :hypothesis_tags

  enum taxonomy: TAXONOMY_ENUM

  scope :alphabetical, -> { reorder("lower(title)") }

  def self.find_or_create_for_title(str)
    return nil unless str.present?
    friendly_find(str) || create(title: str.strip)
  end

  def self.serialized_attrs
    %i[title id taxonomy].freeze
  end
end
