class FlatFileSerializer
  FILES_PATH = File.path(ENV["FLAT_FILE_OUT_PATH"])

  class << self

    def write_all_files
      write_all_hypotheses
      write_all_citations
      write_all_tags
      write_all_publications
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

    def tags_file
      filepath = File.join(FILES_PATH, "tags.csv")
      dirname = File.dirname(filepath)
      # Create the intermidiary directories
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      filepath
    end

    def write_all_tags
      attrs_to_write = %i[title id slug taxonomy] # Skip price of initializing serializer for csv
      File.open(tags_file, "w") { |f|
        f.puts attrs_to_write.join(",")
        Tag.alphabetical.pluck(*attrs_to_write).each { |attrs| f.puts attrs.join(",") }
      }
    end

    def publications_file
      filepath = File.join(FILES_PATH, "publications.csv")
      dirname = File.dirname(filepath)
      # Create the intermidiary directories
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      filepath
    end

    def write_all_publications
      attrs_to_write = %i[title slug id has_published_retractions has_peer_reviewed_articles home_url]
      File.open(publications_file, "w") { |f|
        f.puts attrs_to_write.join(",")
        Publication.alphabetical.pluck(*attrs_to_write).each { |attrs| f.puts attrs.join(",") }
      }
    end
  end
end
