class HypothesisScorer
  BADGES = {
    hypothesis: {
      direct_quotation: 1
    },

    citation: {
      open_access_research: 10,
      randomized_controlled_trial: 2
    },

    publication: {
      peer_reviewed_high_impact_factor: 10,
      peer_reviewed_medium_impact_factor: 6,
      peer_reviewed_low_impact_factor: 3,
      non_peer_reviewed_with_retractions: 1
    }
  }

  def self.hypothesis_badges(hypothesis)
    badges = hypothesis.direct_quotation? ? BADGES[:hypothesis].slice(:direct_quotation) : {}
    citation = hypothesis.citation_for_score
    badges.merge(citation_badges(citation))
      .merge(publication_badges(citation&.publication))
  end

  def self.citation_badges(citation)
    badges = {}
    return badges unless citation.present?
    cite_badges = BADGES[:citation]
    if citation.peer_reviewed && citation.url_is_direct_link_to_full_text
      badges.merge!(cite_badges.slice(:open_access_research))
    end
    if citation.randomized_controlled_trial
      badges.merge!(cite_badges.slice(:randomized_controlled_trial))
    end
    badges
  end

  def self.publication_badges(publication)
    return {} unless publication.present?
    pub_badges = BADGES[:publication]
    if publication.has_peer_reviewed_articles
      impact_factor = if publication.impact_factor.blank? || publication.impact_factor < 1.0
        "low"
      elsif publication.impact_factor < 4.0
        "medium"
      else
        "high"
      end
      pub_badges.slice("peer_reviewed_#{impact_factor}_impact_factor".to_sym)
    else
      return {} unless publication.has_published_retractions
      pub_badges.slice(:non_peer_reviewed_with_retractions)
    end
  end
end
