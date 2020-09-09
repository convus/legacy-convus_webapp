class Publication < ApplicationRecord
  scope :issued_retractions, -> { where(has_issued_retractions: true) }

  def issued_retractions?
    has_issued_retractions
  end
end
