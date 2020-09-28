class HypothesisCitation < ApplicationRecord
  belongs_to :hypothesis
  belongs_to :citation

  validates :citation_id, presence: true, uniqueness: {scope: [:hypothesis_id]}
end
