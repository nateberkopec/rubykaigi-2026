#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "erb"
require "fileutils"

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
SLIDE_TICKS_TAG = /\A\[ticks?:\s*(\d+)(?:x)?\]\z/i
TOTAL_PRESENTATION_MS = 25 * 60 * 1000
TEMPLATE_DIR = File.expand_path("../src", __dir__)
PAGE = ERB.new(File.read(File.join(TEMPLATE_DIR, "page.html.erb")))
READING_MODE_PAGE = ERB.new(File.read(File.join(TEMPLATE_DIR, "reading_mode.html.erb")))
SLIDES_SCRIPT = ERB.new(File.read(File.join(TEMPLATE_DIR, "slides.js.erb")))

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
    content = line.delete_prefix(prefix)
    fit = content.match?(/\A\[fit\]\s+/)
    content = content.sub(/\A\[fit\]\s+/, "")
    classes = fit ? ' class="fit-heading"' : ""

    "<#{tag}#{classes}>#{parse_inline(content)}</#{tag}>"
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

def parse_slide(lines)
  ticks = 1
  lines = lines.dup

  while (match = lines.first&.strip&.match(SLIDE_TICKS_TAG))
    ticks = match[1].to_i
    lines.shift
  end

  return if lines.all? { _1.strip.empty? }

  { lines:, ticks: }
end

def parse_slides(content)
  content.split(/^\s*---\s*$/).filter_map do |slide|
    slide = slide.strip
    parse_slide(slide.lines(chomp: true)) unless slide.empty?
  end
end

def advance_durations_ms(weights)
  return [] if weights.empty?

  total_weight = weights.sum
  elapsed = 0

  weights.map do |weight|
    next_elapsed = (TOTAL_PRESENTATION_MS * (elapsed + weight)) / total_weight
    duration = next_elapsed - (TOTAL_PRESENTATION_MS * elapsed) / total_weight
    elapsed += weight
    duration
  end
end

def base_tick_ms(weights)
  return 0 if weights.empty?

  TOTAL_PRESENTATION_MS.to_f / weights.sum
end

def slide_html(index, slide, advance_ms)
  lines = slide.fetch(:lines)
  %(<div class="slide" id="slide-#{index}" data-advance-ms="#{advance_ms}"><div class="slide-content">#{render_slide(lines)}</div></div>)
end

def render_deck(input_path)
  slides = parse_slides(File.read(input_path))
  weights = slides.map { _1.fetch(:ticks) }
  durations = advance_durations_ms(weights)
  html = slides.each_with_index.map { |slide, i| slide_html(i, slide, durations.fetch(i)) }.join

  [slides.length, html, weights.sum, base_tick_ms(weights)]
end

def slides_script(mode, total)
  SLIDES_SCRIPT.result_with_hash(mode:, total:)
end

def page_html(total, slides)
  PAGE.result_with_hash(total:, slides:, script: slides_script("presentation", total))
end

def reading_mode_html(total, slides)
  READING_MODE_PAGE.result_with_hash(total:, slides:, script: slides_script("reading", total))
end

def write_artifact(total, output_path, html)
  FileUtils.mkdir_p(File.dirname(output_path))
  File.write(output_path, html)
  puts "Built #{total} slides -> #{output_path}"
end

def write_schedule_summary(total_ticks, tick_ms)
  puts format("Auto-advance tick: %.2fs (%d weighted ticks in 25:00)", tick_ms / 1000.0, total_ticks)
end

def build(input_path, output_path)
  total, slides, total_ticks, tick_ms = render_deck(input_path)
  write_schedule_summary(total_ticks, tick_ms)
  write_artifact(total, output_path, page_html(total, slides))
end

def build_artifacts(input_path, output_path)
  total, slides, total_ticks, tick_ms = render_deck(input_path)

  write_schedule_summary(total_ticks, tick_ms)
  write_artifact(total, output_path, page_html(total, slides))

  reading_mode_path = File.join(File.dirname(output_path), "reading-mode.html")
  return if File.expand_path(reading_mode_path) == File.expand_path(output_path)

  write_artifact(total, reading_mode_path, reading_mode_html(total, slides))
end

build_artifacts(ARGV[0] || "presentation.md", ARGV[1] || "dist/presentation.html") if __FILE__ == $PROGRAM_NAME
