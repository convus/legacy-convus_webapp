class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :ensure_user!, raise: false

  def bike_index
    @user = User.from_omniauth(request.env["omniauth.auth"].uid, request.env["omniauth.auth"])
    if @user.persisted?
      sign_in_and_redirect @user
    else
      flash[:error] = "We're sorry, we failed to sign you in. Can't help you now"
      redirect_to root_url
    end
  end
end
