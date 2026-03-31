#!/usr/bin/env ruby
# frozen_string_literal: true

# Converts presentation.md into a single-page HTML slideshow.
#
# Slide separator: a line containing only "---"
# Each slide's content is rendered as simple HTML:
#   # heading  -> <h1>
#   ## heading -> <h2>
#   **bold**   -> <strong>
#   *italic*   -> <em>
#   - item     -> <li> inside <ul>
#   numbered   -> <li> inside <ol>
#   blank lines separate paragraphs

require "cgi"

def parse_inline(text)
  text = CGI.escapeHTML(text)
  text.gsub!(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
  text.gsub!(/\*(.+?)\*/, '<em>\1</em>')
  text.gsub!(/`(.+?)`/, '<code>\1</code>')
  text.gsub!(/\[(.+?)\]\((.+?)\)/, '<a href="\2">\1</a>')
  text.gsub!(%r{(?<!")https?://\S+}) { |url| %(<a href="#{url}">#{url}</a>) }
  text
end

def render_slide(lines)
  blocks = []
  i = 0

  while i < lines.length
    stripped = lines[i].strip

    if stripped.empty?
      i += 1
      next
    end

    # Headings
    if stripped.start_with?("### ")
      blocks << "<h3>#{parse_inline(stripped[4..])}</h3>"
      i += 1
      next
    elsif stripped.start_with?("## ")
      blocks << "<h2>#{parse_inline(stripped[3..])}</h2>"
      i += 1
      next
    elsif stripped.start_with?("# ")
      blocks << "<h1>#{parse_inline(stripped[2..])}</h1>"
      i += 1
      next
    end

    # Unordered list
    if stripped.match?(/^[-*]\s/)
      items = []
      while i < lines.length && lines[i].strip.match?(/^[-*]\s/)
        item_text = lines[i].strip.sub(/^[-*]\s+/, "")
        items << "  <li>#{parse_inline(item_text)}</li>"
        i += 1
      end
      blocks << "<ul>\n#{items.join("\n")}\n</ul>"
      next
    end

    # Ordered list
    if stripped.match?(/^\d+[.)]\s/)
      items = []
      while i < lines.length && lines[i].strip.match?(/^\d+[.)]\s/)
        item_text = lines[i].strip.sub(/^\d+[.)]\s+/, "")
        items << "  <li>#{parse_inline(item_text)}</li>"
        i += 1
      end
      blocks << "<ol>\n#{items.join("\n")}\n</ol>"
      next
    end

    # Paragraph
    para_lines = []
    while i < lines.length && !lines[i].strip.empty?
      para_lines << parse_inline(lines[i].strip)
      i += 1
    end
    blocks << "<p>#{para_lines.join("<br>\n")}</p>"
  end

  blocks.join("\n")
end

def build(input_path, output_path)
  content = File.read(input_path)

  raw_slides = content.split(/^\s*---\s*$/)
  slides = raw_slides.filter_map { |s|
    lines = s.strip.lines.map(&:chomp)
    lines unless lines.empty?
  }

  slide_html_parts = slides.each_with_index.map { |slide_lines, idx|
    inner = render_slide(slide_lines)
    <<~HTML
      <div class="slide" id="slide-#{idx}">
        <div class="slide-content">
      #{inner}
        </div>
      </div>
    HTML
  }

  total = slides.length
  slides_joined = slide_html_parts.join("\n")

  page = <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Presentation</title>
    <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    html, body {
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #fff;
      color: #000;
      font-family: "Palatino Linotype", Palatino, "Book Antiqua", Georgia, serif;
    }
    .slide {
      display: none;
      width: 100vw;
      height: 100vh;
      justify-content: center;
      align-items: center;
      padding: 8vw;
    }
    .slide.active {
      display: flex;
    }
    .slide-content {
      max-width: 900px;
      width: 100%;
    }
    h1 {
      font-size: 3rem;
      font-weight: 700;
      margin-bottom: 0.6em;
      line-height: 1.2;
    }
    h2 {
      font-size: 2.2rem;
      font-weight: 600;
      margin-bottom: 0.5em;
      line-height: 1.2;
    }
    h3 {
      font-size: 1.6rem;
      font-weight: 600;
      margin-bottom: 0.4em;
    }
    p {
      font-size: 1.5rem;
      line-height: 1.6;
      margin-bottom: 0.8em;
    }
    ul, ol {
      font-size: 1.5rem;
      line-height: 1.8;
      margin-left: 1.5em;
      margin-bottom: 0.8em;
    }
    li {
      margin-bottom: 0.3em;
    }
    strong {
      font-weight: 700;
    }
    code {
      font-family: "SF Mono", Menlo, monospace;
      background: #f0f0f0;
      padding: 0.1em 0.3em;
      border-radius: 3px;
      font-size: 0.9em;
    }
    a {
      color: #000;
      text-decoration: underline;
    }
    .progress {
      position: fixed;
      bottom: 0;
      left: 0;
      height: 3px;
      background: #000;
      transition: width 0.3s ease;
    }
    </style>
    </head>
    <body>

    #{slides_joined}

    <div class="progress" id="progress"></div>

    <script>
    (function() {
      var current = 0;
      var total = #{total};
      var slides = document.querySelectorAll(".slide");
      var progress = document.getElementById("progress");

      function show(n) {
        if (n < 0 || n >= total) return;
        slides[current].classList.remove("active");
        current = n;
        slides[current].classList.add("active");
        progress.style.width = ((current + 1) / total * 100) + "%";
      }

      function next() { show(current + 1); }
      function prev() { show(current - 1); }

      document.addEventListener("click", function(e) {
        if (e.clientX < window.innerWidth * 0.15) {
          prev();
        } else {
          next();
        }
      });

      document.addEventListener("keydown", function(e) {
        if (e.key === "ArrowRight" || e.key === " " || e.key === "Enter") {
          e.preventDefault();
          next();
        } else if (e.key === "ArrowLeft" || e.key === "Backspace") {
          e.preventDefault();
          prev();
        } else if (e.key === "Home") {
          e.preventDefault();
          show(0);
        } else if (e.key === "End") {
          e.preventDefault();
          show(total - 1);
        }
      });

      show(0);
    })();
    </script>
    </body>
    </html>
  HTML

  File.write(output_path, page)
  puts "Built #{total} slides -> #{output_path}"
end

if __FILE__ == $PROGRAM_NAME
  src = ARGV[0] || "presentation.md"
  dst = ARGV[1] || "presentation.html"
  build(src, dst)
end
