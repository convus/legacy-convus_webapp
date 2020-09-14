class FlatFileSerializer
  FILES_PATH = File.path(ENV["FLAT_FILE_OUT_PATH"])

  def self.write_all_publications
    Publication.find_each { |publication| write_publication(publication) }
  end

  def self.write_publication(publication)
    dirname = File.dirname(publication.flat_file_name(FILES_PATH))
    # Create the intermidiary directories
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    File.open(publication.flat_file_name(FILES_PATH), "w") { |f|
      f.puts(PublicationSerializer.new(publication, root: false).as_json.to_yaml)
    }
  end
end
