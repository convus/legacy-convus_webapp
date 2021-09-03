class ExplanationSerializer < ApplicationSerializer
  attributes :id,
    :text,
    :quote_urls

  def id
    object.ref_number
  end

  def quote_urls
    object.explanation_quotes.not_removed.order(:ref_number).map(&:url)
  end
end
