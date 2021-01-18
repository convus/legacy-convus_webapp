class HypothesisSerializer < ApplicationSerializer
  attributes :title, :id, :cited_urls, :new_cited_url, :refuted_by_hypotheses, :topics

  def topics
    object.tag_titles
  end

  def refuted_by_hypotheses
    object.refuted_by_hypotheses.map(&:title)
  end

  def cited_urls
    hypothesis_citations.map(&:flat_file_serialized)
  end

  def new_cited_url
    object.included_unapproved_hypothesis_citation&.flat_file_serialized
  end

  # If the hypothesis is approved, only include the approved hypothesis_citations
  def hypothesis_citations
    if object.approved?
      object.hypothesis_citations.approved
    else
      object.hypothesis_citations
    end
  end
end
