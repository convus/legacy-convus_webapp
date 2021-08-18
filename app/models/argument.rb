class Argument < ApplicationRecord
  include ApprovedAtable
  include GithubSubmittable
  include PgSearch::Model

  belongs_to :creator, class_name: "User"
  belongs_to :hypothesis

  has_many :quotes
  has_many :user_scores
end
