class HypothesisSerializer < ApplicationSerializer
  attributes :title, :slug, :id, :direct_quotation, :created_timestamp, :tag_titles
  has_many :citations

  def created_timestamp
    object.created_at.utc.rfc3339
  end

  def direct_quotation
    object.has_direct_quotation
  end

  def tag_titles
    object.tags.pluck(:title)
  end
end
