# Outputs a current version of the database

class FlatFileImporter
  FILES_PATH = FlatFileSerializer::FILES_PATH

  class << self
    # TODO: This is an embarrassing solution, and needs to be improved, probably using octokit
    # Right now this is just for a rake task
    def reconcile_flat_files
      Dir.chdir FILES_PATH
      git_pull_output = `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git pull origin main`
      import_all_files
      FlatFileSerializer.write_all_files
      pp "fffxcv7xcv7s9912312"
      puts `git add -A`
      puts `git commit -m"reconciliation"`
      puts `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git push origin main`
      # git_push_output = `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git add -A && git commit -m"reconciliation" && git push origin main`
    end

    def import_all_files
      import_citations
      import_hypotheses
      # TODO: Import tags and publications
    end

    def import_hypotheses
      Dir.glob("#{FILES_PATH}/hypotheses/*.yml").each do |file|
        import_hypothesis(YAML.load_file(file).with_indifferent_access)
      end
    end

    # TODO: This method isn't tested in detail, and should be
    def import_hypothesis(hypothesis_attrs)
      hypothesis = Hypothesis.where(id: hypothesis_attrs[:id]).first || Hypothesis.new
      hypothesis.approved_at ||= Time.current # If it's in the flat files, it's approved
      hypothesis.update(title: hypothesis_attrs[:title], has_direct_quotation: hypothesis_attrs[:direct_quotation])
      # We need to save first, so we can update the columns if necessary, before creating associations
      unless hypothesis.id == hypothesis_attrs[:id]
        created_at = TimeParser.parse(hypothesis_attrs[:created_at]) || Time.current
        hypothesis.update_columns(id: hypothesis_attrs[:id], created_at: created_at)
      end
      hypothesis.update(tags_string: hypothesis_attrs[:tag_titles], citation_urls: hypothesis_attrs[:citation_urls])
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
                      url: citation_attrs[:url],
                      publication_title: citation_attrs[:publication_title],
                      kind: citation_attrs[:kind],
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
