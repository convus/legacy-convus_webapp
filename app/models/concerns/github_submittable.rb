# Note: as of now, models with GithubSubmittable also require ApprovedAtable
module GithubSubmittable
  extend ActiveSupport::Concern

  included do
    scope :removed, -> { where.not(removed_pull_request_number: nil) }
    scope :not_removed, -> { where(removed_pull_request_number: nil) }
    scope :approved, -> { not_removed.where.not(approved_at: nil) }
    scope :submitted_to_github, -> { approved.or(not_removed.where.not(pull_request_number: nil)).or(not_removed.where(submitting_to_github: true)) }
    scope :not_submitted_to_github, -> { not_removed.where(approved_at: nil, pull_request_number: nil, submitting_to_github: false) }

    attr_accessor :add_to_github
  end

  # NOTE: Removed, for now, is a manual update via the console
  def removed?
    removed_pull_request_number.present?
  end

  def approved?
    approved_at.present? && !removed?
  end

  def submitted_to_github?
    return false if removed?
    approved? || pull_request_number.present? || submitting_to_github
  end

  def not_submitted_to_github?
    return false if removed?
    !submitted_to_github?
  end

  def waiting_on_github?
    return false if approved? || GithubIntegration::SKIP_GITHUB_UPDATE
    submitted_to_github?
  end

  def editable_by?(user = nil)
    return false unless user.present? && not_submitted_to_github?
    creator == user
  end

  def add_to_github_content
    return true if submitted_to_github? || GithubIntegration::SKIP_GITHUB_UPDATE
    return false unless ParamsNormalizer.boolean(add_to_github)
    AddToGithubContentJob.perform_async(self.class.name, id)
    # Because we've enqueued, and we want the fact that it is submitted to be reflected instantly
    # ... But call after adding to the job, so we know we're actually in the submitting process
    update(submitting_to_github: true)
  end
end
