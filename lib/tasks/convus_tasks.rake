# TODO: This is an embarrassing solution, and needs to be improved, probably using octokit
# Ideally this would be in a service. This is mission critical and needs to be tested
# ....
# HOWEVER - one of the advantages of this solution is that it is blocking - only one job runs at a time
# - the idea of managing multiple imports simultaneously is additional complexity that is nice to avoid
task reconcile_flat_file_database: :environment do
  Dir.chdir FlatFileSerializer::FILES_PATH
  output = ""
  output += `git config user.email admin-bot@convus.org`
  output += `git config user.name convus-admin-bot`
  # Make sure we're up to date on the main branch
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git checkout main 2>&1`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git reset --hard origin/main 2>&1`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git fetch origin 2>&1`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git merge origin 2>&1`
  FlatFileImporter.import_all_files # Import the files from the git branch
  # Remove the existing hypotheses and citations, and then re-write them
  # Important because of title/slug renaming
  FileUtils.rm_rf("hypotheses")
  FileUtils.rm_rf("citations")
  FlatFileSerializer.write_all_files
  output += `git add -A`
  commit_message = "Reconciliation: #{Time.now.utc.to_date.iso8601}"
  # Get the number of commit_messages with that title, add number to the back of the commit_message
  reconciliation_count = `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git --no-pager log --grep="#{commit_message}" --format=oneline 2>&1`
  commit_message += "_#{reconciliation_count.scan(/\n/).size + 1}"
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git commit -m"#{commit_message}" 2>&1`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git push origin main 2>&1`

  puts "(Output start) " + output + " (output end)\n\n"

  raise output if ReconcileTaskOutputChecker.failed?(output)
end

# This generally should NOT be used. It does not import the updates from git before pushing up the current data
# It pushes a branch up named "override-#{timestamp}", which needs to be manually merged
# This CAN OVERWRITE THINGS IN THE CONTENT REPOSITORY. It's for fixing broken stuff, YMMV
task update_flat_file_database_without_import: :environment do
  Dir.chdir FlatFileSerializer::FILES_PATH
  output = ""
  output += `git config user.email admin-bot@convus.org`
  output += `git config user.name convus-admin-bot`
  # In case something fucked up, checkout the main branch
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git checkout main 2>&1`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git reset --hard origin/main 2>&1`
  branch_name = "override-#{Time.current.to_i}"
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git checkout -b #{branch_name} 2>&1`
  FileUtils.rm_rf("hypotheses")
  FileUtils.rm_rf("citations")
  FlatFileSerializer.write_all_files
  output += `git add -A`
  commit_message = "Reconciliation: #{Time.now.utc.to_date.iso8601}"
  # Get the number of commit_messages with that title, add number to the back of the commit_message
  reconciliation_count = `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git --no-pager log --grep="#{commit_message}" --format=oneline 2>&1`
  commit_message += "_#{reconciliation_count.scan(/\n/).size + 1}"
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git commit -m"#{commit_message}" 2>&1`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git push origin #{branch_name} 2>&1`
  # Get back on main so future commands don't error
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git checkout main 2>&1`

  puts "(Output start) " + output + " (output end)"

  raise output if ReconcileTaskOutputChecker.failed?(output)
end

# Useful if formatting changes for arguments!
# All approved arguments are reprocessed when they are imported
task regenerate_argument_bodies: :environment do
  Argument.find_each { |a| a.update_body_html }
end

task dev_update_from_git: :environment do
  Dir.chdir FlatFileSerializer::FILES_PATH
  output = `git reset --hard origin/main 2>&1`
  output += `git fetch origin 2>&1`
  output += `git merge origin 2>&1`
  pp "Output:", output
  FlatFileImporter.import_all_files # Import the files from the git branch
end
