class ReconcileTaskOutputChecker
  NON_ERROR_STRINGS = [
    "Already up to date",
    "Everything up-to-date"
  ]

  def self.success?(output)
    NON_ERROR_STRINGS.any? { |string| output.match?(/#{string}/i) }
  end
end
