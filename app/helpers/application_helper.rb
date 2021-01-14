module ApplicationHelper
  def page_title
    return @page_title if @page_title
    [default_action_name_title, controller_title_for_action].compact.join(" ")
  end

  def check_mark
    "&#x2713;".html_safe
  end

  def internal_link_text(link_title = nil)
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

  def hypothesis_link_to(*args, &block)
    if block
      options = args.first || {}
      html_options = args[1]
      concat(hypothesis_link_to(capture(&block), options, html_options))
    else
      obj_id = args[1]
      html_options = args[2] || {}
      hypothesis = Hypothesis.friendly_find(obj_id)
      html_options[:title] = hypothesis.title if hypothesis.present?
      link_to args[0], hypothesis_path(obj_id), html_options
    end
  end

  def citation_link_to(*args, &block)
    if block
      options = args.first || {}
      html_options = args[1]
      concat(citation_link_to(capture(&block), options, html_options))
    else
      obj_id = args[1]
      html_options = args[2] || {}
      citation = Citation.friendly_find(obj_id)
      html_options[:title] = citation.display_title if citation.present?
      link_to args[0], citation_path(obj_id), html_options
    end
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

  def sortable(column, title = nil, html_options = {})
    title ||= column.gsub(/_(id|at)\z/, "").titleize
    html_options[:class] = "#{html_options[:class]} sortable-link"
    direction = column == sort_column && sort_direction == "desc" ? "asc" : "desc"
    if column == sort_column
      html_options[:class] += " active"
      span_content = direction == "asc" ? "\u2193" : "\u2191"
    end
    link_to(sortable_search_params.merge(sort: column, direction: direction, query: params[:query], user_id: params[:user_id]), html_options) do
      concat(title.html_safe)
      concat(content_tag(:span, span_content, class: "sortable-direction"))
    end
  end

  def sortable_search_params
    search_param_keys = params.keys.select { |k| k.to_s.start_with?(/search_/i) }
    # NOTE: with permitted params, to permit an array, you have to pass it with special syntax
    # ... so for now, arrays need to be in the search_array parameter. TODO: improve this
    params.permit(:direction, :sort, :period, :start_time, :end_time, :render_chart,
      :query, *search_param_keys, search_array: [])
  end

  def sortable_search_params?
    sortable_search_params.values.reject(&:blank?).any?
  end

  def display_true_or_false(t_or_f)
    if !t_or_f
      content_tag(:span, "False", class: "less-strong")
    else
      content_tag(:span, "True")
    end
  end

  def hypothesis_score_class(score)
    if score > 17
      "score-very-high"
    elsif score > 11
      "score-high"
    elsif score > 5
      "score-medium"
    else
      "score-low"
    end
  end

  def link_to_add_fields(name, f, association, html_options = {}, obj_attrs: {}, filename: nil, &block)
    new_object = f.object.send(association).klass.new(obj_attrs)
    id = new_object.object_id
    filename ||= association.to_s.singularize + "_fields"
    fields = f.fields_for(association, new_object, child_index: id) { |builder|
      render(filename, f: builder)
    }
    # And then set the html options we need
    html_options[:class] ||= ""
    html_options[:class] = html_options[:class] + " add-fields"
    html_options[:data] ||= {}
    html_options[:data].merge!(id: id, fields: fields.delete("\n"))
    # Use button, so that pressing spacebar when focused on it works
    content_tag(:button, name, html_options)
  end

  # This is required by both hypothesis#new and edit, so make it consistent
  def citations_block_attributes
    {:id => "citationsBlock",
     "data-ckinds" => Citation.kinds.join(","),
     "data-cresearchkinds" => Citation.kinds_research.join(",")}
  end

  def in_admin?
    controller_namespace == "admin"
  end

  # Refactor and remove this!
  def bootstrap_devise_error_messages!
    return "" if resource.errors.empty?

    messages = resource.errors.full_messages.map { |message| content_tag(:li, message) }.join
    sentence = I18n.t(
      "errors.messages.not_saved",
      count: resource.errors.count,
      resource: resource.class.model_name.human.downcase
    )

    html = <<-HTML
    <div class="alert alert-danger">
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
      <h4 class="alert-heading">#{sentence}</h4>
      <ul class="mb-0">#{messages}</ul>
    </div>
    HTML

    html.html_safe
  end

  def pretty_print_json(data)
    require "coderay"
    CodeRay.scan(JSON.pretty_generate(data), :json).div.html_safe
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
