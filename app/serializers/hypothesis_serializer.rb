class HypothesisSerializer < ApplicationSerializer
  attributes :title, :id, :direct_quotation, :created_timestamp, :tag_titles, :citation_urls

  def created_timestamp
    (object.created_at || Time.current).utc.rfc3339
  end

  def direct_quotation
    object.has_direct_quotation
  end

  def tag_titles
    object.tags.pluck(:title)
  end
end
