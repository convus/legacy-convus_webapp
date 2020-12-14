class HypothesisSerializer < ApplicationSerializer
  attributes :title, :id, :cited_urls, :refuted_by_hypotheses, :topics

  def topics
    object.tag_titles
  end

  def refuted_by_hypotheses
    object.refuted_by_hypotheses.map(&:title)
  end

  def cited_urls
    object.hypothesis_citations.map do |hypothesis_citation|
      {
        url: hypothesis_citation.citation.url,
        quotes: hypothesis_citation.hypothesis_quotes.map(&:quote_text)
      }
    end
  end
end
