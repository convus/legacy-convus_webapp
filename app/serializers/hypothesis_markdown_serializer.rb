class HypothesisMarkdownSerializer
  def initialize(hypothesis:, explanations: nil)
    @hypothesis = hypothesis
    @explanations = explanations || @hypothesis.explanations.approved
  end

  def serialized_attrs
    {
      title: @hypothesis.title,
      id: @hypothesis.ref_id,
      topics: @hypothesis.tag_titles,
      explanations: @explanations.map(&:flat_file_serialized)
      citations: citations
    }
  end

  def as_json
    serialized_attrs.as_json
  end

  def to_markdown
    # Make this happen...
  end

  def front_matter
    # Serialize to yaml - stringify keys so the keys don't start with :, to make things easier to read
  end

  def citations
    @explanations.map(&:citations).uniq.each do |citation|
      [citation.url, {title: citation.title, publication_title: citation.publication_title}]
    end.to_h
  end
end
