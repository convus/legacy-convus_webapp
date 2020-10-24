class AddSubmittingToGithubToHypothesisAndCitations < ActiveRecord::Migration[6.0]
  def change
    add_column :hypotheses, :submitting_to_github, :boolean, default: false
    add_column :citations, :submitting_to_github, :boolean, default: false
  end
end
