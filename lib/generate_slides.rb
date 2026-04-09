#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"

INPUT_PATH = Pathname(ARGV[0] || "OUTLINE.md")
OUTPUT_PATH = Pathname(ARGV[1] || "presentation.md")
STOP_HEADING = "REMAINING RESEARCH HOURS"

TITLE_SLIDE = <<~MARKDOWN
  ---

  # [fit] Autoresearching Ruby Performance with LLMs

  **Nate Berkopec**

  RubyKaigi 2026
MARKDOWN

def heading_title(text)
  match = text.match(/^\*\*(.+?)\*\*\s*(.*)$/)
  match ? match[1].strip : text.strip
end

def top_slide(text)
  match = text.match(/^\*\*(.+?)\*\*\s*(.*)$/)

  if match
    title, rest = match.captures
    lines = ["# #{title.strip}"]
    lines += ["", rest.strip] unless rest.strip.empty?
    return lines.join("\n")
  end

  prefix = text.strip.length > 50 ? "# [fit]" : "#"
  "#{prefix} #{text.strip}"
end

def item_level(indent)
  spaces = indent.length
  return 0 if spaces.zero?
  return 1 if spaces <= 4

  2
end

unless INPUT_PATH.exist?
  warn "Missing input file: #{INPUT_PATH}"
  exit 1
end

slides = [TITLE_SLIDE.strip]
stack = []

INPUT_PATH.read.each_line do |raw_line|
  line = raw_line.chomp
  break if line.strip == STOP_HEADING

  match = line.match(/^(\s*)-\s+(.*\S)\s*$/)
  next unless match

  indent, text = match.captures
  level = item_level(indent)

  stack.pop while stack.any? && stack.last[:level] >= level

  slide = if level.zero?
    ["---", "", top_slide(text).strip].join("\n")
  else
    ancestors = stack.map.with_index(1) do |item, depth|
      ["#" * [depth, 3].min + " #{item[:title]}", ""]
    end.flatten

    current_heading = "#" * [level + 1, 3].min
    ["---", "", *ancestors, "#{current_heading} #{text.strip}"].join("\n")
  end

  slides << slide
  stack << { level:, title: heading_title(text) }
end

OUTPUT_PATH.write(slides.join("\n\n") + "\n")
puts "Wrote #{OUTPUT_PATH} with #{slides.length} slides from #{INPUT_PATH}"
