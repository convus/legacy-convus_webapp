module AdminHelper
  def admin_nav_select_links
    [
      {title: "Dashboard", path: admin_root_path, match_controller: true},
      {title: "Content Commits", path: admin_content_commits_path, match_controller: true},
    ]
  end

  def admin_nav_select_link_active
    return @admin_nav_select_link_active if defined?(@admin_nav_select_link_active)
    @admin_nav_select_link_active = admin_nav_select_links.detect { |link| current_page_active?(link[:path], link[:match_controller]) }
  end

  def admin_nav_select_prompt
    # If there is a admin_nav_select_link_active, the prompt is for the select link
    admin_nav_select_link_active.present? ? "Viewing #{admin_nav_select_link_active[:title]}" : "Admin navigation"
  end

  def admin_nav_display_view_all?
    # If there is a admin_nav_select_link_active, and it matches controller
    return false unless admin_nav_select_link_active.present? && admin_nav_select_link_active[:match_controller]
    # If it's not the main page, we should have a display all link
    return true unless current_page_active?(admin_nav_select_link_active[:path])
    # Don't show "view all" if the path is the exact same
    return true if params[:period].present? && params[:period] != "all"
    # If there are any parameters that aren't
    ignored_keys = %w[render_chart sort period direction]
    (sortable_search_params.reject { |_k, v| v.blank? }.keys - ignored_keys).any?
  end

  def admin_number_display(number)
    content_tag(:span, number_with_delimiter(number), class: (number == 0 ? "less-less-strong" : ""))
  end
end
