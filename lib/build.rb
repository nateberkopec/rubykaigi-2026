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
SLIDE_SKIN_TAG = /\A\[slide-skin:\s*([a-z0-9_-]+)\]\z/i
TOTAL_PRESENTATION_MS = 25 * 60 * 1000
TEMPLATE_DIR = File.expand_path("../src", __dir__)
RUBYKAIGI_HORIZONTAL_LOGO_SVG = File.expand_path(
  "../tmp/rubykaigi-2026-graphics-kit/Logo/SVG/Logo-RubyKaigi2026-Horizontal-White.svg",
  __dir__
)
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

def heading_text(line)
  HEADINGS.find { |prefix, _| line.start_with?(prefix) }&.then do |prefix, _tag|
    line.delete_prefix(prefix).sub(/\A\[fit\]\s+/, "").strip
  end
end

def descent_slide_copy(lines)
  title = nil
  details = []

  lines.each do |line|
    stripped = line.strip
    next if stripped.empty?

    if title.nil? && (text = heading_text(stripped))
      title = text
      next
    end

    details << stripped.sub(/\A#+\s+/, "")
  end

  {
    title: parse_inline(title || "Autoresearching Ruby Performance with LLMs"),
    author: parse_inline(details[0] || "Nate Berkopec"),
    event: parse_inline(details[1] || "RubyKaigi 2026"),
    subtitle: parse_inline(details[2..]&.join(" ").to_s)
  }
end

def rubykaigi_horizontal_logo_paths
  @rubykaigi_horizontal_logo_paths ||= begin
    if File.exist?(RUBYKAIGI_HORIZONTAL_LOGO_SVG)
      File.read(RUBYKAIGI_HORIZONTAL_LOGO_SVG).scan(/<path\b[^>]*\/>/)
    else
      []
    end
  end
end

def rubykaigi_svg_current_color(path)
  path.gsub(/fill="[^"]+"/, 'fill="currentColor"')
end

def rubykaigi_wordmark_svg
  paths = rubykaigi_horizontal_logo_paths[0...-1]
  return '<span class="descent-rubykaigi-wordmark-fallback">RubyKaigi 2026</span>' if paths.empty?

  <<~SVG.delete("\n")
    <svg class="descent-rubykaigi-wordmark" viewBox="223 61 729 102" role="img" aria-label="RubyKaigi 2026" xmlns="http://www.w3.org/2000/svg">
      #{paths.map { rubykaigi_svg_current_color(_1) }.join}
    </svg>
  SVG
end

def rubykaigi_star_path
  star_path = rubykaigi_horizontal_logo_paths.last.to_s
  star_path[/d="([^"]+)"/, 1].to_s
end

