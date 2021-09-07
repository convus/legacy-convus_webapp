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
end
