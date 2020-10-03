class HypothesisSerializer < ApplicationSerializer
  attributes :title, :id, :direct_quotation, :citation_urls, :topics

  def direct_quotation
    object.has_direct_quotation
  end

  def topics
    object.tag_titles
  end
end
