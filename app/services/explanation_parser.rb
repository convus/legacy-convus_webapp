class ExplanationParser
  # Duplicates parseExplanationQuotes in explanation_form.js
  def self.quotes(text)
    matching_lines = []
    last_quote_line = nil
    text.split("\n").each_with_index do |line, index|
      # match lines that are blockquotes
      if line.match?(/\A\s*>/)
        # remove the >, trim the string,
        quote_text = line.gsub(/\A\s*>\s*/, "").strip
        # We need to group consecutive lines, because that's how markdown parses
        # So check if the last line was a quote and if so, update it
        if last_quote_line == (index - 1)
          quote_text = [matching_lines.pop, quote_text].join("\n ")
        end
        matching_lines.push(quote_text)
        last_quote_line = index
      end
    end
    # - remove duplicates & ignore any empty quotes
    matching_lines.uniq.reject(&:blank?)
  end

  def self.quotes_with_urls(text, urls: [])
    quotes(text).each_with_index.map do |quote, i|
      quote_split_url(quote, urls[i])
    end
  end

  def self.quote_split_url(str, url = nil)
    lines = str.split("\n").map(&:strip)
    if lines.last.match?(/reference:[^\z]/i)
      url = lines.pop.gsub(/reference:/i, "").strip
    end
    {text: lines.join(" "), url: url}
  end

  def self.markdown
    Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(no_images: true, no_links: true, filter_html: true),
      {no_intra_emphasis: true, tables: true, fenced_code_blocks: true, strikethrough: true,
       superscript: true, lax_spacing: true}
    )
  end

  def initialize(explanation: nil, text_nodes: nil)
    @explanation = explanation
    @text_nodes = text_nodes
  end

  attr_reader :reparse_text_nodes, :text_nodes

  def parse_text_nodes

  end

  def parse_quotes

  end

  def to_nodes

  end

  def text_with_references
    @explanation.text
  end

  # This is what is stored in the database, in explanation#text
  def to_markdown_no_references

  end

  def to_body_html

  end
end
