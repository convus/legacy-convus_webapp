# TODO: This is an embarrassing solution, and needs to be improved
# ....
# HOWEVER - one of the advantages of this solution is that it is blocking - only one job runs at a time
# - the idea of managing multiple imports simultaneously is additional complexity that is nice to avoid
task reconcile_flat_file_database: :environment do
  # Move into the repository directory
  git_content_repo = GitContentRepo.new
  git_content_repo.enter_repository
  git_content_repo.reset_main

  FlatFileImporter.import_all_files # Import the files from the git branch
  # Remove the existing hypotheses and citations, and then re-write them
  # Important because of title/slug renaming
  FileUtils.rm_rf("hypotheses")
  FileUtils.rm_rf("citations")
  FlatFileSerializer.write_all_files

  git_content_repo.add_all
  git_content_repo.commit(git_content_repo.new_reconciliation_message)
  git_content_repo.push

  puts "(Output start) " + git_content_repo.output + " (output end)\n\n"
  raise git_content_repo.output if git_content_repo.output_failed?
end

# This generally should NOT be used. It does not import the updates from git before pushing up the current data
# It pushes a branch up named "override-#{timestamp}", which needs to be manually merged
# This CAN OVERWRITE THINGS IN THE CONTENT REPOSITORY. It's for fixing broken stuff, YMMV
task update_flat_file_database_without_import: :environment do
  # Move into the repository directory
  git_content_repo = GitContentRepo.new
  git_content_repo.enter_repository
  git_content_repo.reset_main

  branch_name = "override-#{Time.current.to_i}"
  git_content_repo.checkout_branch(branch_name)

  FileUtils.rm_rf("hypotheses")
  FileUtils.rm_rf("citations")
  FlatFileSerializer.write_all_files
  git_content_repo.add_all
  git_content_repo.commit(git_content_repo.new_reconciliation_message)
  git_content_repo.push
  # Get back on main to prevent possible future errors
  git_content_repo.checkout_main
  # cleanup branch
  git_content_repo.delete_branch

  puts "(Output start) " + git_content_repo.output + " (output end)\n\n"
  raise git_content_repo.output if git_content_repo.output_failed?
end

task dev_update_from_git: :environment do
  git_content_repo = GitContentRepo.new
  git_content_repo.enter_repository
  git_content_repo.reset_main
  FlatFileImporter.import_all_files # Import the files from the git branch
  puts "(Output start) " + git_content_repo.output + " (output end)\n\n"
end

# Useful if formatting changes for explanations!
# All approved explanations are reprocessed when they are imported
task regenerate_explanation_bodies: :environment do
  Explanation.find_each { |a| a.update_body_html }
end
