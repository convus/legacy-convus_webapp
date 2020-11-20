# NOTE: for now, we're only recording commits to the main branch

class ContentCommit < ApplicationRecord
  validates :sha, allow_blank: false, uniqueness: true

  before_validation :set_calculated_attributes

  def author
    github_data.dig("author", "login")
  end

  def message
    github_data.dig("commit", "message")
  end

  def reconciler_update?
    author == "convus-admin-bot" && message.start_with?("Reconciliation:")
  end

  def set_calculated_attributes
    self.sha ||= github_data&.dig("sha")
  end
end
