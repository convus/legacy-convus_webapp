class HypothesisMarkdownSerializer
  def initialize(hypothesis:, explanations: nil)
    @hypothesis = hypothesis
    @explanations ||= get_explanations
  end

  def attributes
    %i[title id cited_urls new_cited_url topics explanations]
  end

  def id
    @hypothesis.ref_id
  end

  def topics
    @hypothesis.tag_titles
  end

  # Commented out in PR#146
  def cited_urls
    # hypothesis_citations.map(&:flat_file_serialized)
  end

  # Commented out in PR#146
  def new_cited_url
    # @hypothesis.included_unapproved_hypothesis_citation&.flat_file_serialized
  end

  # Commented out in PR#146
  def hypothesis_citations
    # if @hypothesis.approved?
    #   @hypothesis.hypothesis_citations.approved
    # else
    #   @hypothesis.hypothesis_citations
    # end
  end

  # If the hypothesis is approved, only include the approved explanations
  def explanations
    explanations_included = if @hypothesis.approved?
      @hypothesis.explanations.approved
    else
      @hypothesis.explanations
    end
    (explanations_included + [@hypothesis.additional_serialized_explanation]).reject(&:blank?)
      .map { |a| [a.ref_number, a.flat_file_serialized] }.to_h
  end
end
