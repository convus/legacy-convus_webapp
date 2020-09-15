class HypothesisTag < ApplicationRecord
  belongs_to :hypothesis
  belongs_to :tag
  validates :tag_id, presence: true, uniqueness: {scope: [:hypothesis_id]}
end
