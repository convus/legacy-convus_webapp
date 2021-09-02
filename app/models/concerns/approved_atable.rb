# NOTE: Do NOT add this concern to models that have GithubSubmittable -
# GithubSubmittable has all the methods from this concern but does different things because removed_pull_request_number

module ApprovedAtable
  extend ActiveSupport::Concern

  included do
    scope :approved, -> { where.not(approved_at: nil) }
    scope :unapproved, -> { where(approved_at: nil) }
    # TODO: make this work better. Should use coalesce? - also update the scope in GithubSubmittable
    # Order by approved_at, unless it isn't approved, in which case order by created_at
    scope :newness_ordered, -> { reorder("approved_at DESC NULLS FIRST", created_at: :desc) }
  end

  def approved?
    approved_at.present?
  end

  def unapproved?
    !approved?
  end
end
