# NOTE: some of this is duplicated in the spec in the convus_content repo
# Anything changed here should also be changed there

class HypothesisMarkdownParser
  # Duplicated in the content repo
  def initialize(file_content:)
    @file_content = file_content
  end

  attr_reader :file_content, :hypothesis

  def import
    @hypothesis = matching_hypothesis
    @hypothesis.approved_at ||= Time.current # If it's in the flat files, it's approved
    @hypothesis.update(title: front_matter[:hypothesis])
    explanations.each do |ref_number, text|
      explanation = @hypothesis.explanations.find_by_ref_number(ref_number)
      explanation ||= @hypothesis.explanations.build(ref_number: ref_number)
      explanation.approved_at ||= Time.current
      explanation.update_from_text(text)
    end
    @hypothesis.update(tags_string: front_matter[:topics])
    # TODO: should only be the ones that were passed in here :(
    @hypothesis.tags.unapproved.update_all(approved_at: Time.current)

    # Because explanations were added, reload
    @hypothesis.reload
    (front_matter[:citations] || []).each { |url, c_attrs| import_citation(url, c_attrs) }
    @hypothesis
  end

  def matching_hypothesis
    Hypothesis.find_ref_id(front_matter[:id]) ||
      Hypothesis.friendly_find(front_matter[:hypothesis]) ||
      Hypothesis.new(ref_id: front_matter[:id], ref_number: front_matter[:id].to_i(36))
  end

  # Duplicated in the content repo
  def split_content
    return @split_content if defined?(@split_content)
    content = @file_content.split(/^---\s*\n/)
    front = content.shift
    front = content.shift if front.blank? # First block will be blank if formatted correctly
    @split_content = [front, content.join("\n---\n")] # add back in horizontal lines, if they were in there
  end

  # Duplicated in the content repo
  def front_matter
    @front_matter ||= YAML.load(split_content.first).with_indifferent_access
  end

  # Duplicated in the content repo
  def explanations
    return @explanations if defined?(@explanations)
    argument_numbers = []
    @explanations = split_content.last.split(/^\s*#+ explanation /i).reject(&:blank?)
      .each_with_index.map do |exp, index|
        num = exp[/\A\s*\d+/]
        num = if num.blank?
          index + 1
        else
          exp.gsub!(/\A\s*\d+/, "")
          num.to_i
        end
        num = argument_numbers.max + 1 if argument_numbers.include?(num)
        argument_numbers << num
        [num.to_s, exp.strip]
      end.to_h
  end

  def import_citation(url, citation_attrs)
    citation = @hypothesis&.citations&.friendly_find_slug(url)
    # Can't update citations for other records here
    return unless citation.present?
    citation.approved_at ||= Time.current
    # Rename this attr
    citation_attrs[:published_date_str] = citation_attrs.delete(:published_date)
    # Friendly search kind, skip if it isn't valid
    if citation_attrs[:kind].present?
      citation_attrs[:kind] = Citation.friendly_find_kind(citation_attrs[:kind])
    end
    citation.update(citation_attrs.slice(*Citation.permitted_attrs))
  end
end
