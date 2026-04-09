#!/usr/bin/env node
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execSync } = require('node:child_process');
const puppeteer = require(path.resolve(__dirname, '../../tmp/benchmark_node/node_modules/puppeteer-core'));

const sampleMs = Number(process.env.BENCH_SAMPLE_MS || 5000);
const warmupMs = Number(process.env.BENCH_WARMUP_MS || 1500);
const viewport = { width: 1920, height: 1080, deviceScaleFactor: 1 };
const chromePath = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const filePath = path.resolve(process.argv[2] || 'dist/presentation.html');
const fileUrl = 'file://' + filePath + '#slide-0';

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function metricValue(metrics, name) {
  const match = metrics.find((metric) => metric.name === name);
  return match ? match.value : 0;
}

function chromeTreeRssMb(rootPid) {
  const lines = execSync('ps -axo pid=,ppid=,rss=,comm=', { encoding: 'utf8' })
    .trim()
    .split('\n')
    .filter(Boolean);
  const rows = lines.map((line) => {
    const match = line.trim().match(/^(\d+)\s+(\d+)\s+(\d+)\s+(.+)$/);
    if (!match) return null;
    return {
      pid: Number(match[1]),
      ppid: Number(match[2]),
      rssKb: Number(match[3]),
      command: match[4],
    };
  }).filter(Boolean);

  const rowByPid = new Map(rows.map((row) => [row.pid, row]));
  const children = new Map();
  for (const row of rows) {
    if (!children.has(row.ppid)) children.set(row.ppid, []);
    children.get(row.ppid).push(row.pid);
  }

  let rssKb = 0;
  const queue = [rootPid];
  const seen = new Set(queue);
  while (queue.length) {
    const pid = queue.shift();
    const row = rowByPid.get(pid);
    if (row && /Google Chrome/i.test(row.command)) rssKb += row.rssKb;
    for (const childPid of children.get(pid) || []) {
      if (!seen.has(childPid)) {
        seen.add(childPid);
        queue.push(childPid);
      }
    }
  }

  return rssKb / 1024;
}

async function removeDirQuietly(dirPath) {
  for (let attempt = 0; attempt < 8; attempt += 1) {
    try {
      fs.rmSync(dirPath, { recursive: true, force: true });
      return;
    } catch (error) {
      if (!['ENOTEMPTY', 'EBUSY', 'EPERM'].includes(error.code)) throw error;
      await sleep(150 * (attempt + 1));
    }
  }

  fs.rmSync(dirPath, { recursive: true, force: true });
}

(async () => {
  if (!fs.existsSync(filePath)) throw new Error(`Missing file: ${filePath}`);
  if (!fs.existsSync(chromePath)) throw new Error(`Missing Chrome executable: ${chromePath}`);

  const userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'title-slide-bench-'));
  let browser;

  try {
    browser = await puppeteer.launch({
      executablePath: chromePath,
      headless: 'new',
      userDataDir,
      defaultViewport: viewport,
      args: [
        '--allow-file-access-from-files',
        '--disable-background-timer-throttling',
        '--disable-backgrounding-occluded-windows',
        '--disable-renderer-backgrounding',
        '--enable-precise-memory-info',
        '--js-flags=--expose-gc',
        '--no-first-run',
        '--no-default-browser-check'
      ],
    });

    const [page] = await browser.pages();
    await page.evaluateOnNewDocument(() => {
      const bench = {
        count: 0,
        firstTs: null,
        lastTs: null,
        intervals: [],
        longTaskMs: 0,
      };
      window.__titleBench = bench;

      const originalRequestAnimationFrame = window.requestAnimationFrame.bind(window);
      window.requestAnimationFrame = (callback) => originalRequestAnimationFrame((timestamp) => {
        if (bench.firstTs === null) bench.firstTs = timestamp;
        if (bench.lastTs !== null) bench.intervals.push(timestamp - bench.lastTs);
        bench.lastTs = timestamp;
        bench.count += 1;
        callback(timestamp);
      });

      if ('PerformanceObserver' in window) {
        try {
          const observer = new PerformanceObserver((list) => {
            for (const entry of list.getEntries()) bench.longTaskMs += entry.duration;
          });
          observer.observe({ type: 'longtask', buffered: true });
        } catch (_error) {
        }
      }
    });

    await page.goto(fileUrl, { waitUntil: 'load' });
    await page.waitForSelector('.slide.active[data-slide-skin="descent"] .descent-stage');
    await page.waitForFunction(() => window.__titleBench && window.__titleBench.count > 20, { timeout: 10000 });

    const client = await page.target().createCDPSession();
    await client.send('Performance.enable');
    await client.send('HeapProfiler.enable');
    await client.send('HeapProfiler.collectGarbage');

    await sleep(warmupMs);

    const before = (await client.send('Performance.getMetrics')).metrics;
    await sleep(sampleMs);
    const after = (await client.send('Performance.getMetrics')).metrics;
    const pageStats = await page.evaluate(() => {
      const bench = window.__titleBench;
      const frameWindowMs = bench.lastTs && bench.firstTs ? bench.lastTs - bench.firstTs : 0;
      const fps = frameWindowMs > 0 ? ((bench.count - 1) * 1000) / frameWindowMs : 0;
      const p95FrameMs = bench.intervals.length
        ? (() => {
            const sorted = [...bench.intervals].sort((a, b) => a - b);
            return sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * 0.95))];
          })()
        : 0;
      return {
        fps,
        p95FrameMs,
        longTaskMs: bench.longTaskMs,
      };
    });

    const browserPid = browser.process().pid;
    const taskMs = (metricValue(after, 'TaskDuration') - metricValue(before, 'TaskDuration')) * 1000;
    const scriptMs = (metricValue(after, 'ScriptDuration') - metricValue(before, 'ScriptDuration')) * 1000;
    const layoutMs = (metricValue(after, 'LayoutDuration') - metricValue(before, 'LayoutDuration')) * 1000;
    const styleMs = (metricValue(after, 'RecalcStyleDuration') - metricValue(before, 'RecalcStyleDuration')) * 1000;
    const heapUsedMb = metricValue(after, 'JSHeapUsedSize') / (1024 * 1024);
    const chromeRssMb = chromeTreeRssMb(browserPid);
    const fps = pageStats.fps;
    const fpsPenalty = Math.max(0, 58 - fps);
    const perfIndex = taskMs + chromeRssMb * 2 + fpsPenalty * fpsPenalty * 250;

    process.stdout.write(JSON.stringify({
      sample_ms: sampleMs,
      task_ms: taskMs,
      script_ms: scriptMs,
      layout_ms: layoutMs,
      style_ms: styleMs,
      heap_used_mb: heapUsedMb,
      chrome_rss_mb: chromeRssMb,
      fps,
      p95_frame_ms: pageStats.p95FrameMs,
      longtask_ms: pageStats.longTaskMs,
      perf_index: perfIndex,
    }));
  } finally {
    if (browser) await browser.close();
    await removeDirQuietly(userDataDir);
  }
})().catch((error) => {
  console.error(error && error.stack ? error.stack : String(error));
  process.exit(1);
});
