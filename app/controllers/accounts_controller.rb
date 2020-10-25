class AccountsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  def show
    @hypotheses = current_user.created_hypotheses
    @hypotheses_submitted = @hypotheses.submitted_to_github
    @hypotheses_not_submitted = @hypotheses.not_submitted_to_github
  end
end
