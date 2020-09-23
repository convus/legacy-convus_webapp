# TODO: This is an embarrassing solution, and needs to be improved, probably using octokit
# Ideally this would be in a service. This is mission critical and needs to be tested
# ....
# HOWEVER - one of the advantages of this solution is that it is blocking - only one job runs at a time
# - the idea of managing multiple imports simultaneously is more difficult where things
task reconcile_flat_file_database: :environment do
  Dir.chdir FlatFileSerializer::FILES_PATH
  output = ""
  output += `git config user.email admin-bot@convus.org`
  output += `git config user.name convus-admin-bot`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git reset --hard origin/main`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git pull origin main`
  FlatFileImporter.import_all_files # Import the files from the git branch
  FlatFileSerializer.write_all_files
  output += `git add -A`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git commit -m"reconciliation"`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git push origin main`
  puts "After push"
  puts output
  # if ReconcileTaskOutputChecker.output_contains_error?(output)
  #   raise output
  # end
end