def render_descent_slide(slide)
  copy = descent_slide_copy(slide.fetch(:lines))
  subtitle = copy.fetch(:subtitle)
  subtitle_html = subtitle.empty? ? "" : %(<p class="descent-subtitle">#{subtitle}</p>)

  <<~HTML.delete("\n")
    <div class="slide-content descent-shell">
      <div class="descent-canvas-wrap"><canvas class="descent-stage" aria-hidden="true"></canvas></div>
      <div class="descent-scanlines" aria-hidden="true"></div>
      <div class="descent-ui">
        <header class="descent-header">
          <div class="descent-header-title">RUBY AUTORESEARCH // PERFORMANCE DESCENT</div>
          <div class="descent-sys-status">
            <div>
              <span class="descent-label">BENCH SUITE</span>
              <span data-descent-bench-suite>railsbench / liquid / optcarrot</span>
            </div>
            <div>
              <span class="descent-label">KEEP DELTA</span>
              <span data-descent-delta>+0.00%</span>
            </div>
            <div>
              <span class="descent-label">RUBYSPEC</span>
              <span data-descent-spec-short>99.60%</span>
            </div>
            <div>
              <span class="descent-label">RSS</span>
              <span data-descent-memory-short>612MB / +0.0%</span>
            </div>
            <div>
              <span class="descent-label">SYS.TIME</span>
              <span data-descent-clock>00:00:00:00</span>
            </div>
          </div>
        </header>

        <aside class="descent-panel descent-panel-left">
          <div class="descent-panel-header">PROCESS PARAMETERS</div>
          <div class="descent-param-group">
            <div class="descent-label">TARGET</div>
            <div class="descent-value">ruby-head // make it faster</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">SEARCH STRATEGY</div>
            <div class="descent-value descent-value-highlight">AUTORESEARCH LOOP</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">ACTIVE BRANCH</div>
            <div class="descent-value" data-descent-branch>ruby-speed-lab-A12</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">LEARNING RATE (α)</div>
            <div class="descent-value">0.011</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">MOMENTUM (β)</div>
            <div class="descent-value">0.840</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">CURRENT PATCH</div>
            <div class="descent-value" data-descent-patch>warming benchmark harness</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">HOT BENCH</div>
            <div class="descent-value" data-descent-hotbench>railsbench</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">JIT STATUS</div>
            <div class="descent-value" data-descent-jit>YJIT on // side exits 1.8%</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">RUBYSPEC PASS</div>
            <div class="descent-value" data-descent-spec-long>18,415 / 18,472 (99.69%)</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">RSS / OBJSPACE</div>
            <div class="descent-value" data-descent-memory-long>612MB rss // heap live 78.3%</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">GC PROFILE</div>
            <div class="descent-value" data-descent-gc>RGENGC // compaction off // minor 3.1ms</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">WORKERS / SANDBOXES</div>
            <div class="descent-value" data-descent-workers>08 local // 03 remote</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">NOISE FLOOR (σ)</div>
            <div class="descent-value" data-descent-noise>±0.37%</div>
          </div>
          <div class="descent-param-group">
            <div class="descent-label">SEARCH VECTOR [dispatch, alloc]</div>
            <div class="descent-value" data-descent-vector>[ 0.000, 0.000 ]</div>
          </div>
          <div class="descent-param-group descent-param-group-fill">
            <div class="descent-label">AGENT STATUS</div>
            <div class="descent-value glitch-text" data-text="AUTORESEARCHING" data-descent-status>AUTORESEARCHING</div>
          </div>
        </aside>

        <aside class="descent-panel descent-panel-right">
          <div class="descent-panel-header">TELEMETRY STREAM</div>
          <div class="descent-mini-grid">
            <div class="descent-mini-stat">
              <span class="descent-label">MUTATIONS</span>
              <span class="descent-mini-value" data-descent-mutations>0000</span>
            </div>
            <div class="descent-mini-stat">
              <span class="descent-label">KEEPS</span>
              <span class="descent-mini-value" data-descent-keeps>000</span>
            </div>
            <div class="descent-mini-stat">
              <span class="descent-label">YJIT COVERAGE</span>
              <span class="descent-mini-value" data-descent-jitcov>91.4%</span>
            </div>
            <div class="descent-mini-stat">
              <span class="descent-label">FAILURES</span>
              <span class="descent-mini-value" data-descent-failures>0</span>
            </div>
          </div>
          <div class="descent-check-matrix">
            <div class="descent-viz-header"><span>VERIFY MATRIX</span><span>LINTS + TESTS</span></div>
            <div class="descent-check-grid" data-descent-check-grid>
              <div class="descent-check-cell" data-descent-check="rubyspec-core"><span class="descent-check-name">spec</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="ruby-lint"><span class="descent-check-name">lint</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="bench-suite"><span class="descent-check-name">bench</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="rss-budget"><span class="descent-check-name">rss</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="gc-guard"><span class="descent-check-name">gc</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="yjit-exits"><span class="descent-check-name">yjit</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="shape-cache"><span class="descent-check-name">shape</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="alloc-budget"><span class="descent-check-name">alloc</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="railsbench"><span class="descent-check-name">rails</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="optcarrot"><span class="descent-check-name">8bit</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="liquid"><span class="descent-check-name">liquid</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="threading"><span class="descent-check-name">threads</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="ffi"><span class="descent-check-name">ffi</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="api-compat"><span class="descent-check-name">api</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="asan"><span class="descent-check-name">asan</span><span class="descent-check-state">pending</span></div>
              <div class="descent-check-cell" data-descent-check="ubsan"><span class="descent-check-name">ubsan</span><span class="descent-check-state">pending</span></div>
            </div>
          </div>
          <div class="descent-analytics-grid">
            <section class="descent-viz-card">
              <div class="descent-viz-header"><span>RSS HISTORY</span><span data-descent-memory-short>612MB / +0.0%</span></div>
              <canvas class="descent-viz-canvas" data-descent-memory-chart aria-hidden="true"></canvas>
            </section>
            <section class="descent-viz-card">
              <div class="descent-viz-header"><span>STACK TRACE TREEMAP</span><span>HOT PATHS</span></div>
              <canvas class="descent-viz-canvas" data-descent-stack-chart aria-hidden="true"></canvas>
            </section>
            <section class="descent-viz-card">
              <div class="descent-viz-header"><span>TIME IN SUBSERVICES</span><span>STREAMGRAPH</span></div>
              <canvas class="descent-viz-canvas" data-descent-stream-chart aria-hidden="true"></canvas>
            </section>
            <section class="descent-viz-card">
              <div class="descent-viz-header"><span>COST/$ RESULTS</span><span>SCATTERPLOT</span></div>
              <canvas class="descent-viz-canvas" data-descent-cost-chart aria-hidden="true"></canvas>
            </section>
          </div>
          <div class="descent-log-container" data-descent-log></div>
          <div class="descent-footer-strip">
            <div class="descent-footer-item">
              <span class="descent-label">QUEUE DEPTH</span>
              <span data-descent-queue>03 pending</span>
            </div>
            <div class="descent-footer-item">
              <span class="descent-label">LAST VERIFY</span>
              <span data-descent-verify>spec + bench + memory</span>
            </div>
            <div class="descent-footer-item">
              <span class="descent-label">BASELINE</span>
              <span data-descent-baseline>ruby 3.5.0dev</span>
            </div>
          </div>
        </aside>

        <div class="descent-panel descent-panel-bottom">
          <div class="descent-chart-container">
            <div class="descent-label descent-chart-heading">
              <span>LOSS FUNCTION TRAJECTORY // RUBY GETS FASTER</span>
              <span>f(patch)</span>
            </div>
            <canvas class="descent-chart" data-descent-chart aria-hidden="true"></canvas>
            <div class="descent-chart-labels">
              <span>ITERATION (t)</span>
              <span>KEEP IF LOWER</span>
            </div>
          </div>
          <div class="descent-loss-readout">
            <div class="descent-loss-grid">
              <div class="descent-loss-block">
                <div class="descent-label">CURRENT LOSS</div>
                <div class="descent-loss-value" data-descent-loss>0.000000</div>
                <div class="descent-loss-best">GLOBAL MIN <span data-descent-best>0.000000</span></div>
              </div>
              <div class="descent-loss-block">
                <div class="descent-label">LATEST KEEP</div>
                <div class="descent-delta-value" data-descent-delta>+0.00%</div>
                <div class="descent-loss-caption">WIN VS BASELINE</div>
              </div>
            </div>
            <div class="descent-readout-grid">
              <div class="descent-readout-stat">
                <span class="descent-label">THROUGHPUT</span>
                <span class="descent-mini-value" data-descent-throughput>+0.00%</span>
              </div>
              <div class="descent-readout-stat">
                <span class="descent-label">IPS</span>
                <span class="descent-mini-value" data-descent-ips>0.00M</span>
              </div>
              <div class="descent-readout-stat">
                <span class="descent-label">MEM Δ</span>
                <span class="descent-mini-value" data-descent-memory-delta>+0.0%</span>
              </div>
              <div class="descent-readout-stat">
                <span class="descent-label">SPEC OK</span>
                <span class="descent-mini-value" data-descent-spec-short>99.60%</span>
              </div>
            </div>
          </div>
        </div>

        <div class="descent-target" aria-hidden="true">
          <div class="descent-target-bracket descent-target-top-left"></div>
          <div class="descent-target-bracket descent-target-top-right"></div>
          <div class="descent-target-bracket descent-target-bottom-left"></div>
          <div class="descent-target-bracket descent-target-bottom-right"></div>
        </div>

        <div class="descent-title-card">
          <div class="descent-kicker">AUTORESEARCH HARNESS v0.1</div>
          <h1 class="descent-title">#{copy.fetch(:title)}</h1>
          #{subtitle_html}
          <div class="descent-meta">
            <span class="descent-meta-pill">#{copy.fetch(:author)}</span>
            <span class="descent-meta-pill">SPEEDSHOP.CO.JP</span>
            <span class="descent-meta-pill descent-meta-pill--logo">#{rubykaigi_wordmark_svg}</span>
          </div>
        </div>
      </div>
    </div>
  HTML
end

def parse_slide(lines)
  ticks = 1
  skin = nil
  lines = lines.dup

  loop do
    line = lines.first&.strip
    break if line.nil?

    if (match = line.match(SLIDE_TICKS_TAG))
      ticks = match[1].to_i
      lines.shift
    elsif (match = line.match(SLIDE_SKIN_TAG))
      skin = match[1].downcase
      lines.shift
    else
      break
    end
  end

  return if lines.all? { _1.strip.empty? }

  { lines:, ticks:, skin: }
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
  skin = slide[:skin]
  classes = ["slide"]
  classes << "slide--#{skin}" if skin
  skin_attr = skin ? %( data-slide-skin="#{skin}") : ""
  content = skin == "descent" ? render_descent_slide(slide) : %(<div class="slide-content">#{render_slide(lines)}</div>)

  %(<div class="#{classes.join(" ")}" id="slide-#{index}" data-advance-ms="#{advance_ms}"#{skin_attr}>#{content}</div>)
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
