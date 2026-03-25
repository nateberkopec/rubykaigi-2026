# Autoresearching Ruby Performance with LLMs

**Status:** Accepted
**Format:** Regular Session
**Track:** General
**Speaker:** Nate Berkopec

---

## Abstract

AI agents (LLMs) are very good at automating the less-fun parts of programming. They're also very good at working in a loop: try something, verify if it worked, learn and try again. We'll talk about how to harness LLM agents to use "autoresearch" to fix performance problems, even in Ruby itself.

We'll show how to use a combination of LLMs, simple scripts, skills and MCPs to create reproducible benchmarks. These tools will combine to create an "agent-native" Ruby performance improving workbench. We'll also explore and discuss the limitations of these tools, including what kinds of problems they tend to be bad at solving.

---

## Talk Outline

1. **Performance: How To Solve Perf Problems**
   - Understanding "what is fast enough?"
   - Important tool 1: benchmarking
   - Important tool 2: profiling
   - An overview of a pre-LLM perf solving workflow

2. **How to make performance problems brute-forceable**

3. **An overview of the "Ruby Perf AI Agent Workbench"**
   - Skills
   - Tools
   - MCP
   - Prompts
   - Models and harnesses I've found useful

4. **How to make performance an LLM-able problem**

5. **How not to fool yourself (or be fooled) into thinking you fixed a problem but you actually didn't**

6. **What should you do with this incredible power?**
   - How to make useful issue reports for open source repositories
   - Why you shouldn't just open PRs you don't understand and can't verify

---

## For the Review Committee

I think developers right now probably have a lot of anxiety about LLMs and AI. They have a fear of missing out, and a fear that maybe they will lose their job. I'd like to teach Ruby developers a useful skill and application of LLMs that will help them to:

- Understand LLMs and how to work with them effectively
- Solve a useful problem (performance)
- Contribute back to Ruby and libraries they use, but in a way that doesn't burden maintainers with LLM slop

---

## Pitch

The 2025 program did not include any talks about LLMs except for a mention in Matz's keynote. Since 2025, the world of LLMs has really changed, and they have changed from a sort-of-useful curiosity into a tool used daily by most of RubyKaigi's attendees. Many attendees may not even write Ruby manually anymore, but instead just let the LLM write it for them. Because of that, I think talks about LLMs are important.

I have a lot of experience using these tools and know their limitations. I would like to see people use LLMs to make their applications faster and also to contribute more to Ruby, but in a way that is helpful and not putting more work on other OSS maintainers. I think I have some useful things to say about that.

---

## Speaker

**Nate Berkopec** is the owner of Speedshop, a Ruby on Rails performance consultancy, and the author of *The Complete Guide to Rails Performance*. Nate has taught Ruby and Rails performance skills in workshops all over the world, and is a contributor to several open source projects, such as Ruby on Rails, Puma and Sentry. His favorite Japanese musical artists are 山下 達郎, 角松 敏生 and カシオペア.

**Spoken Language:** English
