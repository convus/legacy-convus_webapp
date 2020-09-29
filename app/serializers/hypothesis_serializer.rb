class HypothesisSerializer < ApplicationSerializer
  attributes :title, :id, :direct_quotation, :citation_urls, :tag_titles

  def direct_quotation
    object.has_direct_quotation
  end
end
