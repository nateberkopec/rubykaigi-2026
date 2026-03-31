# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "build"

class ParseInlineTest < Minitest::Test
  def test_bold
    assert_equal "<strong>hello</strong>", parse_inline("**hello**")
  end

  def test_italic
    assert_equal "<em>hello</em>", parse_inline("*hello*")
  end

  def test_inline_code
    assert_equal "<code>foo</code>", parse_inline("`foo`")
  end

  def test_link
    assert_equal '<a href="http://x.com">click</a>', parse_inline("[click](http://x.com)")
  end

  def test_bare_url
    assert_includes parse_inline("see https://example.com ok"), '<a href="https://example.com">https://example.com</a>'
  end

  def test_html_escaping
    assert_includes parse_inline("<script>"), "&lt;script&gt;"
  end

  def test_bold_and_italic_combined
    result = parse_inline("**bold** and *italic*")
    assert_includes result, "<strong>bold</strong>"
    assert_includes result, "<em>italic</em>"
  end
end

class RenderSlideTest < Minitest::Test
  def test_h1
    assert_equal "<h1>Title</h1>", render_slide(["# Title"])
  end

  def test_h2
    assert_equal "<h2>Sub</h2>", render_slide(["## Sub"])
  end

  def test_h3
    assert_equal "<h3>Small</h3>", render_slide(["### Small"])
  end

  def test_unordered_list
    html = render_slide(["- one", "- two"])
    assert_includes html, "<ul>"
    assert_includes html, "<li>one</li>"
    assert_includes html, "<li>two</li>"
  end

  def test_ordered_list
    html = render_slide(["1. first", "2. second"])
    assert_includes html, "<ol>"
    assert_includes html, "<li>first</li>"
    assert_includes html, "<li>second</li>"
  end

  def test_paragraph
    html = render_slide(["hello world"])
    assert_equal "<p>hello world</p>", html
  end

  def test_multiline_paragraph
    html = render_slide(["line one", "line two"])
    assert_includes html, "line one<br>"
    assert_includes html, "line two"
  end

  def test_blank_lines_ignored
    html = render_slide(["# Title", "", "text"])
    assert_includes html, "<h1>Title</h1>"
    assert_includes html, "<p>text</p>"
  end

  def test_inline_formatting_in_list
    html = render_slide(["- **bold item**"])
    assert_includes html, "<strong>bold item</strong>"
  end
end

class BuildTest < Minitest::Test
  def test_builds_correct_slide_count
    Dir.mktmpdir do |dir|
      md = File.join(dir, "test.md")
      html_path = File.join(dir, "test.html")

      File.write(md, <<~MD)
        # Slide 1

        ---

        # Slide 2

        ---

        # Slide 3
      MD

      build(md, html_path)
      html = File.read(html_path)

      assert_equal 3, html.scan(/class="slide"/).length
    end
  end

  def test_empty_separators_skipped
    Dir.mktmpdir do |dir|
      md = File.join(dir, "test.md")
      html_path = File.join(dir, "test.html")

      File.write(md, <<~MD)
        ---

        # Only slide

        ---
      MD

      build(md, html_path)
      html = File.read(html_path)

      assert_equal 1, html.scan(/class="slide"/).length
    end
  end

  def test_output_is_valid_html_structure
    Dir.mktmpdir do |dir|
      md = File.join(dir, "test.md")
      html_path = File.join(dir, "test.html")

      File.write(md, "# Hello")

      build(md, html_path)
      html = File.read(html_path)

      assert_includes html, "<!DOCTYPE html>"
      assert_includes html, "<title>Presentation</title>"
      assert_includes html, "Palatino Linotype"
      assert_includes html, 'var total = 1'
      assert_includes html, 'class="progress"'
    end
  end

  def test_slide_ids_are_sequential
    Dir.mktmpdir do |dir|
      md = File.join(dir, "test.md")
      html_path = File.join(dir, "test.html")

      File.write(md, "# A\n\n---\n\n# B\n\n---\n\n# C")

      build(md, html_path)
      html = File.read(html_path)

      assert_includes html, 'id="slide-0"'
      assert_includes html, 'id="slide-1"'
      assert_includes html, 'id="slide-2"'
    end
  end
end
