# markd

[![Language](https://img.shields.io/badge/language-crystal-776791.svg)](https://github.com/crystal-lang/crystal)
[![Tag](https://img.shields.io/github/tag/icyleaf/markd.svg)](https://github.com/icyleaf/markd/blob/master/CHANGELOG.md)
[![Build Status](https://img.shields.io/circleci/project/github/icyleaf/markd/master.svg?style=flat)](https://circleci.com/gh/icyleaf/markd)


**THIS PROJECT IS LOOKING FOR MAINTAINER**

Unfortunately, the maintainer no longer has the time and/or resources to work on markd further. This means that bugs will not be fixed and features will not be added unless someone else does so. 

If you're interested in fixing up markd, please [file an issue](https://github.com/icyleaf/markd/issues/new) let me know.

<hr />

Yet another markdown parser built for speed, written in [Crystal](https://crystal-lang.org), Compliant to [CommonMark](http://spec.commonmark.org) specification (`v0.29`). Copy from [commonmark.js](https://github.com/jgm/commonmark.js).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  markd:
    github: icyleaf/markd
```

## Quick start

```crystal
require "markd"

markdown = <<-MD
# Hello Markd

> Yet another markdown parser built for speed, written in Crystal, Compliant to CommonMark specification.
MD

html = Markd.to_html(markdown)
```

Also here are options to configure the parse and render.

```crystal
options = Markd::Options.new(smart: true, safe: true)
Markd.to_html(markdown, options)
```

## Options

| Name        | Type   | Default value | Description                                                                                                                                                                     |
| ----------- | ------ | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| time        | `Bool` | false         | render parse cost time during read source, parse blocks, parse inline.                                                                                                          |
| smart       | `Bool` | false         | if **true**, straight quotes will be made curly,<br />`--` will be changed to an en dash,<br />`---` will be changed to an em dash, and<br />`...` will be changed to ellipses. |
| source_pos  | `Bool` | false         | if **true**, source position information for block-level elements<br />will be rendered in the data-sourcepos attribute (for HTML)                                              |
| safe        | `Bool` | false         | if **true**, raw HTML will not be passed through to HTML output (it will be replaced by comments)                                                                               |
| prettyprint | `Bool` | false         | if **true**, code tags generated by code blocks will have a `prettyprint` class added to them, to be used by [Google code-prettify](https://github.com/google/code-prettify).   |
| gfm         | `Bool` | false         | **Not completed supported for now**                                                                                                                                                         |
| toc         | `Bool` | false         | if **true**, show a svg link to the beginning of the head tag(as github markdown does).                                                                                                                                                       |
| base_url    | `URI?` | nil           | if not **nil**, relative URLs of links are resolved against this `URI`. It act's like HTML's `<base href="base_url">` in the context of a Markdown document.                    |

## Advanced

If you want to use a custom renderer, it can!

```crystal

class CustomRenderer < Markd::Renderer

  def strong(node, entering)
  end

  # more methods following in render.
end

options = Markd::Options.new(time: true)
document = Markd::Parser.parse(markdown, options)
renderer = CustomRenderer.new(options)

html = renderer.render(document)
```

## Use tartrazine shards to render code block.

Added and require [tartrazine](https://github.com/ralsina/tartrazine) before markd will use it to render code block.

By default, it use formatter like following:

```crystal
formatter = Tartrazine::Html.new(
  theme: Tartrazine.theme("catppuccin-macchiato"),
  line_numbers: true,
  standalone: true,
)
```

You can passing a formatter instead.

e.g.

```crystal
require "tartrazine" # require it before markd
require "markd"

formatter = Tartrazine::Html.new(
  theme: Tartrazine.theme("emacs"),
  
  # Disable print line number
  line_numbers: false,
  
  # Set standalone to false for better performace.
  #
  # You need generate css file use `bin/tartrazine -f html -t "emacs" --css`, 
  # then link it in you site.
  standalone: false,
)

html = Markd.to_html(markdown,formatter: formatter)
```

If you don't care about the formatter config, you can just passing a string instead.

```crystal
require "tartrazine" # require it before markd
require "markd"

html = Markd.to_html(markdown, formatter: "emacs")
```


Currently Tartrazine supports 247 languages and [331 themes](https://github.com/ralsina/tartrazine/tree/main/styles), you can retrieve the supported languages use `Tartrazine::LEXERS_BY_NAME.values.uniq.sort`, for now the result is:

```crystal
[
  "LiquidLexer", "VelocityLexer", 
  
  "abap", "abnf", "actionscript", "actionscript_3", "ada", "agda", "al", "alloy", "angular2", 
  "antlr",   "apacheconf", "apl", "applescript", "arangodb_aql", "arduino", "armasm", 
  "autohotkey", "autoit", "awk", 
  
  "ballerina", "bash", "bash_session", "batchfile", "bbcode", "bibtex", "bicep", "blitzbasic", 
  "bnf", "bqn", "brainfuck", 
  
  "c", "c#", "c++", "cap_n_proto", "cassandra_cql", "ceylon", "cfengine3", "cfstatement", 
  "chaiscript", "chapel",   "cheetah", "clojure", "cmake", "cobol", "coffeescript", 
  "common_lisp", "coq", "crystal", "css", "cue", "cython", 
  
  "d", "dart", "dax", "desktop_entry", "diff", "django_jinja", "dns", "docker", "dtd", "dylan", 
  
  "ebnf", "elixir", "elm", "emacslisp", "erlang", 
  
  "factor", "fennel", "fish", "forth", "fortran", "fortranfixed", "fsharp", 
  
  "gas", "gdscript", "gdscript3", "gherkin", "gleam", "glsl", "gnuplot", "go_template", 
  "graphql", "groff", "groovy", 
  
  "handlebars", "hare", "haskell", "hcl", "hexdump", "hlb", "hlsl", "holyc", "html", "hy", 
  
  "idris", "igor", "ini", "io", "iscdhcpd", 
  
  "j", "java", "javascript", "json", "jsonata", "julia", "jungle", 
  
  "kotlin", 
  
  "lighttpd_configuration_file", "llvm", "lua", 
  
  "makefile", "mako", "markdown", "mason", "materialize_sql_dialect", "mathematica", "matlab", 
  "mcfunction", "meson", "metal", "minizinc", "mlir", "modula-2", "moinwiki", "monkeyc", 
  "morrowindscript", "myghty", "mysql", 
  
  "nasm", "natural", "ndisasm", "newspeak", "nginx_configuration_file", "nim", "nix", 
  
  "objective-c", "objectpascal", "ocaml", "octave", "odin", "onesenterprise", "openedge_abl", 
  "openscad", "org_mode", 
  
  "pacmanconf", "perl", "php", "pig", "pkgconfig", "pl_pgsql", "plaintext", "plutus_core", 
  "pony", "postgresql_sql_dialect", "postscript", "povray", "powerquery", "powershell", 
  "prolog", "promela", "promql", "properties", "protocol_buffer",   "prql", "psl", "puppet", 
  "python", "python_2", 
  
  "qbasic", "qml", 
  
  "r", "racket", "ragel", "react", "reasonml", "reg", "rego", "rexx", "rpm_spec", "rst", 
  "ruby", "rust", 
  
  "sas", "sass", "scala", "scheme", "scilab", "scss", "sed", "sieve", "smali", "smalltalk", 
  "smarty", "snobol", "solidity", "sourcepawn", "sparql", "sql", "squidconf", "standard_ml", 
  "stas", "stylus", "swift", "systemd", "systemverilog", 
  
  "tablegen", "tal", "tasm", "tcl", "tcsh", "termcap", "terminfo", "terraform", "tex", 
  "thrift",  "toml", "tradingview", "transact-sql", "turing", "turtle", "twig", "typescript", 
  "typoscript", "typoscriptcssdata", "typoscripthtmldata", 
  
  "ucode", 
  
  "v", "v_shell", "vala", "vb_net", "verilog", "vhdl", "vhs", "viml", "vue", "wdte", 
  
  "webgpu_shading_language", "whiley", 
  
  "xml", "xorg", 
  
  "yaml", "yang", "z80_assembly", 
  
  "zed", "zig"
]
```

For details usage, check [tartrazine](https://github.com/ralsina/tartrazine) documents.

## Performance

Here is the result of [a sample markdown file](benchmarks/source.md) parse at MacBook Pro Retina 2015 (2.2 GHz):

```
Crystal Markdown (no longer present)   3.28k (305.29µs) (± 0.92%)       fastest
           Markd                       305.36 (  3.27ms) (± 5.52%) 10.73× slower
```

Recently, I'm working to compare the other popular commonmark parser, the code is stored in [benchmarks](/benchmarks).

## How to Contribute

Your contributions are always welcome! Please submit a pull request or create an issue to add a new question, bug or feature to the list.

All [Contributors](https://github.com/icyleaf/markd/graphs/contributors) are on the wall.

## You may also like

- [halite](https://github.com/icyleaf/halite) - HTTP Requests Client with a chainable REST API, built-in sessions and middlewares.
- [totem](https://github.com/icyleaf/totem) - Load and parse a configuration file or string in JSON, YAML, dotenv formats.
- [poncho](https://github.com/icyleaf/poncho) - A .env parser/loader improved for performance.
- [popcorn](https://github.com/icyleaf/popcorn) - Easy and Safe casting from one type to another.
- [fast-crystal](https://github.com/icyleaf/fast-crystal) - 💨 Writing Fast Crystal 😍 -- Collect Common Crystal idioms.

## License

[MIT License](https://github.com/icyleaf/markd/blob/master/LICENSE) © icyleaf
