---

# [fit] Autoresearching Ruby Performance with LLMs

**Nate Berkopec**

RubyKaigi 2026

---

# THE HOOK

Karpathy sets the world on fire: the coining of "autoresearch"

---

# THE HOOK

## Explain the tweet

---

# THE HOOK

## Explain what was accomplished

---

# THE HOOK

## Developer anxiety: FOMO, job fears

---

# THE HOOK

## Is this the singularity? The take-off?

---

# BIG IDEA

All of our work, including performance, is changing from building the thing, to building the thing that builds the thing. What is a "performance factory" and how do we build one?

---

# WHO AM I

I'm Nate Berkopec!

---

# WHO AM I

## CGRP, Puma, Speedshop, Threadpilot

---

# WHO AM I

## Retainer revenue chart w/o the y-axis

---

# WHO AM I

## I've taught workshops on these topics for years, how difficult it was to teach

---

# WHO AM I

## I consider myself primarily a "maker" rather than a programmer, so LLMs didn't threaten me in the way I saw others react

---

# WHO AM I

## My git commit count exploded. I think the entire dev job description has changed.

---

# WHO AM I

## Opus 4.5/Codex 5 was a turning point in December

---

# WHO AM I

## In some ways, I no longer consider myself a Rubyist

---

# WHO AM I

## However, I want to continue to be a Rubyist as a hobby. And it's still nicer to read!

---

# WHO AM I

## What I want: automate the drudgery, do the fun "software engineering"

---

# WHO AM I

## Overview of where we're going to go today

---

# PERF ENGINEERING

So, in the abstract, how does performance engineering work?

---

# PERF ENGINEERING

## Engineering: meeting requirements within constraints

---

# PERF ENGINEERING

## What requirements do we usually have?

---

# PERF ENGINEERING

## What requirements do we usually have?

### Latency

---

# PERF ENGINEERING

## What requirements do we usually have?

### Resource efficiency

---

# PERF ENGINEERING

## What requirements do we usually have?

### Robustness

---

# PERF ENGINEERING

## Tool 1: benchmarking

---

# PERF ENGINEERING

## Tool 1: benchmarking

### What still matters: warmup, noise, insufficient samples, GC

---

# PERF ENGINEERING

## Tool 2: profiling

---

# PERF ENGINEERING

## Tool 2: profiling

### Sample size is important, resolution

---

# PERF ENGINEERING

## Tool 3: RUM and APM

---

# PERF ENGINEERING

## What pre-LLM perf workflows looked like with these three tools put together

---

# GENERAL PRINCIPLES OF LLM POWERED SOFTWARE DEVELOPMENT

---

# GENERAL PRINCIPLES OF LLM POWERED SOFTWARE DEVELOPMENT

## Briefly: I use pi, codex and claude. see dotfiles.

---

# GENERAL PRINCIPLES OF LLM POWERED SOFTWARE DEVELOPMENT

## I don't just ask. I ask it to come with a benchmark or a test that would demonstrate what is true, review the test, then come back in 10 minutes when it's demonstrated what is true conclusively.

---

# GENERAL PRINCIPLES OF LLM POWERED SOFTWARE DEVELOPMENT

## Software factory

---

# GENERAL PRINCIPLES OF LLM POWERED SOFTWARE DEVELOPMENT

## Verify, never trust

---

# GENERAL PRINCIPLES OF LLM POWERED SOFTWARE DEVELOPMENT

## LLMs tend to want to write MORE, which is not always the correct solution

---

# GENERAL PRINCIPLES OF LLM POWERED SOFTWARE DEVELOPMENT

## Onerous linting is actually encouraged

---

# GENERAL PRINCIPLES OF LLM POWERED SOFTWARE DEVELOPMENT

## LLM judges are not really useful

---

# GENERAL PRINCIPLES OF LLM POWERED SOFTWARE DEVELOPMENT

## Loops allow us to apply the bitter lesson, but are best when used against a deterministic standard

---

# AUTORESEARCH DESIGN

Creating evals

---

# AUTORESEARCH DESIGN

## How "Ralphing" becomes "Autoresearch"

---

# AUTORESEARCH DESIGN

## Software is not single-variable

---

# AUTORESEARCH DESIGN

## Even performance is not single-variable

---

# AUTORESEARCH DESIGN

## Looping is fundamentally about making the problem brute-forceable

---

# AUTORESEARCH DESIGN

## Autoresearch design principles:

---

# WHAT LLMS DONT CHANGE

---

# WHAT LLMS DONT CHANGE

## We can't break software (or make other parts of it slow, or exceed memory usage constraints) in pursuit of optimizing a single variable. THIS IS IS THE HARD PART.

---

# WHAT LLMS DONT CHANGE

## We can't ship slop.

---

# WHAT LLMS DONT CHANGE

## You could make claude split that into 12 PRs of 100 lines or less.

---

# WHAT LLMS DONT CHANGE

## No thousand line diffs.

---

# WHAT LLMS DONT CHANGE

## Weaponized "why don't you just" nerd sniping

---

# WHAT LLMS DONT CHANGE

## All of software engineering and development still applies

---

# WHAT LLMS DONT CHANGE

## LLMs are amplifiers, not gods. They autocopmlete and amplify what already exists. If you have slop, it will amplify slop.

---

# AUTORESEARCH RUBY HISTORY

---

# AUTORESEARCH RUBY HISTORY

## Tobi

---

# AUTORESEARCH RUBY HISTORY

## Bundler/Eileen

---

# AUTORESEARCH RUBY HISTORY

## Stan Lo

---

# THE RUBY AUTORESEARCH HARNESS

---

# THE RUBY AUTORESEARCH HARNESS

## Skills:

---

# THE RUBY AUTORESEARCH HARNESS

## Tools:

---

# THE RUBY AUTORESEARCH HARNESS

## MCPs:

---

# THE RUBY AUTORESEARCH HARNESS

## Prompts:

---

# THE RUBY AUTORESEARCH HARNESS

## Sandboxes, remotes and security

---

# THE RUBY AUTORESEARCH HARNESS

## Overview of harnesses and models

---

# THE RUBY AUTORESEARCH HARNESS

## Knowing when to stop

---

# [fit] Let's apply to **Puma**, **Threadpilot**, **Sidekiq** and **Ruby**.

---

# HOW TO BE A GOOD OSS CONTRIBUTOR

---

# HOW TO BE A GOOD OSS CONTRIBUTOR

## How to make useful issue reports for open source repositories

---

# HOW TO BE A GOOD OSS CONTRIBUTOR

## Why you shouldn't just open PRs you don't understand and can't verify

---

# Takeaways

---

# Takeaways

## 1: Research without verification is waste.

---

# Takeaways

## 2: De-risk what you can

---

# Takeaways

## 3: Use my toolkit:

---

# Thank you!
