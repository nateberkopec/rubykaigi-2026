- **THE HOOK** Karpathy sets the world on fire: the coining of "autoresearch"
    - Explain the tweet
    - Explain what was accomplished
    - Developer anxiety: FOMO, job fears
    - Is this the singularity? The take-off?
- **BIG IDEA** All of our work, including performance, is changing from building the thing, to building the thing that builds the thing. What is a "performance factory" and how do we build one?
- **WHO AM I** I'm Nate Berkopec!
    - CGRP, Puma, Speedshop, Threadpilot
    - Retainer revenue chart w/o the y-axis
    - I've taught workshops on these topics for years, how difficult it was to teach
    - I consider myself primarily a "maker" rather than a programmer, so LLMs didn't threaten me in the way I saw others react
    - My git commit count exploded. I think the entire dev job description has changed.
    - Opus 4.5/Codex 5 was a turning point in December
    - In some ways, I no longer consider myself a Rubyist
    - However, I want to continue to be a Rubyist as a hobby. And it's still nicer to read!
    - What I want: automate the drudgery, do the fun "software engineering"
    - Overview of where we're going to go today
- **PERF ENGINEERING** So, in the abstract, how does performance engineering work?
    - Engineering: meeting requirements within constraints
    - What requirements do we usually have?
        - Latency
        - Resource efficiency
        - Robustness
    - Tool 1: benchmarking
        - What still matters: warmup, noise, insufficient samples, GC
    - Tool 2: profiling
        - Sample size is important, resolution
    - Tool 3: RUM and APM
    - What pre-LLM perf workflows looked like with these three tools put together
- **GENERAL PRINCIPLES OF LLM POWERED SOFTWARE DEVELOPMENT**
    - Briefly: I use pi, codex and claude. see dotfiles.
    - I don't just ask. I ask it to come with a benchmark or a test that would demonstrate what is true, review the test, then come back in 10 minutes when it's demonstrated what is true conclusively.
    - Software factory
    - Verify, never trust
    - LLMs tend to want to write MORE, which is not always the correct solution
    - Onerous linting is actually encouraged
    - LLM judges are not really useful
    - Loops allow us to apply the bitter lesson, but are best when used against a deterministic standard
- **AUTORESEARCH DESIGN** Creating evals
    - How "Ralphing" becomes "Autoresearch"
    - Software is not single-variable
    - Even performance is not single-variable
    - Looping is fundamentally about making the problem brute-forceable
    - Autoresearch design principles:
        -
        -
        -
- **WHAT LLMS DONT CHANGE**
    - We can't break software (or make other parts of it slow, or exceed memory usage constraints) in pursuit of optimizing a single variable. THIS IS IS THE HARD PART.
    - We can't ship slop.
    - You could make claude split that into 12 PRs of 100 lines or less.
    - No thousand line diffs.
    - Weaponized "why don't you just" nerd sniping
    - All of software engineering and development still applies
    - LLMs are amplifiers, not gods. They autocopmlete and amplify what already exists. If you have slop, it will amplify slop.
- **AUTORESEARCH RUBY HISTORY**
    - Tobi
    - Bundler/Eileen
    - Stan Lo
- **THE RUBY AUTORESEARCH HARNESS**
    - Skills:
        -
    - Tools:
        -
    - MCPs:
        -
    - Prompts:
        -
    - Sandboxes, remotes and security
    - Overview of harnesses and models
    - Knowing when to stop
- Let's apply to **Puma**, **Threadpilot**, **Sidekiq** and **Ruby**.

- **HOW TO BE A GOOD OSS CONTRIBUTOR**
    - How to make useful issue reports for open source repositories
   - Why you shouldn't just open PRs you don't understand and can't verify
- Takeaways
    - 1: Research without verification is waste.
    - 2: De-risk what you can
    - 3: Use my toolkit:
- Thank you!

REMAINING RESEARCH HOURS

1. Autoresearch history (karpathy)
1. Perf eng/gen principles/llms dont change slides
1. Autoresearch Ruby History
2. Autoresearch "design" principles (pi-autoresearch, etc)
3. Defining the harness
4. Puma
5. Threadpilot
6. Sidekiq
7. Ruby
8. Takeaways
