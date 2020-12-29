# Outputs a current version of the database

class FlatFileImporter
  FILES_PATH = FlatFileSerializer::FILES_PATH
  require "csv"

  class << self
    def import_all_files
      import_tags
      import_publications
      import_citations
      import_hypotheses
      UpdateHypothesisScoreJob.perform_async
    end

    def import_tags
      CSV.read(FlatFileSerializer.tags_file, headers: true, header_converters: :symbol).each do |row|
        tag = Tag.find_by_id(row[:id]) || Tag.friendly_find(row[:title]) || Tag.new
        tag.title = row[:title]
        tag.taxonomy = row[:taxonomy]
        tag.approved_at ||= Time.current
        tag.save if tag.changed? || tag.id.blank?
        tag.update_column :id, row[:id] unless tag.id == row[:id]
      end
    end

    def import_publications
      CSV.read(FlatFileSerializer.publications_file, headers: true, header_converters: :symbol).each do |row|
        publication = Publication.find_by_id(row[:id]) || Publication.new
        publication.attributes = {title: row[:title],
                                  has_published_retractions: row[:has_published_retractions],
                                  has_peer_reviewed_articles: row[:has_peer_reviewed_articles],
                                  home_url: row[:home_url],
                                  meta_publication: row[:meta_publication]}
        publication.save if publication.changed?
        publication.update_column :id, row[:id] unless publication.id == row[:id]
      end
    end

    def import_hypotheses
      Dir.glob("#{FILES_PATH}/hypotheses/*.yml").each do |file|
        import_hypothesis(YAML.load_file(file).with_indifferent_access)
      end
    end

    def import_hypothesis(hypothesis_attrs)
      hypothesis = Hypothesis.where(id: hypothesis_attrs[:id]).first || Hypothesis.new
      hypothesis.approved_at ||= Time.current # If it's in the flat files, it's approved
      hypothesis.update(title: hypothesis_attrs[:title])
      # We need to save first, so we can update the columns if necessary, before creating associations
      unless hypothesis.id == hypothesis_attrs[:id]
        hypothesis.update_columns(id: hypothesis_attrs[:id])
      end
      hypothesis.update(tags_string: hypothesis_attrs[:topics], refuted_by_hypotheses_str: hypothesis_attrs[:refuted_by_hypotheses])
      hypothesis.tags.unapproved.update_all(approved_at: Time.current)
      hypothesis_attrs[:cited_urls]&.map do |cited_url|
        hypothesis_citation = hypothesis.hypothesis_citations.where(url: cited_url[:url]).first
        hypothesis_citation ||= hypothesis.hypothesis_citations.build(url: cited_url[:url])
        hypothesis_citation.update(quotes_text: cited_url[:quotes].join("\n"))
        # If we've imported the hypothesis citation through this, we need to approve it
        unless hypothesis_citation.citation.approved?
          hypothesis_citation.citation.update(approved_at: Time.current)
        end
      end
      hypothesis
    end

    def import_citations
      Dir.glob("#{FILES_PATH}/citations/**/*.yml").each do |file|
        import_citation(YAML.load_file(file).with_indifferent_access)
      end
    end

    # TODO: This method isn't tested in detail, and should be
    def import_citation(citation_attrs)
      citation = Citation.where(id: citation_attrs[:id]).first || Citation.new
      citation.approved_at ||= Time.current # If it's in the flat files, it's approved
      citation.update(title: citation_attrs[:title],
                      kind: Citation.friendly_find_kind(citation_attrs[:kind]) || Citation.kinds.first,
                      url: citation_attrs[:url],
                      url_is_not_publisher: citation_attrs[:url_is_not_publisher],
                      publication_title: citation_attrs[:publication_title],
                      peer_reviewed: citation_attrs[:peer_reviewed],
                      url_is_direct_link_to_full_text: citation_attrs[:url_is_direct_link_to_full_text],
                      published_date_str: citation_attrs[:published_date],
                      authors: citation_attrs[:authors])
      # We need to save first, so we can update the columns if necessary
      unless citation.id == citation_attrs[:id]
        citation.update_columns(id: citation_attrs[:id])
      end
      citation
    end
  end
end
