#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "erb"

INLINE = [
  [/\*\*(.+?)\*\*/, '<strong>\1</strong>'],
  [/\*(.+?)\*/, '<em>\1</em>'],
  [/`(.+?)`/, '<code>\1</code>'],
  [/\[(.+?)\]\((.+?)\)/, '<a href="\2">\1</a>']
].freeze
HEADINGS = { "### " => "h3", "## " => "h2", "# " => "h1" }.freeze
LISTS = {
  ul: [/\A[-*]\s/, /\A[-*]\s+/],
  ol: [/\A\d+[.)]\s/, /\A\d+[.)]\s+/]
}.freeze
PAGE = ERB.new(File.read(File.join(__dir__, "page.html.erb")))

def parse_inline(text)
  html = INLINE.reduce(CGI.escapeHTML(text)) do |memo, (pattern, replacement)|
    memo.gsub(pattern, replacement)
  end

  html.gsub(%r{(?<!")https?://\S+}) { %(<a href="#{$&}">#{$&}</a>) }
end

def take(lines, &block)
  lines.shift(lines.take_while(&block).length)
end

def render_heading(line)
  HEADINGS.find { |prefix, _| line.start_with?(prefix) }&.then do |prefix, tag|
    "<#{tag}>#{parse_inline(line.delete_prefix(prefix))}</#{tag}>"
  end
end

def render_item(item, prefix)
  content = item.strip.sub(prefix, "")
  "  <li>#{parse_inline(content)}</li>"
end

def render_list(kind, line, lines)
  match, prefix = LISTS.fetch(kind)
  return unless line.match?(match)

  items = [line, *take(lines) { _1.strip.match?(match) }]
  body = items.map { |item| render_item(item, prefix) }.join("\n")
  "<#{kind}>\n#{body}\n</#{kind}>"
end

def render_paragraph(line, lines)
  body = [line, *take(lines) { !_1.strip.empty? }.map { _1.strip }]
  "<p>#{body.map { |text| parse_inline(text) }.join("<br>\n")}</p>"
end

def render_block(lines)
  line = lines.shift&.strip
  return if line.nil? || line.empty?

  render_heading(line) || render_list(:ul, line, lines) ||
    render_list(:ol, line, lines) || render_paragraph(line, lines)
end

def render_blocks(lines)
  Enumerator.new do |blocks|
    blocks << render_block(lines) until lines.empty?
  end
end

def render_slide(lines)
  render_blocks(lines.dup).filter_map { _1 }.join("\n")
end

def parse_slides(content)
  content.split(/^\s*---\s*$/).filter_map do |slide|
    slide = slide.strip
    slide.lines(chomp: true) unless slide.empty?
  end
end

def slide_html(index, lines)
  %(<div class="slide" id="slide-#{index}"><div class="slide-content">#{render_slide(lines)}</div></div>)
end

def page_html(total, slides)
  PAGE.result_with_hash(total:, slides:)
end

def build(input_path, output_path)
  slides = parse_slides(File.read(input_path))
  html = slides.each_with_index.map { |lines, i| slide_html(i, lines) }.join
  File.write(output_path, page_html(slides.length, html))
  puts "Built #{slides.length} slides -> #{output_path}"
end

build(ARGV[0] || "presentation.md", ARGV[1] || "presentation.html") if __FILE__ == $PROGRAM_NAME
