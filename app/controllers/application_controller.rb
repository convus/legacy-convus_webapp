class ApplicationController < ActionController::Base
  before_action :enable_rack_profiler

  before_action do
    if Rails.env.production? && current_user.present?
      Honeybadger.context(user_id: current_user.id, user_email: current_user.email)
    end
  end

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

  def display_dev_info?
    return @display_dev_info if defined?(@display_dev_info)
    # Tie display_dev_info to the rack mini profiler display
    @display_dev_info = !Rails.env.test? && current_user&.developer? &&
      Rack::MiniProfiler.current.present?
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

  helper_method :display_dev_info?, :user_root_path, :github_link, :tag_titles

  def tag_titles
    @tag_titles ||= Tag.approved.pluck(:title)
  end

  def user_root_path
    return @user_root_path if defined?(@user_root_path)
    return @user_root_path = new_user_session_path if current_user.blank?
    @user_root_path = account_path
  end

  def redirect_to_signup_unless_user_present!
    return current_user if current_user.present?
    store_return_to
    redirect_to new_user_session_path
    nil
  end

  def store_return_to
    return if not_stored_paths.include?(request.path) || request.xhr?
    if request.path == "/user_scores" && params[:hypothesis_id].present?
      session[:after_sign_in_score] = "#{params[:hypothesis_id]},#{params[:score]},#{params[:kind]}"
      session[:user_return_to] = hypothesis_path(params[:hypothesis_id])
    else
      session[:user_return_to] = request.path
    end
  end

  def not_stored_paths
    ["/users/sign_in", "/users/sign_up", "/users/password", "/users/sign_out"]
  end
end
