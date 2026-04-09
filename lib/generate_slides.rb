#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"

INPUT_PATH = Pathname(ARGV[0] || "OUTLINE.md")
OUTPUT_PATH = Pathname(ARGV[1] || "presentation.md")
STOP_HEADING = "REMAINING RESEARCH HOURS"

TITLE_SLIDE = <<~MARKDOWN
  ---

  [slide-skin:descent]
  # [fit] Autoresearching Ruby Performance with LLMs

  **Nate Berkopec**

  RubyKaigi 2026
MARKDOWN

def heading_title(text)
  match = text.match(/^\*\*(.+?)\*\*\s*(.*)$/)
  match ? match[1].strip : text.strip
end

def top_slide(text, fit: false)
  match = text.match(/^\*\*(.+?)\*\*\s*(.*)$/)

  if match
    title, rest = match.captures
    prefix = fit ? "# [fit]" : "#"
    lines = ["#{prefix} #{title.strip}"]
    lines += ["", rest.strip] unless rest.strip.empty?
    return lines.join("\n")
  end

  prefix = fit || text.strip.length > 50 ? "# [fit]" : "#"
  "#{prefix} #{text.strip}"
end

def item_level(indent)
  spaces = indent.length
  return 0 if spaces.zero?
  return 1 if spaces <= 4

  2
end

def outline_item(line)
  line.match(/^(\s*)-\s*(.*?)\s*$/)&.then do |match|
    indent, text = match.captures
    { indent:, text:, level: item_level(indent) }
  end
end

def ancestor_headings(stack)
  stack.map.with_index(1) do |item, depth|
    ["#" * [depth, 3].min + " #{item[:title]}", ""]
  end.flatten
end

def normalize_content_lines(lines)
  trimmed = lines.map(&:rstrip)
  trimmed.shift while trimmed.first&.strip.to_s.empty?
  trimmed.pop while trimmed.last&.strip.to_s.empty?
  return [] if trimmed.empty?

  indent = trimmed.reject { _1.strip.empty? }.map { _1[/\A */].length }.min || 0
  trimmed.map { |line| line[indent..] || "" }
end

def next_child_item(lines, start_index, parent_level)
  lines[(start_index + 1)..]&.each do |line|
    break if line.strip == STOP_HEADING

    item = outline_item(line)
    next unless item

    return item if item[:level] > parent_level
    return nil
  end

  nil
end

unless INPUT_PATH.exist?
  warn "Missing input file: #{INPUT_PATH}"
  exit 1
end

slides = [TITLE_SLIDE.strip]
stack = []
lines = INPUT_PATH.read.each_line.map(&:chomp)
index = 0

while index < lines.length
  line = lines[index]
  break if line.strip == STOP_HEADING

  item = outline_item(line)
  unless item
    index += 1
    next
  end

  level = item[:level]
  text = item[:text]

  stack.pop while stack.any? && stack.last[:level] >= level

  if text.empty?
    content_lines = []
    index += 1

    while index < lines.length
      content_line = lines[index]
      break if content_line.strip == STOP_HEADING

      nested_item = outline_item(content_line)
      break if nested_item && nested_item[:level] <= level

      content_lines << content_line
      index += 1
    end

    content = normalize_content_lines(content_lines)
    unless content.empty?
      slides << ["---", "", *ancestor_headings(stack), *content].join("\n")
    end

    next
  end

  slide = if level.zero?
    fit = next_child_item(lines, index, level)&.fetch(:text, nil).to_s.empty?
    ["---", "", top_slide(text, fit:).strip].join("\n")
  else
    current_heading = "#" * [level + 1, 3].min
    ["---", "", *ancestor_headings(stack), "#{current_heading} #{text.strip}"].join("\n")
  end

  slides << slide
  stack << { level:, title: heading_title(text) }
  index += 1
end

OUTPUT_PATH.write(slides.join("\n\n") + "\n")
puts "Wrote #{OUTPUT_PATH} with #{slides.length} slides from #{INPUT_PATH}"
