# frozen_string_literal: true

class Admin::BaseController < ApplicationController
  before_action :ensure_admin_access!

  def ensure_admin_access!
    return redirect_to_signup_unless_user_present! if current_user.blank?
    return true if current_user&.developer?
    flash[:error] = "Sorry, you don't have access to that"
    redirect_to user_root_path
    nil
  end
end
