desc "Write/update flat file database"
task output_flat_files: :environment do
  FlatFileSerializer.write_all_files
end
