class AccountsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  def show
    @hypotheses = current_user.created_hypotheses.reorder(id: :desc)
    @hypotheses_submitted = @hypotheses.submitted_to_github.reorder(id: :desc)
    @hypotheses_not_submitted = @hypotheses.not_submitted_to_github.reorder(id: :desc)
  end
end
