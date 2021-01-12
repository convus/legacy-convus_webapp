class CitationChallenge < ApplicationRecord
  include ApprovedAtable
  include GithubSubmittable

  KIND_ENUM = {
    citation_does_not_support_hypothesis: 0,
    refutted_by_another_citation: 2
  }.freeze

  belongs_to :creator, class_name: "User"
  belongs_to :supporting_citation, class_name: "Citation"
  belongs_to :hypothesis_citation
  has_one :citation, through: :hypothesis_citation
  has_one :hypothesis, through: :hypothesis_citation


  def self.kinds
    KIND_ENUM.keys.map(&:to_s)
  end

  enum kind: KIND_ENUM
end
