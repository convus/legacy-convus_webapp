class User < ApplicationRecord
  ROLE_ENUM = {normal_user: 0, developer: 6}

  devise :database_authenticatable, :registerable, :omniauthable,
    :rememberable, :trackable, omniauth_providers: [:github]

  has_many :created_hypotheses, class_name: "Hypothesis", foreign_key: :creator_id
  has_many :created_citations, class_name: "Citation", foreign_key: :creator_id
  has_many :user_scores

  enum role: ROLE_ENUM

  before_validation :set_calculated_attributes

  # TODO: make this better, with case insensitivity and striping
  def self.friendly_find(str)
    find_by_username(str) || find_by_email(str) || find_by_id(str)
  end

  def self.from_omniauth(uid, auth)
    user = where(github_id: uid.to_i).first

    if user.present?
      user.update(github_auth: auth)
      return user
    end
    User.create(github_id: uid, password: Devise.friendly_token[0, 20], github_auth: auth)
  end

  def admin_access?
    developer?
  end

  # Maybe someday, involves more sophisticated things
  def github?
    github_auth.present?
  end

  def set_calculated_attributes
    self.role ||= "normal_user"
    if github?
      self.username = github_auth.dig("info", "nickname")
      self.email = github_auth.dig("info", "email")
    else
      self.username ||= email
    end
  end

  # This will definitely become sophisticated
  def trustedness
    recent_approved_hypotheses.count * 10
  end

  def recent_approved_hypotheses
    created_hypotheses.approved.where("created_at > ?", Time.current - 1.month)
  end

  def recent_approved_citations
    created_citations.approved.where("created_at > ?", Time.current - 1.month)
  end
end
