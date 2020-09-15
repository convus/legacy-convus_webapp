module ApplicationHelper
  def check_mark
    "&#x2713;".html_safe
  end

  def link_emoji(link_title = nil)
    content_tag(:span, title: link_title || "link") do
      content_tag(:span, "🔗", class: "emoji") +
        content_tag(:small, " link")
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
end
