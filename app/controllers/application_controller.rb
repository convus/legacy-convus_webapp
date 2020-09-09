class ApplicationController < ActionController::Base
  def append_info_to_payload(payload)
    super
    payload[:ip] = forwarded_ip_address
  end

  def forwarded_ip_address
    @forwarded_ip_address ||= ForwardedIpAddress.parse(request)
  end

  def enable_rack_profiler
    return true unless current_user&.developer?
    Rack::MiniProfiler.authorize_request unless Rails.env.test?
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || user_root_path
  end

  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end

  def github_link
    user_github_omniauth_authorize_path
  end

  helper_method :user_root_path, :github_link

  def user_root_path
    return github_link unless current_user.present?
    account_path
  end

  def redirect_to_signup_unless_user_present!
    return current_user if current_user.present?
    redirect_to github_link
    nil
  end
end
