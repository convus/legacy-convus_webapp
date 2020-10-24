# Note: as of now, models with GithubSubmittable also require ApprovedAtable
module GithubSubmittable
  extend ActiveSupport::Concern

  included do
    scope :submitted_to_github, -> { approved.or(where.not(pull_request_number: nil)) }
    scope :not_submitted_to_github, -> { where(approved_at: nil, pull_request_number: nil) }
  end

  def submitted_to_github?
    approved? || pull_request_number.present?
  end

  def not_submitted_to_github?
    !submitted_to_github?
  end
end
