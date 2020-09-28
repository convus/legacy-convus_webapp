module ApplicationHelper
  def page_title
    return @page_title if @page_title
    [default_action_name_title, controller_title_for_action].compact.join(" ")
  end

  def check_mark
    "&#x2713;".html_safe
  end

  def internal_link(link_title = nil)
    content_tag(:span, title: link_title || "link") do
      content_tag(:span, "view", class: "emoji")
    end
  end

  def active_link(link_text, link_path, html_options = {})
    match_controller = html_options.delete(:match_controller)
    html_options[:class] ||= ""
    html_options[:class] += " active" if current_page_active?(link_path, match_controller)
    link_to(raw(link_text), link_path, html_options).html_safe
  end

  def current_page_active?(link_path, match_controller = false)
    link_path = Rails.application.routes.recognize_path(link_path)
    active_path = Rails.application.routes.recognize_path(request.url)
    matches_controller = active_path[:controller] == link_path[:controller]
    return true if match_controller && matches_controller
    current_page?(link_path) || matches_controller && active_path[:action] == link_path[:action]
  rescue # This mainly fails in testing - but why not rescue always
    false
  end

  def sortable_search_params
    search_param_keys = params.keys.select { |k| k.to_s.start_with?(/search_/i) }
    # NOTE: with permitted params, to permit searching an array, you have to pass it in specifically
    # ... for now, it needs to be in the search_array parameter - TODO: improve this
    params.permit(:direction, :sort, :period, :start_time, :end_time, :render_chart,
      :query, *search_param_keys, search_array: [])
  end

  def sortable_search_params?
    sortable_search_params.values.reject(&:blank?).any?
  end

  private

  def default_action_name_title
    return "Display" if action_name == "show"
    action_name == "index" ? "" : action_name.titleize
  end

  def controller_title_for_action
    return controller_name.titleize if %(index).include?(action_name)
    controller_name.singularize.titleize
  end
end
