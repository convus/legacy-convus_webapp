# TODO: make this less shitty, probably using octokit
# Specifically: this is mission critical and needs to be tested
class GitContentRepo
  NON_ERROR_STRINGS = [
    "Already up to date",
    "Everything up-to-date",
    "Your branch is up to date with 'origin/main'"
  ].freeze

  def self.output_success?(output)
    return true if output.blank?
    return true if NON_ERROR_STRINGS.any? { |string| output.match?(/#{string}/i) }
    last_line = output.split("\n").last
    # If the last line looks like this: d201524..df11e5b main -> main - it means the whole task ran through
    last_line.match?(/main -> main/)
  end

  def self.output_failed?(output)
    !output_success?(output)
  end

  def initialize(repo_path: nil, branch: nil)
    @repo_path = repo_path || FlatFileSerializer::FILES_PATH
    @output = ""
    @branch = branch || "main"
  end

  attr_reader :repo_path, :output, :branch

  def enter_repository
    Dir.chdir repo_path
    @output += `git config user.email admin-bot@convus.org`
    @output += `git config user.name convus-admin-bot`
  end

  def git_auth
    'GIT_SSH_COMMAND="ssh -i ~/.ssh/admin_bot_id_rsa"'
  end

  def checkout_main
    @output += `#{git_auth} git checkout main 2>&1`
  end

  def reset_main
    # Make sure we're up to date on the main branch
    checkout_main
    @output += `#{git_auth} git reset --hard origin/main 2>&1`
    @output += `#{git_auth} git fetch origin 2>&1`
    @output += `#{git_auth} git merge origin 2>&1`
  end

  def add_all
    @output += `git add -A`
  end

  # Memoize so it returns the same thing pre & post commit
  def new_reconciliation_message
    return @new_reconciliation_message if defined?(@new_reconciliation_message)
    message = "Reconciliation: #{Time.now.utc.to_date.iso8601}"
    # Get the number of commit_messages with that title, add number to the back of the message
    reconciliation_count = `#{git_auth} git --no-pager log --grep="#{message}" --format=oneline 2>&1`
    @new_reconciliation_message = "#{message}_#{reconciliation_count.scan(/\n/).size + 1}"
  end

  def commit(message)
    @output += `#{git_auth} git commit -m"#{message}" 2>&1`
  end

  def push
    @output += `#{git_auth} git push origin #{@branch} 2>&1`
  end

  def output_failed?
    self.class.output_failed?(@output)
  end

  def checkout_branch(new_branch)
    @branch = new_branch
    @output += `#{git_auth} git checkout -b #{@branch} 2>&1`
  end

  def delete_branch
    raise "Can't delete main branch" if @branch == "main"
    @output += `#{git_auth} git branch -D #{@branch} 2>&1`
  end
end
