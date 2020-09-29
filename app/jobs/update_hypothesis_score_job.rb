class UpdateHypothesisScoreJob < ApplicationJob
  def perform(id = nil)
    return enqueue_all_hypotheses_for_update unless id.present?
    hypothesis = Hypothesis.find(id)
    hypothesis.update(updated_at: Time.current) unless hypothesis.score == hypothesis.calculated_score
  end

  def enqueue_all_hypotheses_for_update
    Hypothesis.approved.pluck(:id).each { |id| UpdateHypothesisScoreJob.perform_async(id) }
  end
end
