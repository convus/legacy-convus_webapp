# Outputs a current version of the database

class FlatFileSerializer
  FILES_PATH = File.path(ENV["FLAT_FILE_PATH"])
  require "csv"

  class << self
    # For now, don't wrapping lines. It makes editing easier, only elder programmers expect it
    def yaml_opts
      {options: {line_width: -1}}
    end

    def write_all_files
      Hypothesis.approved.find_each { |hypothesis| write_hypothesis(hypothesis) }
      Citation.approved.find_each { |citation| write_citation(citation) }
      write_approved_tags
      write_all_publications
    end

    def write_hypothesis(hypothesis)
      dirname = File.dirname(hypothesis.flat_file_name(FILES_PATH))
      # Create the intermediary directories
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
      CSV.open(tags_file, "w") { |csv|
        csv << Tag.serialized_attrs
        # Skip price of initializing serializer for csv, instead use pluck because it works (at least for now)
        Tag.alphabetical.pluck(*Tag.serialized_attrs).each { |attrs| csv << attrs }
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
        # Skip price of initializing serializer for csv, instead use pluck because it works (at least for now)
        Publication.alphabetical.pluck(*Publication.serialized_attrs)
          .each { |attrs| csv << attrs }
      }
    end
  end
end
