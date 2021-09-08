class HypothesisMarkdownParser
  def initialize(file_content:)
    @file_content = file_content
  end

  attr_reader :file_content


  def front_matter
    matter = @file_content.split("\n---\s*\n")

    f_matter = matter.first.present? ? matter.first : matter.second
    YAML.load(f_matter)
  end

  # import_hypothesis(File.load_file(file).with_indifferent_access)

  # hypothesis = Hypothesis.find_ref_id(hypothesis_attrs[:id]) ||
  #       Hypothesis.new(ref_id: hypothesis_attrs[:id], ref_number: hypothesis_attrs[:id].to_i(36))
  #     hypothesis.approved_at ||= Time.current # If it's in the flat files, it's approved
  #     hypothesis.update(title: hypothesis_attrs[:title])

  #     # Handle transition, where not everything has an explanation key
  #     (hypothesis_attrs[:explanations] || {}).values.each do |explanation_attrs|
  #       explanation = hypothesis.explanations.find_by(ref_number: explanation_attrs[:id]) || hypothesis.explanations.build
  #       explanation.approved_at ||= Time.current
  #       explanation.update_from_text(explanation_attrs[:text])
  #     end

  #     hypothesis.update(tags_string: hypothesis_attrs[:topics])
  #     hypothesis.tags.unapproved.update_all(approved_at: Time.current)

  #     # Commented out in PR#146
  #     # hypothesis_citation_ids = []
  #     # hypothesis_citations = hypothesis_attrs[:cited_urls] || []
  #     # # If there is a "new_cited_url", process that too
  #     # hypothesis_citations += [hypothesis_attrs[:new_cited_url]] if hypothesis_attrs[:new_cited_url].present?
  #     # hypothesis_citations.map do |hc_attrs|
  #     #   hypothesis_citation = create_hypothesis_citation(hypothesis, hc_attrs)
  #     #   hypothesis_citation_ids << hypothesis_citation.id
  #     # end
  #     # hypothesis.reload
  #     # # If we have new_cited_urls, we're ignoring the old cited_urls to avoid merge conflict issues
  #     # unless hypothesis_attrs.key?(:new_cited_urls)
  #     #   hypothesis.hypothesis_citations.where.not(id: hypothesis_citation_ids).destroy_all
  #     # end
  #     hypothesis
end
