# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "build"

class BuildArtifactTest < Minitest::Test
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
    assert_includes html, "font-size: clamp(2.2rem, 4vw, 4.75rem);"
    assert_includes html, "function fitHeading(heading)"
    assert_includes html, "var total=1"
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
    refute_includes reading_html, 'class="progress"'
  end
end
