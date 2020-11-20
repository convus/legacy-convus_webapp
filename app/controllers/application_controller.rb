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

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || user_root_path
  end

  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end

  helper_method :display_dev_info?, :user_root_path, :github_link, :tag_titles, :controller_namespace

  def display_dev_info?
    return @display_dev_info if defined?(@display_dev_info)
    # Tie display_dev_info to the rack mini profiler display
    @display_dev_info = !Rails.env.test? && current_user&.developer? &&
      Rack::MiniProfiler.current.present?
  end

  def github_link
    user_github_omniauth_authorize_path
  end

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

  # For setting periods, particularly for graphing
  def set_period
    set_timezone
    # Set time period
    @period ||= params[:period]
    if @period == "custom"
      if params[:start_time].present?
        @start_time = TimeParser.parse(params[:start_time], @timezone)
        @end_time = TimeParser.parse(params[:end_time], @timezone) || Time.current
        if @start_time > @end_time
          new_end_time = @start_time
          @start_time = @end_time
          @end_time = new_end_time
        end
      else
        set_time_range_from_period
      end
    else
      set_time_range_from_period
    end
    @time_range = @start_time..@end_time
  end

  def controller_namespace
    @controller_namespace ||= self.class.module_parent.name != "Object" ? self.class.module_parent.name.downcase : nil
  end

  private

  def store_return_to
    return if request.xhr? || not_stored_paths.include?(request.path)
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

    def set_time_range_from_period
    @period = default_period unless %w[hour day month year week all next_week next_month].include?(@period)
    case @period
    when "hour"
      @start_time = Time.current - 1.hour
    when "day"
      @start_time = Time.current.beginning_of_day - 1.day
    when "month"
      @start_time = Time.current.beginning_of_day - 30.days
    when "year"
      @start_time = Time.current.beginning_of_day - 1.year
    when "week"
      @start_time = Time.current.beginning_of_day - 1.week
    when "next_month"
      @start_time ||= Time.current
      @end_time = Time.current.beginning_of_day + 30.days
    when "next_week"
      @start_time = Time.current
      @end_time = Time.current.beginning_of_day + 1.week
    when "all"
      @start_time = earliest_period_date
    end
    @end_time ||= latest_period_date
  end

  # Separate method so it can be overridden on per controller basis
  def default_period
    "all"
  end

  # Separate method so it can be overriden, specifically in invoices
  def latest_period_date
    Time.current
  end

  def set_timezone
    return true if @timezone.present?
    # Parse the timezone params if they are passed (tested in admin#activity_groups#index)
    if params[:timezone].present?
      @timezone = TimeParser.parse_timezone(params[:timezone])
      # If it's a valid timezone, save to session
      session[:timezone] = @timezone&.name
    end
    # Set the timezone on a per request basis if we have a timezone saved
    if session[:timezone].present?
      @timezone ||= TimeParser.parse_timezone(session[:timezone])
      Time.zone = @timezone
    end
    @timezone ||= TimeParser::DEFAULT_TIMEZONE
  end

  # Separate method so it can be overriden
  def earliest_period_date
    Time.at(1599616770) # right before first user created_at
  end
end
