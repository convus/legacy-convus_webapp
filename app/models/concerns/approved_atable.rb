module ApprovedAtable
  extend ActiveSupport::Concern

  included do
    scope :approved, -> { where.not(approved_at: nil) }
    scope :unapproved, -> { where(approved_at: nil) }
    # TODO: make this work better. Should use coalesce?
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
