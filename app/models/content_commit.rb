# NOTE: for now, we're only recording commits to the main branch

class ContentCommit < ApplicationRecord
  validates :sha, allow_blank: false, uniqueness: true

  before_validation :set_calculated_attributes

  def message
    github_data.dig("commit", "message")
  end

  def reconciler_update?
    author == "convus-admin-bot" && message.start_with?("Reconciliation:")
  end

  def set_calculated_attributes
    self.sha ||= github_data&.dig("sha")
    self.committed_at ||= TimeParser.parse(github_data_committed_at)
    self.author ||= github_data_author
  end

  def github_data_author
    github_data.dig("author", "login")
  end

  def github_data_committed_at
    github_data&.dig("commit", "committer", "date")
  end
end
