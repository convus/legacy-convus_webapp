class FlatFileSerializer
  FILES_PATH = File.path(ENV["FLAT_FILE_OUT_PATH"])

  class << self

    def write_all_files
      write_all_hypotheses
    end

    def write_all_hypotheses
      Hypothesis.find_each { |hypothesis| write_hypothesis(hypothesis) }
    end

    def write_hypothesis(hypothesis)
      dirname = File.dirname(hypothesis.flat_file_name(FILES_PATH))
      # Create the intermidiary directories
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      File.open(hypothesis.flat_file_name(FILES_PATH), "w") { |f|
        f.puts(HypothesisSerializer.new(hypothesis, root: false).as_json.to_yaml)
      }
    end

    def write_all_citations
      Citation.find_each { |citation| write_citation(citation) }
    end

    def write_citation(citation)
      dirname = File.dirname(citation.flat_file_name(FILES_PATH))
      # Create the intermidiary directories
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      File.open(citation.flat_file_name(FILES_PATH), "w") { |f|
        f.puts(CitationSerializer.new(citation, root: false).as_json.to_yaml)
      }
    end

    def write_all_publications
      Publication.find_each { |publication| write_publication(publication) }
    end

    def write_publication(publication)
      dirname = File.dirname(publication.flat_file_name(FILES_PATH))
      # Create the intermidiary directories
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      File.open(publication.flat_file_name(FILES_PATH), "w") { |f|
        f.puts(PublicationSerializer.new(publication, root: false).as_json.to_yaml)
      }
    end
  end
end
