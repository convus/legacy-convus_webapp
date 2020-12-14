class Refutation < ApplicationRecord
  belongs_to :refuter_hypothesis, class_name: "Hypothesis"
  belongs_to :refuted_hypothesis, class_name: "Hypothesis"

  validates :refuter_hypothesis_id, presence: true, uniqueness: {scope: [:refuted_hypothesis_id]}

  after_commit :update_refuted_hypothesis

  attr_accessor :skip_associated_tasks

  def update_refuted_hypothesis
    return false if skip_associated_tasks
    refuted_hypothesis&.update(updated_at: Time.current)
  end
end
