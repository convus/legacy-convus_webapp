# TODO: This is an embarrassing solution, and needs to be improved, probably using octokit
# Ideally this would be in a service. This is mission critical and needs to be tested
# ....
# HOWEVER - one of the advantages of this solution is that it is blocking - only one job runs at a time
# - the idea of managing multiple imports simultaneously is more difficult where things
task reconcile_flat_file_database: :environment do
  Dir.chdir FlatFileSerializer::FILES_PATH
  output = ""
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git config admin-bot@convus.org`
  puts "after config"
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git reset --hard origin/main`
  puts "After reset"
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git pull origin main`
  puts "After PULL"
  FlatFileImporter.import_all_files # Import the files from the git branch
  FlatFileSerializer.write_all_files
  output += `git add -A`
  puts "After ADD"
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git commit -m"reconciliation"`
  puts "AFTER Commit"
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git push origin main`
  # Check this output with something, to see if it errored
  raise output
  # git_push_output = `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git add -A && git commit -m"reconciliation" && git push origin main`
end
