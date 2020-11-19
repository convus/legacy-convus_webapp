class UpdateCitationQuotesJob < ApplicationJob
  def perform(citation_id)
    # If citation is deleted, remove the dangles
    return remove_associations(citation_id) unless Citation.find_by_id(citation_id)
    # Remove quotes that have been orphaned
    hypothesis_quote_ids = []
    Quote.where(citation_id: citation_id).each do |quote|
      ids = quote.hypothesis_quotes.pluck(:id)
      if ids.any?
        hypothesis_quote_ids += ids
      else
        quote.destroy
      end
    end
    # Update hypothesis quotes
    HypothesisQuote.where(id: hypothesis_quote_ids).each do |hypothesis_quote|
      hypothesis_quote.set_calculated_attributes
      hypothesis_quote.save if hypothesis_quote.changed?
    end
  end

  def remove_associations(citation_id)
    quote_ids = Quote.where(citation_id: citation_id).pluck(:id)
    Quote.where(citation_id: citation_id).delete_all
    HypothesisQuote.where(quote_id: quote_ids).delete_all
  end
end
