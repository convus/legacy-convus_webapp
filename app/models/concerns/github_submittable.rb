# Note: as of now, models with GithubSubmittable also require ApprovedAtable
module GithubSubmittable
  extend ActiveSupport::Concern

  included do
    scope :submitted_to_github, -> { approved.or(where.not(pull_request_number: nil)).or(where(submitting_to_github: true)) }
    scope :not_submitted_to_github, -> { where(approved_at: nil, pull_request_number: nil, submitting_to_github: false) }
  end

  def submitted_to_github?
    approved? || pull_request_number.present? || submitting_to_github
  end

  def not_submitted_to_github?
    !submitted_to_github?
  end

  def editable_by?(user = nil)
    return false unless user.present? && not_submitted_to_github?
    creator == user
  end
end
