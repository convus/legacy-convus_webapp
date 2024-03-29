class AccountsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  def show
    @hypotheses = current_user.created_hypotheses.newness_ordered
    @hypotheses_submitted = @hypotheses.submitted_to_github.newness_ordered
    @hypotheses_not_submitted = @hypotheses.not_submitted_to_github.newness_ordered
  end
end
