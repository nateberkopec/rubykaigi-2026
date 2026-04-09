# frozen_string_literal: true

require "cgi"
require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"
require_relative "lib/build"

class BuildArtifactTest < Minitest::Test
  CHROME_PATH = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  FIT_HEADING_GOLDENS = JSON.parse(File.read(File.join(__dir__, "testdata/fit_heading_golden.json")))

  private

  def build_html(markdown)
    Dir.mktmpdir do |dir|
      md = File.join(dir, "test.md")
      html_path = File.join(dir, "test.html")

      File.write(md, markdown)
      build(md, html_path)
      File.read(html_path)
    end
  end

  def build_outputs(markdown)
    Dir.mktmpdir do |dir|
      md = File.join(dir, "test.md")
      presentation_path = File.join(dir, "presentation.html")
      reading_mode_path = File.join(dir, "reading-mode.html")

      File.write(md, markdown)
      build_artifacts(md, presentation_path)
      [File.read(presentation_path), File.read(reading_mode_path)]
    end
  end

  def generate_slides_markdown(outline)
    Dir.mktmpdir do |dir|
      input_path = File.join(dir, "outline.md")
      output_path = File.join(dir, "presentation.md")

      File.write(input_path, outline)
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        File.join(__dir__, "lib/generate_slides.rb"),
        input_path,
        output_path
      )

      assert status.success?, "generate_slides failed: #{stderr}\n#{stdout}"
      File.read(output_path)
    end
  end

  def with_built_artifacts(markdown)
    Dir.mktmpdir do |dir|
      md = File.join(dir, "test.md")
      presentation_path = File.join(dir, "presentation.html")
      reading_mode_path = File.join(dir, "reading-mode.html")

      File.write(md, markdown)
      build_artifacts(md, presentation_path)
      yield presentation_path, reading_mode_path
    end
  end

  def chrome_available?
    File.executable?(CHROME_PATH)
  end

  def rendered_dom(path, window_size:, hash: nil, virtual_time_budget: 1500)
    skip "Google Chrome is required for rendered fit-heading tests" unless chrome_available?

    width, height = window_size
    url = "file://#{path}"
    url = "#{url}#{hash}" if hash
    stdout, stderr, status = Open3.capture3(
      CHROME_PATH,
      "--headless=new",
      "--disable-gpu",
      "--run-all-compositor-stages-before-draw",
      "--virtual-time-budget=#{virtual_time_budget}",
      "--window-size=#{width},#{height}",
      "--dump-dom",
      url
    )

    assert status.success?, "chrome dump failed: #{stderr}"
    stdout
  end

  def rendered_dom_with_injected_script(path, window_size:, script:, hash: nil, virtual_time_budget: 1500)
    Dir.mktmpdir do |dir|
      html_path = File.join(dir, File.basename(path))
      html = File.read(path).sub("</body>", %(<script>#{script}</script></body>))

      File.write(html_path, html)
      return rendered_dom(html_path, window_size:, hash:, virtual_time_budget:)
    end
  end

  def fit_heading_font_size(dom)
    match = dom.match(/class="fit-heading" style="font-size: ([0-9.]+)px;"/)
    refute_nil match, "expected rendered DOM to include a fit-heading with inline font-size"

    match[1].to_f
  end

  def active_slide_id(dom)
    match = dom.match(/class="slide active" id="([^"]+)"/)
    refute_nil match, "expected rendered DOM to include an active slide"

    match[1]
  end

  def body_data_attribute(dom, name)
    match = dom.match(/<body[^>]*#{name}="([^"]*)"/)
    refute_nil match, "expected body to include #{name}"

    CGI.unescapeHTML(match[1])
  end

  public

  def test_renders_inline_formatting
    html = build_html(<<~MD)
      **hello**

      *world*

      `foo`

      [click](http://x.com)

      see https://example.com ok
    MD

    assert_includes html, "<strong>hello</strong>"
    assert_includes html, "<em>world</em>"
    assert_includes html, "<code>foo</code>"
    assert_includes html, '<a href="http://x.com">click</a>'
    assert_includes html, '<a href="https://example.com">https://example.com</a>'
  end

  def test_escapes_html
    html = build_html("<script>")
    assert_includes html, "&lt;script&gt;"
  end

  def test_renders_headings
    html = build_html(<<~MD)
      # Title

      ## Subtitle

      ### Small
    MD

    assert_includes html, "<h1>Title</h1>"
    assert_includes html, "<h2>Subtitle</h2>"
    assert_includes html, "<h3>Small</h3>"
  end

  def test_renders_fit_headings
    html = build_html("# [fit] The Slide")

    assert_includes html, '<h1 class="fit-heading">The Slide</h1>'
    refute_includes html, "[fit] The Slide"
    assert_includes html, "fit-layout"
  end

  def test_renders_lists
    html = build_html(<<~MD)
      - one
      - **two**

      1. first
      2. second
    MD

    assert_includes html, "<ul>"
    assert_includes html, "<li>one</li>"
    assert_includes html, "<li><strong>two</strong></li>"
    assert_includes html, "<ol>"
    assert_includes html, "<li>first</li>"
    assert_includes html, "<li>second</li>"
  end

  def test_parses_optional_slide_ticks_tags
    slides = parse_slides(<<~MD)
      [ticks:2x]
      # A

      ---

      # B

      ---

      [tick:3]
      # C
    MD

    assert_equal [2, 1, 3], slides.map { _1.fetch(:ticks) }
    assert_equal ["# A"], slides.first.fetch(:lines)
    assert_equal ["# C"], slides.last.fetch(:lines)
  end

  def test_parses_optional_slide_skin_tag
    slides = parse_slides(<<~MD)
      [slide-skin:descent]
      # A

      ---

      [ticks:2x]
      [slide-skin:descent]
      # B
    MD

    assert_equal ["descent", "descent"], slides.map { _1.fetch(:skin) }
    assert_equal [1, 2], slides.map { _1.fetch(:ticks) }
    assert_equal ["# A"], slides.first.fetch(:lines)
  end

  def test_advance_durations_sum_to_25_minutes
    durations = advance_durations_ms([1, 2, 3])

    assert_equal [250_000, 500_000, 750_000], durations
    assert_equal TOTAL_PRESENTATION_MS, durations.sum
  end

  def test_built_presentation_embeds_25_minute_auto_advance_schedule
    html = build_html(<<~MD)
      # A

      ---

      [ticks:2x]
      # B

      ---

      [ticks:3x]
      # C
    MD

    durations = html.scan(/data-advance-ms="(\d+)"/).flatten.map(&:to_i)

    assert_equal [250_000, 500_000, 750_000], durations
    assert_equal TOTAL_PRESENTATION_MS, durations.sum
  end

  def test_build_reports_base_tick_seconds
    Dir.mktmpdir do |dir|
      md = File.join(dir, "test.md")
      html_path = File.join(dir, "presentation.html")

      File.write(md, <<~MD)
        # A

        ---

        [ticks:2x]
        # B

        ---

        [ticks:3x]
        # C
      MD

      stdout, = capture_io do
        build_artifacts(md, html_path)
      end

      assert_includes stdout, "Auto-advance tick: 250.00s"
      assert_includes stdout, "6 weighted ticks in 25:00"
    end
  end

  def test_renders_paragraphs_and_blank_lines
    html = build_html(<<~MD)
      # Title

      line one
      line two
    MD

    assert_includes html, "<h1>Title</h1>"
    assert_includes html, "<p>line one<br>\nline two</p>"
  end

  def test_builds_correct_slide_count
    html = build_html(<<~MD)
      # Slide 1

      ---

      # Slide 2

      ---

      # Slide 3
    MD

    assert_equal 3, html.scan(/class="slide"/).length
  end

  def test_empty_separators_are_skipped
    html = build_html(<<~MD)
      ---

      # Only slide

      ---
    MD

    assert_equal 1, html.scan(/class="slide"/).length
  end

  def test_output_has_expected_html_structure
    html = build_html("# Hello")

    assert_includes html, "<!DOCTYPE html>"
    assert_includes html, "<title>Presentation</title>"
    assert_includes html, "Palatino Linotype"
    assert_includes html, "width: min(100vw, calc(100vh * 16 / 9));"
    assert_includes html, "container-type: size;"
    assert_includes html, "font-size: clamp(2.4rem, 5.5cqh, 6rem);"
    assert_includes html, "function fitHeading(heading)"
    assert_includes html, "function slideInnerSize(slide)"
    assert_includes html, "getComputedStyle(slide)"
    assert_includes html, 'var mode = "presentation";'
    assert_includes html, "var total = 1;"
    assert_includes html, 'data-advance-ms="1500000"'
    assert_includes html, 'toggleAutoAdvance()'
    assert_includes html, 'e.key === "a" || e.key === "A"'
    assert_includes html, 'window.history.replaceState(null, "", hash);'
    assert_includes html, 'show(hashIndex() || 0);'
    assert_includes html, 'body[data-auto-advance="on"] .progress {'
    assert_includes html, 'class="progress"'
  end

  def test_slide_ids_are_sequential
    html = build_html("# A\n\n---\n\n# B\n\n---\n\n# C")

    assert_includes html, 'id="slide-0"'
    assert_includes html, 'id="slide-1"'
    assert_includes html, 'id="slide-2"'
  end

  def test_build_artifacts_generates_reading_mode
    presentation_html, reading_html = build_outputs("# A\n\n---\n\n# [fit] B")

    assert_includes presentation_html, '<title>Presentation</title>'
    assert_includes reading_html, '<title>Presentation (Reading Mode)</title>'
    assert_includes reading_html, 'class="deck"'
    assert_equal 2, reading_html.scan(/class="slide"/).length
    assert_includes reading_html, '<h1 class="fit-heading">B</h1>'
    assert_includes reading_html, 'overflow-y: auto;'
    assert_includes reading_html, 'aspect-ratio: 16 / 9;'
    assert_includes reading_html, 'aspect-ratio: 4 / 3;'
    assert_includes reading_html, 'font-size: clamp(0.95rem, 1.85cqh, 1.9rem);'
    assert_includes reading_html, 'function slideInnerSize(slide)'
    assert_includes reading_html, '@media print {'
    assert_includes reading_html, 'break-after: page;'
    refute_includes reading_html, 'class="progress"'
  end

  def test_renders_descent_slide_skin_markup
    html = build_html(<<~MD)
      [slide-skin:descent]
      # [fit] Autoresearching Ruby Performance with LLMs

      **Nate Berkopec**

      RubyKaigi 2026
    MD

    assert_includes html, 'data-slide-skin="descent"'
    assert_includes html, 'class="slide slide--descent"'
    assert_includes html, "RUBY AUTORESEARCH // PERFORMANCE DESCENT"
    assert_includes html, "LOSS FUNCTION TRAJECTORY // RUBY GETS FASTER"
    assert_includes html, 'class="descent-stage"'
    assert_includes html, 'data-descent-chart'
    assert_includes html, 'data-descent-jit'
    assert_includes html, 'data-descent-spec-long'
    assert_includes html, 'data-descent-memory-long'
    assert_includes html, 'data-descent-check-grid'
    assert_includes html, 'data-descent-check="rubyspec-core"'
    assert_includes html, 'data-descent-memory-chart'
    assert_includes html, 'data-descent-stack-chart'
    assert_includes html, 'data-descent-stream-chart'
    assert_includes html, 'data-descent-cost-chart'
    assert_includes html, 'COST/$ RESULTS'
    assert_includes html, 'SPEEDSHOP.CO.JP'
    assert_includes html, 'AUTORESEARCH HARNESS v0.1'
    assert_includes html, 'descent-meta-pill--logo'
    assert_includes html, 'descent-rubykaigi-wordmark'
    assert_includes html, 'descent-loss-grid'
    assert_includes html, 'WIN VS BASELINE'
    assert_includes html, 'applyDescentDither'
    assert_includes html, 'rubyKaigiStarPath'
    assert_includes html, 'descent-check-alert'
    assert_includes html, 'renderDescentCheckMatrix'
    assert_includes html, 'renderDescentMemoryChart'
    assert_includes html, 'renderDescentTreemap'
    assert_includes html, 'renderDescentStreamgraph'
    assert_includes html, 'renderDescentCostResults'
    assert_includes html, 'currentPatch.toUpperCase()'
    assert_includes html, 'requestAnimationFrame(frame);'
    refute_includes html, 'descent-header-title glitch-text'
  end

  def test_fit_heading_matches_golden_master_in_presentation_mode
    golden = FIT_HEADING_GOLDENS.fetch("presentation_desktop")

    with_built_artifacts("# [fit] The Slide Heading") do |presentation_path, _reading_mode_path|
      dom = rendered_dom(presentation_path, window_size: golden.fetch("window_size"))
      size = fit_heading_font_size(dom)

      assert_in_delta golden.fetch("font_size"), size, golden.fetch("tolerance")
    end
  end

  def test_presentation_mode_respects_hash_anchor_for_initial_slide
    with_built_artifacts("# A\n\n---\n\n# B\n\n---\n\n# C") do |presentation_path, _reading_mode_path|
      dom = rendered_dom(presentation_path, window_size: [1440, 900], hash: "#slide-1")

      assert_equal "slide-1", active_slide_id(dom)
      assert_match(/<div class="progress" id="progress" style="[^"]*width: 66\.6667%;[^"]*">/, dom)
    end
  end

  def test_descent_title_slide_click_advances_even_inside_left_panel_area
    markdown = <<~MD
      [slide-skin:descent]
      # [fit] Autoresearching Ruby Performance with LLMs

      **Nate Berkopec**

      RubyKaigi 2026

      ---

      # Next
    MD

    script = <<~JS
      setTimeout(function () {
        document.dispatchEvent(new MouseEvent("click", { clientX: 200, clientY: 300, bubbles: true }));
      }, 50);
      setTimeout(function () {
        document.body.setAttribute("data-test-active", document.querySelector(".slide.active").id);
        document.body.setAttribute("data-test-slide0-display", getComputedStyle(document.getElementById("slide-0")).display);
        var center = document.elementFromPoint(window.innerWidth / 2, window.innerHeight / 2);
        document.body.setAttribute(
          "data-test-center-slide",
          center && center.closest(".slide") ? center.closest(".slide").id : "none"
        );
      }, 500);
    JS

    with_built_artifacts(markdown) do |presentation_path, _reading_mode_path|
      dom = rendered_dom_with_injected_script(
        presentation_path,
        window_size: [1440, 900],
        script:,
        virtual_time_budget: 1000
      )

      assert_equal "slide-1", body_data_attribute(dom, "data-test-active")
      assert_equal "none", body_data_attribute(dom, "data-test-slide0-display")
      assert_equal "slide-1", body_data_attribute(dom, "data-test-center-slide")
    end
  end

  def test_descent_title_slide_animates_check_matrix_states
    markdown = <<~MD
      [slide-skin:descent]
      # [fit] Autoresearching Ruby Performance with LLMs

      **Nate Berkopec**

      RubyKaigi 2026
    MD

    script = <<~JS
      setTimeout(function () {
        document.body.setAttribute(
          "data-test-running-checks",
          String(document.querySelectorAll(".descent-check-cell.is-running").length)
        );
        document.body.setAttribute(
          "data-test-pass-checks",
          String(document.querySelectorAll(".descent-check-cell.is-pass").length)
        );
      }, 600);
    JS

    with_built_artifacts(markdown) do |presentation_path, _reading_mode_path|
      dom = rendered_dom_with_injected_script(
        presentation_path,
        window_size: [1440, 900],
        script:,
        virtual_time_budget: 1100
      )

      assert_operator body_data_attribute(dom, "data-test-running-checks").to_i, :>=, 1
      assert_operator body_data_attribute(dom, "data-test-pass-checks").to_i, :>=, 1
    end
  end

  def test_descent_title_slide_failure_logic_flashes_and_resets_matrix
    html = build_html(<<~MD)
      [slide-skin:descent]
      # [fit] Autoresearching Ruby Performance with LLMs

      **Nate Berkopec**

      RubyKaigi 2026
    MD

    assert_includes html, 'is-flashing'
    assert_includes html, 'descent-check-alert'
    assert_includes html, 'window.__piForceCheckFailure'
    assert_includes html, 'VERIFY FAIL // restarting lint + test gauntlet'
    assert_includes html, 'VERIFY MATRIX RESET // restarting lints + tests'
    assert_includes html, 'state.matrixResetTimer = window.setTimeout('
    assert_includes html, 'resetDescentCheckMatrix(state);'
  end

  def test_auto_advance_toggle_turns_progress_bar_blue_and_advances_slide
    markdown = <<~MD
      # A

      ---

      # B

      ---

      [ticks:1498x]
      # C
    MD

    script = <<~JS
      setTimeout(function () {
        document.dispatchEvent(new KeyboardEvent("keydown", { key: "a", bubbles: true }));
      }, 50);
      setTimeout(function () {
        document.body.setAttribute("data-test-active", document.querySelector(".slide.active").id);
        document.body.setAttribute("data-test-auto", document.body.dataset.autoAdvance || "");
        document.body.setAttribute("data-test-progress-color", document.getElementById("progress").style.backgroundColor);
      }, 1250);
    JS

    with_built_artifacts(markdown) do |presentation_path, _reading_mode_path|
      dom = rendered_dom_with_injected_script(
        presentation_path,
        window_size: [1440, 900],
        script:,
        virtual_time_budget: 1600
      )

      assert_equal "slide-1", body_data_attribute(dom, "data-test-active")
      assert_equal "on", body_data_attribute(dom, "data-test-auto")
      assert_equal "rgb(10, 132, 255)", body_data_attribute(dom, "data-test-progress-color")
    end
  end

  def test_auto_advance_reaches_last_slide_and_turns_itself_off
    markdown = <<~MD
      # A

      ---

      # B

      ---

      [ticks:1498x]
      # C
    MD

    script = <<~JS
      setTimeout(function () {
        document.dispatchEvent(new KeyboardEvent("keydown", { key: "a", bubbles: true }));
      }, 50);
      setTimeout(function () {
        document.body.setAttribute("data-test-active", document.querySelector(".slide.active").id);
        document.body.setAttribute("data-test-auto", document.body.dataset.autoAdvance || "");
      }, 2300);
    JS

    with_built_artifacts(markdown) do |presentation_path, _reading_mode_path|
      dom = rendered_dom_with_injected_script(
        presentation_path,
        window_size: [1440, 900],
        script:,
        virtual_time_budget: 2700
      )

      assert_equal "slide-2", body_data_attribute(dom, "data-test-active")
      assert_equal "off", body_data_attribute(dom, "data-test-auto")
    end
  end

  def test_fit_heading_matches_golden_master_in_mobile_reading_mode
    golden = FIT_HEADING_GOLDENS.fetch("reading_mobile")

    with_built_artifacts("# [fit] The Slide Heading") do |_presentation_path, reading_mode_path|
      dom = rendered_dom(reading_mode_path, window_size: golden.fetch("window_size"))
      size = fit_heading_font_size(dom)

      assert_in_delta golden.fetch("font_size"), size, golden.fetch("tolerance")
    end
  end

  def test_generate_slides_turns_blank_nested_item_into_a_multiline_slide
    markdown = generate_slides_markdown(<<~MD)
      - **WHAT IS AUTORESEARCH**
          -
              1. Modify code
              2. Run tests
              3. Measure code against benchmark
              4. If improved, keep change, GOTO 1.
    MD

    assert_includes markdown, <<~MD.chomp
      ---

      # [fit] WHAT IS AUTORESEARCH
    MD

    assert_includes markdown, <<~MD.chomp
      ---

      # WHAT IS AUTORESEARCH

      1. Modify code
      2. Run tests
      3. Measure code against benchmark
      4. If improved, keep change, GOTO 1.
    MD
  end

  def test_generate_slides_keeps_ancestor_headings_for_blank_nested_items
    markdown = generate_slides_markdown(<<~MD)
      - **PERF ENGINEERING**
          - What requirements do we usually have?
              -
                  - Latency
                  - Resource efficiency
                  - Robustness
    MD

    assert_includes markdown, <<~MD.chomp
      ---

      # PERF ENGINEERING

      ## What requirements do we usually have?

      - Latency
      - Resource efficiency
      - Robustness
    MD
  end
end
