# Outputs a current version of the database

class FlatFileImporter
  FILES_PATH = File.path(ENV["FLAT_FILE_IN_PATH"])

  class << self
    def write_all_files
      import_hypotheses
      import_citations
      # TODO: Import tags and publications
    end

    def import_hypotheses
    end

    def import_citations
    end
  end
end
