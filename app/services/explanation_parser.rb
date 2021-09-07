class ExplanationParser
  def self.parse_quotes(text, urls: nil)

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

  # This is what is stored in the database, in explanation#text
  def to_markdown_no_references

  end

  def to_body_html

  end
end
