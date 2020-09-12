class Tag < ApplicationRecord
  include TitleSluggable

  TAXONOMY_ENUM = {
    domain_rank: 0,
    family_rank: 5
  }

  has_many :hypothesis_tags
  has_many :hypotheses, through: :hypothesis_tags

  enum taxonomy: TAXONOMY_ENUM

  def self.uncategorized
    friendly_find("uncategorized") ||
      create(title: "uncategorized", taxonomy: "family_rank")
  end
end
