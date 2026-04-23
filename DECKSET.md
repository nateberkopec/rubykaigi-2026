autoscale: true
fit-header: #, ##

![fit autoplay loop mute](img/title-slide.mov)

---

[.column]

![inline](img/tweet.jpeg)

[.column]

![inline](img/tweet-screenshot.png)

March 8th, 2026

---

[.column]


> "In 30 minutes, it produced something that would have normally been a seven-year PhD thesis"
-- David Friedberg, All-In Podcast

[.column]


![inline](img/david-friedberg-all-in.png)

March 13th, 2026

---

# It's gonna take your job!!11

![inline fill](img/job-market-1.jpeg)![inline fill](img/job-market-2.jpeg)

---

>[...] Research is now entirely the domain of autonomous swarms of AI agents running across compute cluster megastructures in the skies. [...] This repo is the story of how it all began.
-- @karpathy, March 2026.

---

![fit](img/autoresearch-core-loop.svg)


---

![inline](img/tweet.jpeg)

---

![inline](img/tobi-bundler-pr.png)

February 7 2026

---

[.column]

## 37 changes
## 8 merged
## 1 original to PR
## all by hand

[.column]

![inline](img/tobi-bundler-results.png)

[Post by Eileen Alayce](https://railsatscale.com/2026-03-18-engineering-rigor-in-the-ai-age-building-a-benchmark-you-can-trust/ )

---

![inline](img/tobi-liquid-pr.png)

^ Opened 6 weeks ago. Tests do not pass. Nothing merged. No activity

---

> "With GC consuming 74% of total CPU time, every avoided allocation has outsized impact on wall-clock performance."
--@tobi's Claude

---

![fit](img/gc-frequency-by-process-age.svg)

---

# Autoresearch
# doesn't work
# The End

---

# ![inline ](img/stan-lo.jpeg) Stan Lo
# [Reduces ruby-lsp CI time by 33% with 30 lines](https://github.com/Shopify/ruby-lsp/pull/4004)
# [Makes rubydex indexing ~10% faster](https://github.com/Shopify/rubydex/pull/659)
# [Makes another part of rubydex 50% faster](https://github.com/Shopify/rubydex/pull/654)

---

# Automatic
# _research_,
# not automatic
# _modification_

---

![fit autoplay loop mute](img/pi-demo.mp4)

---

# pi-autoresearch

## ![inline 12%](img/david-cortes.jpg) David Cortes, Shopify
## Implementation for the pi agent
## Status-line
## HTML and in-terminal dashboards
## Confidence scoring

---

![fit](img/sidekiq.png)

---

![fit autoplay mute](img/sidekiqload-fast.mp4)

---

![fit](img/sidekiqload-screenshot.png)

---

![fit](img/striped-lock-pr.png)

---

# what's Processor::Counter?
# atomic integer
# `PROCESSED = Counter.new`
# incr/decr before Redis flush
# 16 lines of code

---

# what's a striped lock?
# each thread gets its own state
# writes cheap
# reads expensive

---

# mike would
# literally
# never
# merge this

---

![fit inline](img/pr-2-screenshot.png)

^ This works because we are returning an integer directly rather than allocating a Time object and throwing it away

---

```text
Warming up --------------------------------------
       Time.now.to_i     1.271M i/100ms
Process.clock_gettime    1.708M i/100ms
Calculating -------------------------------------
       Time.now.to_i     12.698M (±0.9%) i/s (78.75 ns/i)
Process.clock_gettime    17.294M (±2.3%) i/s (57.82 ns/i)

Comparison:
Process.clock_gettime: 17294486.8 i/s
       Time.now.to_i: 12698329.6 i/s - 1.36x slower
```

---

![fit](img/pr-2-work-state-tracking.png)

---

# Mike
# would
# never
# merge this

---

[.column]

# What do we
# think about
# when we
# merge?

[.column]

![fit](img/merge-checks-passed.png)

---

# What is
# PR review
# _for_?

^ Have you ever been trained on how to do it? What are you expected to review?

---

# Why might we
# request
# changes?

---

# **"You didn't optimize X"**

```text
-fauto-inc-dec,-fbranch-count-reg,-fcombine-stack-adjustments,-fcompare-elim,-fcprop-registers,-fdce,-fdefer-pop
-fdelayed-branch,-fdse,-fforward-propagate,-fguess-branch-probability,-fif-conversion,-fif-conversion2
-finline-functions-called-once,-fipa-modref,-fipa-profile,-fipa-pure-const,-fipa-reference,-fipa-reference-addressable
-fivopts,-fmerge-constants,-fmove-loop-invariants,-fmove-loop-stores,-fomit-frame-pointer,-freorder-blocks,-fshrink-wrap
-fshrink-wrap-separate,-fsplit-wide-types,-fssa-backprop,-fssa-phiopt,-ftree-bit-ccp,-ftree-ccp,-ftree-ch
-ftree-coalesce-vars,-ftree-copy-prop,-ftree-dce,-ftree-dominator-opts,-ftree-dse,-ftree-forwprop,-ftree-fre
-ftree-phiprop,-ftree-pta,-ftree-scev-cprop,-ftree-sink,-ftree-slsr,-ftree-sra,-ftree-ter,-funit-at-a-time
-falign-functions,-falign-jumps,-falign-labels,-falign-loops,-fcaller-saves,-fcode-hoisting,-fcrossjumping
-fcse-follow-jumps,-fcse-skip-blocks,-fdelete-null-pointer-checks,-fdevirtualize,-fdevirtualize-speculatively
-fexpensive-optimizations,-ffinite-loops,-fgcse,-fgcse-lm,-fhoist-adjacent-loads,-finline-functions
-finline-small-functions,-findirect-inlining,-fipa-bit-cp,-fipa-cp,-fipa-icf,-fipa-ra,-fipa-sra,-fipa-vrp
-fisolate-erroneous-paths-dereference,-flra-remat,-foptimize-sibling-calls,-foptimize-strlen,-fpartial-inlining
-fpeephole2,-freorder-blocks-algorithm=stc,-freorder-blocks-and-partition,-freorder-functions,-frerun-cse-after-loop
-fschedule-insns,-fschedule-insns2,-fsched-interblock,-fsched-spec,-fstore-merging,-fstrict-aliasing,-fthread-jumps
-ftree-builtin-call-dce,-ftree-loop-vectorize,-ftree-pre,-ftree-slp-vectorize,-ftree-switch-conversion,-ftree-tail-merge
-ftree-vrp,-fvect-cost-model=very-cheap,-fgcse-after-reload,-fipa-cp-clone,-floop-interchange,-floop-unroll-and-jam
-fpeel-loops,-fpredictive-commoning,-fsplit-loops,-fsplit-paths,-ftree-loop-distribution,-ftree-partial-pre
-funswitch-loops,-fvect-cost-model=dynamic,-fversion-loops-for-strides
```

---

# **"There is a bug"**
# The bugbots (Cursor, etc) are
# pretty OK
# _at checking for bugs_

^ single axis

---

# **"There is a tradeoff"**
# Is a level of
# performance
# that is Good Enough?

---

# CPU: 50 microsec per job
# IO: 1000 microsec per job
# Possible improvement: ~5%

---

# Ugly/Complicated
# vs
# Fast Tradeoff

^ If a change is "ugly" or "complicated", would we merge it if it was 1% faster? What about 99%? Sometimes we're willing to trade, it's not binary

---

# **"This is too complicated"**
# Flog/flay loops,
# ABC scores,
# LOC count

---

# **"This is too risky"**
# The hardest problem
# in computer science is
# cache invalidation

^ Autoresearch LOVES caches. Is it even valid? It's certainly buggy!

---

# **"This passes tests, but..."**
# Autoresearch
# assumes you
# have good tests

---

# Is your test
# coverage 100%
# of what the app does?

^ Is it even possible to specify 100% of a piece of software?

---

# **"This violates HIPAA..."**
# Checks not in GitHub:
# legal
# compliance
# Memory use

---

![fit](img/sidekiq-133-checks-ui.png)

^ Based on the real checks from sidekiq/sidekiq#6895, then expanded into a deliberately fake “what else should GitHub check before merge?” UI.

---

![fit](img/pirates-architects-tweet.png)

---

# Anyone can now
# generate plausible software,
# the question is
# can you verify it is good?

---

# Don't autoresearch
# what you don't own
# and cannot Architect

---

# Now...
# what if AI
# was the Architect?

---

# AI-software-dev today is
# baby-sitting

![inline 80%](img/ai-babysitting-loop.svg)

---

# 1-4 windows open
# Scroll while it runs
# Steer, write messages

---

# "Just use
# this skill"

^ No evals, no backpressure, just vibes

---

[.column]

> When an AI Agent can produce a working implementation in minutes, waiting hours or days for a human to review it is an impedance mismatch.
--Kesha, Intercom

[.column]

![fit](img/prs-pile-up-converted.png)

---

> "What can I build today that I couldn't build before?"
-- Simon Willison

^ Resist the urge to anthromoprhize. Leverage the technology of a token generator, jagged intelligence

---

> The bitter lesson is based on the historical observations that
> 1) AI researchers have often tried to build knowledge into their agents,
> 2) this always helps in the short term, and is personally satisfying to the researcher, but
> 3) in the long run it plateaus and even inhibits further progress, and
> 4) breakthrough progress eventually arrives by an opposing approach based on scaling computation by search and learning.
-- Richard Sutton

