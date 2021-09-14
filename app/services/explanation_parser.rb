class ExplanationParser
  def self.quote_split_url(str, url = nil)
    lines = str.split("\n").map(&:strip)
    # parse out URLs started with ref: or reference:
    if lines.last.match?(/ref(erence)?:[^\z]/i)
      url = lines.pop.gsub(/ref(erence)?:/i, "").strip
    end
    {quote: lines.join("\n"), url: url}
  end

  # Should duplicate parsing logic of parseExplanationQuotes in explanation_form.js
  def self.text_nodes(text, urls: [])
    nodes = []
    return nodes unless text.present?
    quote_index = -1
    last_quote_line = nil
    text.split("\n").each_with_index do |line, index|
      line.strip!
      # match lines that are blockquotes
      if line.match?(/\A\s*>/)
        # remove the >, trim the string,
        quote_text = line.gsub(/\A\s*>\s*/, "").strip
        # We need to group consecutive lines, because that's how markdown parses
        # So check if the last line was a quote and if so, update it
        if last_quote_line == (index - 1)
          quote_node = nodes.pop
          quote_text = [quote_node[:quote], quote_text].join("\n ")
        else
          quote_index += 1
        end
        new_node = quote_split_url(quote_text, urls[quote_index])
        last_quote_line = index
      else
        new_node = if nodes.last&.is_a?(String) # We're in a text block
          [nodes.pop, line].join("\n")
        else # start of a new text block
          line
        end
        last_quote_line = nil
      end
      nodes.push(new_node)
    end
    nodes
  end

  def self.markdown
    @markdown ||= Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(no_images: true, no_links: true, filter_html: true),
      {no_intra_emphasis: true, tables: true, fenced_code_blocks: true, strikethrough: true,
       superscript: true, lax_spacing: true}
    )
  end

  def self.text_to_html(str)
    return "" unless str.present?
    markdown.render(str.strip)
      .gsub(/(<\/?)h\d+/i, '\1p') # Remove header open brackets and close brackets
  end

  def initialize(explanation: nil)
    @explanation = explanation
  end

  def parse_text_nodes(urls: nil)
    urls ||= @explanation.explanation_quotes.not_removed.order(:ref_number).pluck(:url)
    self.class.text_nodes(@explanation.text, urls: urls)
  end

  def text_nodes
    @text_nodes ||= parse_text_nodes
  end

  def text_with_references
    text_nodes.map do |node|
      next node if node.is_a?(String)
      str = node[:quote].split("\n").map { |l| "> #{l}" }.join("\n")
      "#{str}\n> ref:#{node[:url]}" # no whitespace in between to avoid line breaks on GitHub display
    end.join("\n\n").gsub("\n\n\n", "\n\n") # Probably can do better than this gsub...
  end

  # This is what is stored in the database, in explanation#text
  def text_no_references
    text_nodes.map do |node|
      if node.is_a?(String)
        node
      else
        node[:quote].split("\n").map { |l| "> #{l}" }.join("\n")
      end
    end.join("\n\n").gsub("\n\n\n", "\n\n") # Same as above, could do better
  end
end
