task reconcile_flat_file_database: :environment do
  FlatFileImporter.reconcile_flat_files
end
