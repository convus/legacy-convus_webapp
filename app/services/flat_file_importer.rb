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
      Dir.glob("#{FILES_PATH}/hypotheses/*.md").each do |file|
        HypothesisMarkdownParser.new(file_content: File.read(file)).import
      end
    end

    def import_citations
      Dir.glob("#{FILES_PATH}/citations/**/*.yml").each do |file|
        import_citation(YAML.load_file(file).with_indifferent_access)
      end
    end

    def import_citation(citation_attrs)
      citation = Citation.where(id: citation_attrs[:id]).first || Citation.new
      citation.approved_at ||= Time.current # If it's in the flat files, it's approved
      citation.update(title: citation_attrs[:title],
        kind: Citation.friendly_find_kind(citation_attrs[:kind]) || Citation.kinds.first,
        url: citation_attrs[:url],
        url_is_not_publisher: citation_attrs[:url_is_not_publisher],
        publication_title: citation_attrs[:publication_title],
        peer_reviewed: citation_attrs[:peer_reviewed],
        doi: citation_attrs[:doi],
        url_is_direct_link_to_full_text: citation_attrs[:url_is_direct_link_to_full_text],
        published_date_str: citation_attrs[:published_date],
        authors: citation_attrs[:authors])
      # We need to save first, so we can update the columns if necessary
      unless citation.id == citation_attrs[:id]
        citation.update_columns(id: citation_attrs[:id])
      end
      citation
    end

    # probably should be private
    def create_hypothesis_citation(hypothesis, hc_attrs)
      if hc_attrs[:challenges].present?
        challenged_id = hypothesis.hypothesis_citations.hypothesis_supporting
          .where(url: hc_attrs[:challenges]).first&.id
      end
      hypothesis_citation = hypothesis.hypothesis_citations.where(url: hc_attrs[:url],
        challenged_hypothesis_citation_id: challenged_id).first
      hypothesis_citation ||= hypothesis.hypothesis_citations.build(url: hc_attrs[:url])
      hypothesis_citation.approved_at ||= hypothesis_citation.citation&.approved_at || Time.current
      hypothesis_citation.creator_id ||= hypothesis_citation.citation&.creator_id
      hypothesis_citation.challenged_hypothesis_citation_id ||= challenged_id
      hypothesis_citation.update(quotes_text: hc_attrs[:quotes].join("\n"))
      # If we've imported the hypothesis citation through this, we need to approve it
      unless hypothesis_citation.citation.approved?
        hypothesis_citation.citation.update(approved_at: Time.current)
      end
      hypothesis_citation
    end
  end
end
