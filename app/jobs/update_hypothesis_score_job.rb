class UpdateHypothesisScoreJob < ApplicationJob
  def perform(id = nil)
    return enqueue_all_hypotheses_for_update unless id.present?
    hypothesis = Hypothesis.find(id)
    # Update the citations first, because it may impact the hypothesis score calculation
    hypothesis.citations.each do |citation|
      citation.update(updated_at: Time.current) unless citation.score == citation.calculated_score
    end
    hypothesis.reload
    hypothesis.update(updated_at: Time.current) unless hypothesis.score == hypothesis.calculated_score
  end

  def enqueue_all_hypotheses_for_update
    Hypothesis.approved.pluck(:id).each { |id| UpdateHypothesisScoreJob.perform_async(id) }
  end
end
