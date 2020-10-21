class HypothesisQuote < ApplicationRecord
  belongs_to :hypothesis
  belongs_to :quote

  validates_presence_of :quote_id, :hypothesis_id
end
