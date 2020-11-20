class ReconcileTaskOutputChecker
  NON_ERROR_STRINGS = [
    "Already up to date",
    "Everything up-to-date"
  ]

  def self.success?(output)
    return true if output.blank?
    return true if NON_ERROR_STRINGS.any? { |string| output.match?(/#{string}/i) }
    last_line = output.split("\n").last
    # If the last line looks like this: d201524..df11e5b main -> main - it means the whole task ran through
    last_line.match?(/main -> main/)
  end

  def self.failed?(output)
    !success?(output)
  end
end
