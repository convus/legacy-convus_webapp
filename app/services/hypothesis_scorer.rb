class HypothesisScorer
  BADGES = {
    hypothesis: {},

    citation: {},

    publication: {
      peer_reviewed_high_impact_factor: 10,
      peer_reviewed_medium_impact_factor: 6,
      peer_reviewed_low_impact_factor: 3,
      non_peer_reviewed_with_retractions: 1
    }
  }

  def self.publication_badges(publication)
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