---

# Loops apply the bitter lesson
# They scale compute
# Through allowing search
# and "brute force"

---

# Gate, loop

---

# Babysitting is looping
# With a human gate

---

# "Agents" are just a loop

---

# Ralph loop

```ruby
```

---

# Autoresearch takes ralph and
# unbounds it on a single variable

```ruby

```

---

> "Give me the right gate and I will move the earth" - Aristotle

---

# Putting things into software makes decisions explicit, less variation

---

# Loops are anti-skillsmaxxing

---

# Puma-release example: all the things I didn't forget

---

# Example: prosopite loop

---

# The factory is an autoresearch loop across arbitrary numbers of axes

---

# Curate some basic context for how to approach the problem, and make sure it has the right tools (mcp, cli, etc) to accomplish its task. benchmark-ips, vernier or stackprof, etc

---

# Production access: explain analyze on prod, prod console1984 (Intercom), etc

---

# Jagged intelligence: LLMs are not smarter than me, but they have far more attention/cycles

---

# In the dark factory, you will not be allowed inside

---

# Each review cycle is cost. Toyota got faster by eliminating QA and improving the system

---

# Sidekiq example:
# would we merge that
# if we didn't maintain it?

---

# Can we build a system
# that is verifiably correct
# without understanding
# what happens inside?

