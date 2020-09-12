class Tag < ApplicationRecord
  include TitleSluggable

  TAXONOMY_ENUM = {
    domain_rank: 0,
    family_rank: 5
  }

  has_many :hypothesis_tags
  has_many :hypotheses, through: :hypothesis_tags

  enum taxonomy: TAXONOMY_ENUM

  def self.family_uncategorized
    friendly_find("family-uncategorized") ||
      create(title: "Family uncategorized", taxonomy: "family_rank")
  end
end
