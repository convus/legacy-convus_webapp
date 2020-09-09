class AccountsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  def show
  end
end
