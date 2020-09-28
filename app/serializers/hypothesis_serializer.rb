class HypothesisSerializer < ApplicationSerializer
  attributes :title, :id, :direct_quotation, :tag_titles, :citation_urls

  def direct_quotation
    object.has_direct_quotation
  end
end