---

# In the factory,
# the software is mush,
# the gates are the artifact

---

# The software can be
# endlessly rebuilt
# refactoring has no meaning

Mie shrine

---

# Even if we fail,
# we'll be building
# better software

---

# StrongDM's concept

https://simonwillison.net/2026/Feb/7/software-factory/

---

# Attractor (and Fabro)

---

# Whenwords

---

# [Intercom](https://ideas.fin.ai/p/2x-nine-months-later)

---

# Ramp ("Glass")
# combines 1 MCP
# Skills marketplace
# Cron/Async

[Tweet](https://x.com/sebgoddijn/status/2042285915435937816) and [Tweet](https://x.com/buchan_sm/status/2044524727679566156)

---

# Risks

---

# Is merge-time the right gate?

What about in production at runtime via flippers?

[Tomash's post](https://tomash.wrug.eu/blog/2026/04/19/new-modularity/)

---

# What can be specified?

How? Property-based testing or formal verification?

> "Reasonable-looking algorithms can easily be incorrect. Algorithm correctness is a property that must be carefully demonstrated." - Steven Skiena

[Leo Domura](https://leodemoura.github.io/blog/2026-2-28-when-ai-writes-the-worlds-software-who-verifies-it/)

---

# Scalable?

> "There are two ways of constructing a software design: one way is to make it so simple that there are obviously no deficiencies, and the other is to make it so complicated that there are no obvious deficiencies." Tony Hoare, 1980 Turing Award Lecture

[Mutation and property testing are expensive](https://peterlavigne.com/writing/human-code-review-over-full-verification)

---

# Not worth the time?

SQLite's test suite is 590x larger than library itself

---

# Applicable to brownfield?

https://sqlite.org/cpu.html

^ It is extremely difficult to observe the behavior of an existing program in 100%/all aspects, it represents 25+ years of profiling and hard won changes which were never written down in a spec

---

# Intellectual property?

https://lucumr.pocoo.org/2026/3/5/theseus/

---

# How do you prevent runaway LOC?

[Mutation testing in REVERSE?](https://peterlavigne.com/writing/verifying-ai-generated-code)

---

# Where are we gonna run all this compute?

code-on-incus, etc

[The Bones of The Software Factory](https://blog.exe.dev/bones-of-the-software-factory)

---

# How much will be deterministic,
# and how much will be an LLM judge?
## _Who watches the watchmen?_

---

# Is rearranging the training data enough?

[Is byroot really going to emerge from the training data?](https://byroot.github.io/ruby/performance/2026/04/18/faster-paths.html)

---

# Runtime feature flags?
# What can be specified?
# Toy projects only?
# Is it too hard?
# Greenfield only?
# Is it copyrightable?
# Is LOC too high?
# Where will it run?
# Determinstic vs LLM gates
# Is byroot in the training data?

---

# Takeaways

---

# Best for low-attention code
# with a high-skill reviewer
# (Be Like Stan)

---

> "To truly use autoresearch effectively, you must first create the universe" - Carl Sagan

---

# Research without verification
# is waste.
# PRs created and not merged
# are waste.

---

# Start where
# you need
# the fewest
# gates

---

[.column: width(2)]
# Gate/eval
# design
[.column: width(1)]
# >
[.column: width(2)]
# code or
# skill design

---

# Try a loop:
# ralph (discrete)
# autoresearch (continuous)
# factory (multivariate)
