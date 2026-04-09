# Autoresearch: title slide runtime budget

## Objective
Reduce the runtime cost of the title slide (`slide-skin: descent`) in `dist/presentation.html` without visibly breaking the slide. Specifically, reduce CPU usage and memory usage while preserving or improving framerate.

## Metrics
- **Primary**: `perf_index` (unitless, lower is better) — composite of renderer task time, Chrome RSS, and a strong framerate regression penalty.
- **Secondary**:
  - `task_ms` — main-thread task duration over the sample window
  - `script_ms` — JS execution time over the sample window
  - `layout_ms`, `style_ms` — layout/style costs over the sample window
  - `chrome_rss_mb` — Chrome process tree RSS with one title-slide tab open
  - `heap_used_mb` — JS heap used after warmup/sample
  - `fps` — achieved requestAnimationFrame rate
  - `p95_frame_ms` — frame pacing monitor
  - `longtask_ms` — long-task accumulation over the sample window

## How to Run
`./autoresearch/title-slide/autoresearch.sh`

This script:
1. syntax-checks the Ruby generators,
2. rebuilds `dist/presentation.html`,
3. runs a headless Chrome benchmark 3 times against `#slide-0`,
4. reports median structured metrics.

## Files in Scope
- `src/slides.js.erb` — title slide animation/runtime logic
- `src/page.html.erb` — title slide CSS/layout
- `lib/build.rb` — generated slide markup for the descent slide
- `dist/presentation.html`, `dist/reading-mode.html` — generated artifacts only
- `autoresearch/title-slide/*` — benchmark harness and experiment notes

## Off Limits
- `presentation.md` slide copy/content
- non-title-slide behavior unless required for shared runtime fixes
- benchmark definitions that would stop the slide from doing equivalent visible work

## Constraints
- Do not cheat the benchmark by pausing, hiding, or trivially disabling the title animation.
- Keep the title slide recognizably the same experience.
- `mise test` and `mise lint` must pass.
- Prefer changes that reduce actual work: fewer redraws, less DOM churn, less allocation, smaller canvases, more caching.
- Avoid overfitting to one lucky run; the benchmark already uses medians.

## What's Been Tried
- Baseline harness created with headless Chrome + CDP `Performance.getMetrics` + frame counting.
- First baseline attempt failed during teardown because Chrome still held the temporary profile open (`ENOTEMPTY`). Cleanup now retries.
- Big win: stopped redrawing DOM text and auxiliary telemetry panes every animation frame. They now update only when their backing data changes.
- Big win: lowered auxiliary telemetry canvas DPR ceiling from 1.5 to 1.
- Biggest wins so far: progressively lowered the main descent-stage render scale from 0.55 -> 0.5 -> 0.45 -> 0.4 -> 0.35 -> 0.3. Each step materially reduced task/script time while preserving measured framerate.
- Small win: slightly coarsening the terrain mesh to `step = 1.4` helped a bit. Pushing further to `1.6` was not worth the visual-risk / metric tradeoff and was discarded.
- Dead end: shortening the agent trail did not help.
- Open question: Chrome RSS is noisier than task time and sometimes rises even when JS heap and CPU fall. Treat RSS movement cautiously and prefer repeated confirmation before making memory-only decisions.
