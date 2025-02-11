require "uri"

module Markd
  class HTMLRenderer < Renderer
    @disable_tag = 0
    @last_output = "\n"

    @strong_stack = 0

    HEADINGS = %w(h1 h2 h3 h4 h5 h6)

    def heading(node : Node, entering : Bool)
      tag_name = HEADINGS[node.data["level"].as(Int32) - 1]
      if entering
        newline
        tag(tag_name, attrs(node))
        toc(node) if @options.toc
      else
        tag(tag_name, end_tag: true)
        newline
      end
    end

    def code(node : Node, entering : Bool)
      tag("code") do
        code_body(node)
      end
    end

    def code_body(node : Node)
      output(node.text)
    end

    def code_block(node : Node, entering : Bool, formatter : T?) forall T
      {% if @top_level.has_constant?("Tartrazine") %}
        render_code_block_use_tartrazine(node, formatter)
      {% else %}
        render_code_block_use_code_tag(node)
      {% end %}
    end

    def code_block_language(languages)
      languages.try(&.first?).try(&.strip.presence)
    end

    def code_block_body(node : Node, lang : String?)
      output(node.text)
    end

    def thematic_break(node : Node, entering : Bool)
      newline
      tag("hr", attrs(node), self_closing: true)
      newline
    end

    def block_quote(node : Node, entering : Bool)
      newline
      if entering
        tag("blockquote", attrs(node))
      else
        tag("blockquote", end_tag: true)
      end
      newline
    end

    def list(node : Node, entering : Bool)
      tag_name = node.data["type"] == "ordered" ? "ol" : "ul"

      newline
      if entering
        attrs = attrs(node)

        if (start = node.data["start"].as(Int32)) && start != 1
          attrs ||= {} of String => String
          attrs["start"] = start.to_s
        end

        tag(tag_name, attrs)
      else
        tag(tag_name, end_tag: true)
      end
      newline
    end

    def item(node : Node, entering : Bool)
      if entering
        tag("li", attrs(node))

        if node.data["type"] == "checkbox"
          if node.data["checked"]?
            attributes = {
              "checked"  => "",
              "disabled" => "",
              "type"     => "checkbox",
            }
          else
            attributes = {
              "disabled" => "",
              "type"     => "checkbox",
            }
          end

          tag("input", attributes)
          literal(" ")
        end
      else
        tag("li", end_tag: true)
        newline
      end
    end

    def link(node : Node, entering : Bool)
      if entering
        attrs = attrs(node)
        destination = node.data["destination"].as(String)

        unless @options.safe? && potentially_unsafe(destination)
          attrs ||= {} of String => String
          destination = resolve_uri(destination, node)
          attrs["href"] = escape(destination)
        end

        if (title = node.data["title"].as(String)) && !title.empty?
          attrs ||= {} of String => String
          attrs["title"] = escape(title)
        end

        tag("a", attrs)
      else
        tag("a", end_tag: true)
      end
    end

    private def resolve_uri(destination, node)
      base_url = @options.base_url
      return destination unless base_url

      uri = URI.parse(destination)
      return destination if uri.absolute?

      base_url.resolve(uri).to_s
    end

    def image(node : Node, entering : Bool)
      if entering
        if @disable_tag == 0
          destination = node.data["destination"].as(String)
          if @options.safe? && potentially_unsafe(destination)
            literal(%(<img src="" alt=""))
          else
            destination = resolve_uri(destination, node)
            literal(%(<img src="#{escape(destination)}" alt="))
          end
        end
        @disable_tag += 1
      else
        @disable_tag -= 1
        if @disable_tag == 0
          if (title = node.data["title"].as(String)) && !title.empty?
            literal(%(" title="#{escape(title)}))
          end
          literal(%(" />))
        end
      end
    end

    def html_block(node : Node, entering : Bool)
      newline
      content = @options.safe? ? "<!-- raw HTML omitted -->" : node.text
      literal(content)
      newline
    end

    def html_inline(node : Node, entering : Bool)
      content = @options.safe? ? "<!-- raw HTML omitted -->" : node.text
      literal(content)
    end

    def paragraph(node : Node, entering : Bool)
      if (grand_parent = node.parent?.try &.parent?) && grand_parent.type.list?
        return if grand_parent.data["tight"]
      end

      if entering
        newline
        tag("p", attrs(node))
      else
        tag("p", end_tag: true)
        newline
      end
    end

    def emphasis(node : Node, entering : Bool)
      if entering
        node.data["strong_stack"] = @strong_stack
        @strong_stack = 0
      end

      tag("em", end_tag: !entering)

      if !entering
        @strong_stack = node.data["strong_stack"].as(Int32)
      end
    end

    def soft_break(node : Node, entering : Bool)
      literal("\n")
    end

    def line_break(node : Node, entering : Bool)
      tag("br", self_closing: true)
      newline
    end

    def strong(node : Node, entering : Bool)
      @strong_stack -= 1 if @options.gfm && !entering

      tag("strong", end_tag: !entering) if (@strong_stack == 0)

      @strong_stack += 1 if @options.gfm && entering
    end

    def strikethrough(node : Node, entering : Bool)
      tag("del", end_tag: !entering)
    end

    def text(node : Node, entering : Bool)
      output(node.text)
    end

    private def tag(name : String, attrs = nil, self_closing = false, end_tag = false)
      return if @disable_tag > 0

      @output_io << "<"
      @output_io << "/" if end_tag
      @output_io << name
      attrs.try &.each do |key, value|
        @output_io << ' ' << key << '=' << '"' << value << '"'
      end

      @output_io << " /" if self_closing
      @output_io << ">"
      @last_output = ">"
    end

    private def tag(name : String, attrs = nil, &)
      tag(name, attrs)
      yield
      tag(name, end_tag: true)
    end

    private def potentially_unsafe(url : String)
      url.match(Rule::UNSAFE_PROTOCOL) && !url.match(Rule::UNSAFE_DATA_PROTOCOL)
    end

    private def toc(node : Node)
      return unless node.type.heading?

      link_svg = <<-'HEREDOC'
<svg class="octicon octicon-link" viewBox="0 0 16 16" version="1.1" width="16" height="16" aria-hidden="true"><path d="m7.775 3.275 1.25-1.25a3.5 3.5 0 1 1 4.95 4.95l-2.5 2.5a3.5 3.5 0 0 1-4.95 0 .751.751 0 0 1 .018-1.042.751.751 0 0 1 1.042-.018 1.998 1.998 0 0 0 2.83 0l2.5-2.5a2.002 2.002 0 0 0-2.83-2.83l-1.25 1.25a.751.751 0 0 1-1.042-.018.751.751 0 0 1-.018-1.042Zm-4.69 9.64a1.998 1.998 0 0 0 2.83 0l1.25-1.25a.751.751 0 0 1 1.042.018.751.751 0 0 1 .018 1.042l-1.25 1.25a3.5 3.5 0 1 1-4.95-4.95l2.5-2.5a3.5 3.5 0 0 1 4.95 0 .751.751 0 0 1-.018 1.042.751.751 0 0 1-1.042.018 1.998 1.998 0 0 0-2.83 0l-2.5 2.5a1.998 1.998 0 0 0 0 2.83Z"></path></svg>
HEREDOC
      {% if compare_versions(Crystal::VERSION, "1.2.0") < 0 %}
        title = URI.encode(node.first_child.text)
        @output_io << %(<a id="anchor-) << title << %(" class="anchor" href="#anchor-) << title << %(">) << link_svg << %( </a>)
      {% else %}
        title = URI.encode_path(node.first_child.text)
        @output_io << %(<a id="anchor-) << title << %(" class="anchor" href="#anchor-) << title << %(">) << link_svg << %( </a>)
      {% end %}
      @last_output = ">"
    end

    private def attrs(node : Node)
      if @options.source_pos? && (pos = node.source_pos)
        {"data-source-pos" => "#{pos[0][0]}:#{pos[0][1]}-#{pos[1][0]}:#{pos[1][1]}"}
      else
        nil
      end
    end

    private def render_code_block_use_tartrazine(node : Node, formatter : Tartrazine::Formatter?)
      languages = node.fence_language ? node.fence_language.split : nil
      lang = code_block_language(languages)

      newline

      if lang
        lexer = Tartrazine.lexer(lang)

        literal(formatter.format(node.text.chomp, lexer))
      else
        code_tag_attrs = attrs(node)
        pre_tag_attrs = if @options.prettyprint?
                          {"class" => "prettyprint"}
                        else
                          nil
                        end

        tag("pre", pre_tag_attrs) do
          tag("code", code_tag_attrs) do
            code_block_body(node, lang)
          end
        end
      end

      newline
    end

    private def render_code_block_use_code_tag(node : Node)
      languages = node.fence_language ? node.fence_language.split : nil
      code_tag_attrs = attrs(node)
      pre_tag_attrs = if @options.prettyprint?
                        {"class" => "prettyprint"}
                      else
                        nil
                      end

      lang = code_block_language(languages)
      if lang
        code_tag_attrs ||= {} of String => String
        code_tag_attrs["class"] = "language-#{escape(lang)}"
      end

      newline
      tag("pre", pre_tag_attrs) do
        tag("code", code_tag_attrs) do
          code_block_body(node, lang)
        end
      end
      newline
    end
  end
end
