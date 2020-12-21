# Outputs a current version of the database

class FlatFileSerializer
  FILES_PATH = File.path(ENV["FLAT_FILE_PATH"])

  class << self
    def write_all_files
      Hypothesis.approved.find_each { |hypothesis| write_hypothesis(hypothesis) }
      Citation.approved.find_each { |citation| write_citation(citation) }
      write_approved_tags
      write_all_publications
    end

    def write_hypothesis(hypothesis)
      dirname = File.dirname(hypothesis.flat_file_name(FILES_PATH))
      # Create the intermidiary directories
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      File.open(hypothesis.flat_file_name(FILES_PATH), "w") do |f|
        f.puts(hypothesis.flat_file_content)
      end
    end

    def write_citation(citation)
      dirname = File.dirname(citation.flat_file_name(FILES_PATH))
      # Create the intermidiary directories
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      File.open(citation.flat_file_name(FILES_PATH), "w") do |f|
        f.puts(citation.flat_file_content)
      end
    end

    def tags_file
      filepath = File.join(FILES_PATH, "tags.csv")
      dirname = File.dirname(filepath)
      # Create the intermidiary directories
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      filepath
    end

    def write_approved_tags
      File.open(tags_file, "w") { |f|
        f.puts Tag.serialized_attrs.join(",") # Skip price of initializing serializer for csv, instead use pluck
        Tag.alphabetical.pluck(*Tag.serialized_attrs).each { |attrs| f.puts attrs.join(",") }
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
      CSV.open(publications_file, "w") { |csv|
        csv << Publication.serialized_attrs
        Publication.alphabetical.pluck(*Publication.serialized_attrs)
          .each { |r| csv << r }
      }
    end
  end
end
