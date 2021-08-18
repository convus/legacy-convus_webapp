class Argument < ApplicationRecord
  include ReferenceIdable
  include ApprovedAtable
  include GithubSubmittable
  include PgSearch::Model

  belongs_to :creator, class_name: "User"
  belongs_to :hypothesis

  has_many :quotes
  has_many :user_scores

  after_commit :run_associated_tasks

  attr_accessor :skip_associated_tasks

  # This will definitely become more sophisticated later!
  def display_id
    "#{hypothesis&.display_id}: Argument-#{id}"
  end

  def run_associated_tasks
    return false if skip_associated_tasks
    add_to_github_content
  end
end
