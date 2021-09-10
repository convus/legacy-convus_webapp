# TODO: make this less shitty, probably using octokit
# Specifically: this is mission critical and needs to be tested

class GitContentRepo
  NON_ERROR_STRINGS = [
    "Already up to date",
    "Everything up-to-date",
    "Your branch is up to date with 'origin/main'"
  ]

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
end
