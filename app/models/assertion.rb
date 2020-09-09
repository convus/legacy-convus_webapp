class Assertion < ApplicationRecord
  include Sluggable

  belongs_to :creator, class_name: "User"

  has_many :assertion_citations
  has_many :citations, through: :assertion_citations

  validates_presence_of :creator_id
end
