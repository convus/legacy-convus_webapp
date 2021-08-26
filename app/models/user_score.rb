class UserScore < ApplicationRecord
  MIN_SCORE = 0
  MAX_SCORE = 9
  KIND_ENUM = {quality: 0, controversy: 1}

  belongs_to :user
  belongs_to :hypothesis
  belongs_to :argument

  before_validation :set_calculated_attributes
  after_commit :expire_previous_scores, only: [:create]

  validates :user_id, presence: true

  enum kind: KIND_ENUM

  scope :expired, -> { where(expired: true) }
  scope :current, -> { where(expired: false) }

  def self.current_score
    current_count = current.count
    return nil unless current_count > 0
    (current.sum(:score) / current_count.to_f).round(2)
  end

  def set_calculated_attributes
    self.score = MIN_SCORE if score < MIN_SCORE
    self.score = MAX_SCORE if score > MAX_SCORE
  end

  def expire_previous_scores
    return false if expired?
    UserScore.where(user_id: user_id, hypothesis_id: hypothesis_id, kind: kind, expired: false)
      .where("id < ?", id)
      .update_all(expired: true)
  end
end
