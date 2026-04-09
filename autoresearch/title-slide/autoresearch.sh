#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

ruby -wc lib/build.rb build_test.rb lib/generate_slides.rb >/dev/null
mise build >/dev/null

runs_json="$(mktemp)"
for run in 1 2 3; do
  mise x node@22 -- node "$script_dir/bench_title_slide.cjs" dist/presentation.html >> "$runs_json"
  printf '\n' >> "$runs_json"
done

ruby -rjson -e '
  rows = File.readlines(ARGV[0], chomp: true).reject(&:empty?).map { JSON.parse(_1) }
  keys = %w[perf_index task_ms script_ms layout_ms style_ms heap_used_mb chrome_rss_mb fps p95_frame_ms longtask_ms]
  med = ->(values) do
    sorted = values.sort
    n = sorted.length
    n.odd? ? sorted[n / 2] : (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
  end
  metrics = keys.to_h { |key| [key, med.call(rows.map { _1.fetch(key) })] }
  keys.each { |key| puts "METRIC #{key}=#{metrics.fetch(key).round(4)}" }
' "$runs_json"

rm -f "$runs_json"
