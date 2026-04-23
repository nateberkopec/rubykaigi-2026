The Tweet
The dream??? Engineering is solved!
The autoresearch core loop
Tobi tweets go viral, all-in podcast
FOMO, job market is crashing
THIS IS THE TAKEOFF/SKYNET
Tobi bundler PR (https://github.com/ruby/rubygems/pull/9316)
37 changes proposed. 8 merged, only 1 original to the PR, all re-implemented by hand. https://railsatscale.com/2026-03-18-engineering-rigor-in-the-ai-age-building-a-benchmark-you-can-trust/
Tobi liquid PR (https://github.com/Shopify/liquid/pull/2056)
Dead in the water, nothing merged, specs failing
"74% of total CPU time is GC" - Agents make biased/wrong assumptions
Stan Lo PRs maybe more successful on less legacy projects  https://github.com/Shopify/ruby-lsp/pull/4004, https://github.com/Shopify/rubydex/pull/659, https://github.com/Shopify/rubydex/pull/666 (different human-based resolution to a problem noticed by autoresearch), https://github.com/Shopify/rubydex/pull/654,
Automatic _research_, not automatic _modification_
pi-autoresearch
components of pi-autoresearch
sidekiq has a benchmark ready to go
ascii recording
PR 1: striped lock
what is this lock for
what's a striped lock
mike would literally never merge this
PR 2: Time.now.to_i to Process::CLOCk
How does this benchmark?
More complicated work-state tracking thing
Mike would never merge this
How does each change benchmark?
What do we think about when we merge something?
What the heck is a pull request review for? Have you ever been trained on how to do it? What are you expected to review?
The GCC compiler checks for 300 things at -O3 on every single line. Are you doing this?
The bugbots are pretty good, but this is just one axis.
Is there a certain level of performance that is Good Enough?
If a change is "ugly" or "complicated", would we merge it if it was 1% faster? What about 99%? Sometimes we're willing to trade, it's not binary
Can we put numbers to how "ugly" or "complicated" something is?
Flog/flay loops, ABC scores, LOC count
Cache - risk of bugs
Difference in environment not captured by benchmark
Assumes the spec is complete, it cannot be
An entire universe of other thing which are not checks in github: legal, compliance, etc etc
Autoresearch is the pirate, you are the architect https://x.com/danshipper/status/2043819933675450455
No one wants a pirate without an architect, don't autoresearch what you don't own
Anyone can now generate plausible software, the question is can you verify it is good
Do we really need more pirates? Or do we need more architects?
How AI-software-dev works today: babysitting
Description of the typical workflow
PRs pile up, code quality decreases as human review is overwhelmed
Existing process with a slopcannon
"What can I build today that I couldn't build before?" - Simon Willison
Loops apply the bitter lesson
Gate, loop
Declarative programming similarity https://x.com/headius/status/2043857261714362587
Autoresearch is a slight evolution of the Ralph loop
"Agents" are just a loop
Ralph is a particular automation of that loop
Autoresearch takes ralph and unbounds it on a single variable
"Give me the right gate and I will move the earth"
Putting things into software makes decisions explicit, less variation
Loops are anti-skillsmaxxing
Puma-release example: all the things I didn't forget
Example: prosopite loop
The factory is an autoresearch loop across arbitrary numbers of axes
Curate some basic context for how to approach the problem, and make sure it has the right tools (mcp, cli, etc) to accomplish its task. benchmark-ips, vernier or stackprof, etc
Production access: explain analyze on prod, prod console1984 (Intercom), etc
Jagged intelligence: LLMs are not smarter than me, but they have far more attention/cycles
In the dark factory, you will not be allowed inside
Each review cycle is cost. Toyota got faster by eliminating QA and improving the system https://apenwarr.ca/log/20260316
Back to the Sidekiq example: would we merge that?
Can we build a system that is verifiably correct without understanding what happens inside?
In the factory, the software is mush, the gates are the artifact
The software can be endlessly annihalated and rebuilt, refactoring has no meaning
Even if we fail, we'll be building better software
StrongDM's concept https://simonwillison.net/2026/Feb/7/software-factory/
Attractor (and Fabro)
Whenwords
Intercom https://ideas.fin.ai/p/2x-nine-months-later
Ramp ("Glass") combines 1 MCP, Skills marketplace, Cron/Async, https://x.com/sebgoddijn/status/2042285915435937816 https://x.com/buchan_sm/status/2044524727679566156
What remains to be proven, risks
Is merge-time the right gate? What about in production at runtime via flippers? https://tomash.wrug.eu/blog/2026/04/19/new-modularity/
What can be specified? How? Property-based testing or formal verification? https://leodemoura.github.io/blog/ 2026-2-28-when-ai-writes-the-worlds-software-who-verifies-it/
    Steven Skiena writes in The Algorithm Design Manual: "Reasonable-looking algorithms can easily be incorrect. Algorithm correctness is a property that must be carefully demonstrated."
Can it be scaled?
    In the 1980 Turing Award lecture Tony Hoare said: "There are two ways of constructing a software design: one way is to make it so simple that there are obviously no deficiencies, and the other is to make it so complicated that there are no obvious deficiencies."
    Mutation and Property are expensive https://peterlavigne.com/writing/human-code-review-over-full-verification
Is it too onerous? Not worth the time?
    SQLite's test suite is 590x larger than library itself
Can it be applied to brownfield projects?
    It is extremely difficult to observe the behavior of an existing program in 100%/all aspects, it represents 25+ years of profiling and hard won changes which were never written down in a spec
    https://sqlite.org/cpu.html
What happens to intellectual property? https://lucumr.pocoo.org/2026/3/5/theseus/
How do you prevent runaway LOC? LLMs want to expand
    mutation testing in REVERSE https://peterlavigne.com/writing/verifying-ai-generated-code
Where are we gonna run all this compute? code-on-incus, etc https://blog.exe.dev/bones-of-the-software-factory
How much will be deterministic, and how much will be an LLM judge? (Skeptical: who watches the watchmen?)
Is rearranging the training data enough? What happens when it isn't? https://byroot.github.io/ruby/performance/2026/04/18/faster-paths.html
Takeaways
4-square plot: Attention already applied to code, skill of the reviewer
"To use autoresearch effectively you must first create the universe"
Research without verification is waste. PRs created and not merged are waste.
The fewer the gate count, the more likely it is we can loop productively
Gate/eval design > code or skill design
Apply more effort and humanness to the spec, eval, gate, and the test, less to the code
Try a loop today: autoresearch, factory (yamiochi), "ralph"
