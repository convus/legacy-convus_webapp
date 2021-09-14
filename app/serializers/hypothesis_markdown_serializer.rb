class HypothesisMarkdownSerializer
  def initialize(hypothesis:, explanations: nil)
    @hypothesis = hypothesis
    @explanations = (explanations || @hypothesis.explanations.approved)
      .sort_by { |e| e.ref_number }
  end

  attr_reader :explanations

  def serialized_attrs
    {
      id: @hypothesis.ref_id,
      hypothesis: @hypothesis.title,
      topics: @hypothesis.tag_titles,
      supporting: supporting_hypotheses_titles,
      conflicting: conflicting_hypotheses_titles,
      citations: citations_hash.present? ? citations_hash : nil
    }
  end

  def as_json
    serialized_attrs.as_json
  end

  def to_markdown
    "#{front_matter}---\n#{explanations_markdown}"
  end

  def front_matter
    # Serialize to yaml - stringify keys so the keys don't start with :, to make things easier to read
    serialized_attrs.except(:explanations).deep_stringify_keys.to_yaml(FlatFileSerializer.yaml_opts)
  end

  def explanations_markdown
    @explanations.map do |explanation|
      "## Explanation #{explanation.ref_number}\n\n#{explanation.text_with_references}"
    end.join("\n\n")
  end

  def hypothesis_relations
    @hypothesis.approved? ? @hypothesis.relations.approved : @hypothesis.relations
  end

  def related_hypotheses(scope)
    hypothesis_relations.send(scope).hypotheses(@hypothesis.id).approved
  end

  def supporting_hypotheses_titles
    related_hypotheses(:supporting).map(&:title_with_ref_id)
  end

  def conflicting_hypotheses_titles
    related_hypotheses(:conflicting).map(&:title_with_ref_id)
  end

  def citations_hash
    @explanations.map(&:citations).flatten.uniq.reject(&:blank?).sort_by { |c| c.url }
      .map do |citation|
        [citation.url,
          {title: citation.title,
           published_date: citation.published_date_str,
           publication_title: citation.publication_title}]
      end.compact.to_h
  end
end
