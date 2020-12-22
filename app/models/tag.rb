class Tag < ApplicationRecord
  include TitleSluggable
  include ApprovedAtable

  TAXONOMY_ENUM = {
    domain_rank: 0,
    family_rank: 5,
    niche_rank: 10
  }.freeze

  has_many :hypothesis_tags, dependent: :destroy
  has_many :hypotheses, through: :hypothesis_tags

  enum taxonomy: TAXONOMY_ENUM

  scope :alphabetical, -> { reorder("lower(title)") }

  def self.matching_tags(string_or_array)
    Tag.where(id: matching_tag_ids(string_or_array))
  end

  def self.matching_tag_ids(string_or_array)
    return none unless string_or_array.present?
    array = string_or_array.is_a?(Array) ? string_or_array : string_or_array.split(/,|\n/)
    array.map { |s| friendly_find_id(s) }.compact
  end

  def self.matching_tag_ids_and_non_tags(string_or_array)
    return none unless string_or_array.present?
    array = string_or_array.is_a?(Array) ? string_or_array : string_or_array.split(/,|\n/)
    tag_ids = []
    non_tags = []
    array.each do |s|
      next unless s.present?
      t = friendly_find_id(s)
      t.present? ? (tag_ids << t) : (non_tags << s.strip)
    end
    {tag_ids: tag_ids, non_tags: non_tags}
  end

  def self.find_or_create_for_title(str)
    return nil unless str.present?
    friendly_find(str) || create(title: str.strip)
  end

  def self.serialized_attrs
    %i[title id taxonomy].freeze
  end
end
