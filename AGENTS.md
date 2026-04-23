This repository generates a presentation for RubyKaigi 2026, on the topic of "autoresearch" with LLMs.

Andrej Karpathy released **autoresearch** in March 2026 as a minimal, open-source tool that automates ML experimentation on a single GPU. It runs an autonomous loop: an AI coding agent proposes and applies modifications to an ML training script, trains for exactly 5 minutes, evaluates against a baseline metric, and keeps only changes that improve performance — then repeats indefinitely. With no dependencies beyond PyTorch and a single main file, it lets researchers run ~12 experiments per hour (~100 overnight). Karpathy demonstrated it by letting the agent run autonomously for two days, making ~700 code changes and achieving an 11% efficiency gain on the "Time to GPT-2" benchmark; the repo hit 21k+ GitHub stars within days of release.

Autoresearch as a concept is essentially allowing LLMs to brute-force optimize along a single variable axis.

This presentation is about how to apply that concept to all kinds of performance optimization in the Ruby domain.

This presentation is compiled for and by Nate Berkopec, the maintainer of Puma and owner of Speedshop, a Rails performance consultancy.

./archive contains a bunch of old code and previous versions of this presentaiton. It is not relevant anymore, don't read that stuff unless the user explicitly directs you to.

The presentation is given in Deckset via DECKSET.md.

Nate's favorite speakers are: Seth Godin, Justin Searls, Bret Victor, Nicholas Means, LEMMiNO, and Nexpo.


