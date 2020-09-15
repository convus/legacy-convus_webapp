class HypothesisSerializer < ApplicationSerializer
  attributes :title, :slug, :id, :direct_quotation, :created_at, :tag_titles
  has_many :citations

  def created_timestamp
    object.created_at.to_datetime.rfc3339
  end

  def direct_quotation
    object.has_direct_quotation
  end

  def tag_titles
    object.tags.pluck(:title)
  end
end
