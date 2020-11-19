# NOTE: for now, we're only recording commits to the main branch
class ContentCommit < ApplicationRecord
  validates :sha, uniqueness: true, allow_blank: false

  def reconciler_update?
    false
  end

end
