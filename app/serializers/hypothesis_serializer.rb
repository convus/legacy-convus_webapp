class HypothesisSerializer < ApplicationSerializer
  attributes :title, :slug, :id, :direct_quotation, :created_timestamp, :tag_titles, :citation_links

  def created_timestamp
    object.created_at.utc.rfc3339
  end

  def direct_quotation
    object.has_direct_quotation
  end

  def tag_titles
    object.tags.pluck(:title)
  end

  def citation_links
    object.citations.pluck(:slug).map { |u| "#{BASE_URL}/citations/#{u}" }
  end
end
