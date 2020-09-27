module ApprovedAtable
  extend ActiveSupport::Concern

  included do
    scope :approved, -> { where.not(approved_at: nil) }
    scope :unapproved, -> { where(approved_at: nil) }
  end

  def approved?
    approved_at.present?
  end

  def unapproved?
    !approved?
  end
end
