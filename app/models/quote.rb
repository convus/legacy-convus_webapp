class Quote < ApplicationRecord
  belongs_to :citation
  validates_presence_of :citation_id
end
