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
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git reset --hard origin/main`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git pull origin main`
  FlatFileImporter.import_all_files # Import the files from the git branch
  # Remove the existing hypotheses and citations, and then re-write them
  # Important because of title/slug renaming
  FileUtils.rm_rf("hypotheses")
  FileUtils.rm_rf("citations")
  FlatFileSerializer.write_all_files
  output += `git add -A`
  commit_message = "Reconciliation: #{Time.now.utc.to_date.iso8601}"
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git commit -m"#{commit_message}"`
  output += `GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa" git push origin main`

  puts "Output: " + output + " (output end)"

  if ReconcileTaskOutputChecker.success?(output)
    raise output
  end
end
