---

# Autoresearch: LLM-Powered Performance Engineering for Ruby

**Nate Berkopec** — RubyKaigi 2026

---

# The Hook

Karpathy sets the world on fire: **"autoresearch"**

---

# What Was Accomplished

- A tweet that coined a term and launched a movement
- Automated research loops producing real results
- Developer anxiety: FOMO, job fears
- Is this the singularity? The take-off?

---

# Who Am I?

**Nate Berkopec**

- CGRP, Puma, Speedshop, Threadpilot
- I've taught performance workshops for years
- I consider myself a "maker" rather than a programmer

---

# My Journey

- LLMs didn't threaten me the way I saw others react
- My git commit count **exploded**
- The entire dev job description has changed
- Opus 4.5 / Codex 5 was a turning point in December

---

# Still a Rubyist?

- In some ways, I no longer consider myself a Rubyist
- But I want to continue as a hobby — it's still nicer to read!
- What I want: **automate the drudgery, do the fun "software engineering"**

---

# Today's Roadmap

1. Performance engineering fundamentals
2. General principles of LLM-powered development
3. Autoresearch design
4. What LLMs don't change
5. The Ruby autoresearch harness
6. Real-world applications

---

# Performance Engineering

How does performance engineering work, in the abstract?

**Engineering:** meeting requirements within constraints

---

# Tool 1: Benchmarking

What still matters:

- Warmup
- Noise
- Insufficient samples
- GC interference

---

# Tool 2: Profiling

- Sample size is important
- Resolution matters

---

# Tool 3: RUM and APM

- Real User Monitoring
- Application Performance Monitoring
- What pre-LLM perf workflows looked like

---

# General Principles of LLM-Powered Development

- I use Pi, Codex, and Claude (see dotfiles)
- I don't just ask — I ask it to come with a benchmark or test
- Review the test, come back in 10 minutes

---

# The Software Factory

- Verify, **never trust**
- LLMs tend to want to write MORE — not always correct
- Onerous linting is actually encouraged
- LLM judges are not really useful

---

# The Bitter Lesson

Loops allow us to apply the bitter lesson

Best when used against a **deterministic standard**

---

# Autoresearch Design: Creating Evals

- Software is not single-variable
- Even performance is not single-variable
- Autoresearch is fundamentally about making the problem **brute-forceable**

---

# Autoresearch Constraints

- We can't break software in pursuit of optimizing a single variable
- We can't make other parts slow
- We can't exceed memory usage constraints

---

# What LLMs Don't Change

- We can't ship slop
- No thousand-line diffs
- All of software engineering still applies

---

# LLMs Are Amplifiers, Not Gods

They autocomplete and amplify what already exists.

If you have slop, it will amplify slop.

---

# The "Why Don't You Just" Problem

Weaponized nerd-sniping

You could make Claude split that into 12 PRs of 100 lines or less.

---

# Autoresearch Ruby History

- Tobi
- Bundler / Eileen
- Stan Lo

---

# The Ruby Autoresearch Harness

- **Skills**
- **Tools**
- **MCPs**
- **Prompts**
- Sandboxes, remotes, and security
- Knowing when to stop

---

# Real-World Applications

Let's apply to:

- **Puma**
- **Threadpilot**
- **Sidekiq**
- **Rails**

---

# How to Be a Good OSS Contributor

- How to make useful issue reports
- Why you shouldn't just open PRs you don't understand and can't verify

---

# Takeaways

1. ...
2. ...
3. ...

Find more resources here: *(link)*

---

# Thank You!

**Nate Berkopec**

RubyKaigi 2026
