class CitationScorer
  BADGES = {
    hypothesis: {
      has_quote: 1,
      has_at_least_two_topics: 1
    },

    citation: {
      has_author: 1,
      has_publication_date: 1,
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

  def self.total_potential_score
    # Only possible to get one of the publication values. Definitely a better way to manage this in the future
    skipped = %i[peer_reviewed_medium_impact_factor peer_reviewed_low_impact_factor non_peer_reviewed_with_retractions]
    BADGES.values.reduce({}, :merge).map { |badge, value|
      skipped.include?(badge) ? 0 : value
    }.sum
  end

  def self.hypothesis_badges(hypothesis, citation = nil)
    badges = {}
    return badges unless hypothesis.present?
    hy_badges = BADGES[:hypothesis]
    badges.merge!(hy_badges.slice(:has_quote)) if hypothesis.quotes.count > 0
    badges.merge!(hy_badges.slice(:has_at_least_two_topics)) if hypothesis.tags.count > 1
    citation ||= hypothesis.citation_for_score
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
    badges.merge!(cite_badges.slice(:has_author)) if citation.authors.present?
    badges.merge!(cite_badges.slice(:has_publication_date)) if citation.published_at.present?
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

  # May do more later
  def self.badge_humanized(badge)
    badge.to_s.tr("_", " ")
  end
end
