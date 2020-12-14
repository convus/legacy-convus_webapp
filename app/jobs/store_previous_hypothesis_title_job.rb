# NOTE: I initially put this inline - but errors in creation couldn't be surfaced,
# or they would block saving the hypothesis, so this seemed like a better option.
# Not for performance, but for observability

class StorePreviousHypothesisTitleJob < ApplicationJob
  sidekiq_options backtrace: true, retry: false

  def perform(hypothesis_id, old_title)
    return true if old_title.blank?
    hypothesis = Hypothesis.find(hypothesis_id)
    previous_title = hypothesis.previous_titles.build(title: old_title)
    # We might not want to raise an error in the future, but since this shouldn't happen often, raise to make sure we see it
    previous_title.save!
  end
end
