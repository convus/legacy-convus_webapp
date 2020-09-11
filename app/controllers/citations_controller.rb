class CitationsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: [:index]

  def index
    @citations = Citation.reorder(created_at: :desc)
  end
end
