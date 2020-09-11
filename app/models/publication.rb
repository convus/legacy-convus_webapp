class Publication < ApplicationRecord
  include Sluggable

  scope :published_retractions, -> { where(has_published_retractions: true) }

  def published_retractions?
    has_published_retractions
  end
end
