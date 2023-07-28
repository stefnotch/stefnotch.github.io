# Git Clients

(Status 2022)

Well, I'm just going to run you through the options

- The official CLI: Quite unintuitive. Also doesn't teach you very much at all about how Git actually works, you usually have to research that yourself. Standard beginner workflow with `git add .` is an anti-pattern that you have to un-teach people. (It leads to people not looking at what they're committing before they commit and push it)

- Alternate Git CLIs: They're proving my point. The official CLI is not something that I'd recommend. However, I don't have enough experience with the alternate CLIs, so I don't have one specific recommendation.

- [gitoxide](https://github.com/Byron/gitoxide) deserves a mention at thit point, despite very much being a work in progress. It's one of the more interesting Git rewrites out there.


**And now, time for the GUIs**

One major requirement is that they use the "branching" view by default. (`git log --graph`) One that lets you see the commits, and the branches that exist at the moment.

Mostly everything else is unwieldy for bigger projects, and ends up not mapping quite as nicely to the "make lots of branches" Git workflow.

- Official Git GUI: Technically functional, but somehow manages to be worse, or rather less popular, than the CLI.

- GitHub Desktop: Fails that requirement, see [this closed issue](https://github.com/desktop/desktop/issues/1634)

- VSCode: Fails the requirement, though there's [an extension](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph) that I've not tried out yet.

- Intellij: Yay, a decent-ish Git client. Major pain point at the moment is that they're using different terms for a lot of common operations, which leaves you wondering "what does that mean" and once you figure it out, congrats on successfully teaching yourself something that a single vendor uses. (aka vendor lock-in)

- Git Fork: Quite lovely. One catch is that the name makes it terribly difficult to look up anything at all if you've got a question. Like seriously, try looking up "git fork three way merge".

- GitKraken: That's what I use at the moment. It has a somewhat decent "undo" button, which should be standard in all Git clients. Issues include its startup time, its price (subscription model), the fact that it's slow when discarding thousands of changed files at once, ...

- Most 3rd party GUIs out there ([kudos to Git for maintaining a lovely list](https://git-scm.com/downloads/guis)) are either quite limited, abandoned, un-fun to use, are expensive paid software, only work on one operating system or have some combination of factors that make it a no-go. I'd know, I've checked out most of them. *If there's one that you think deserves a mention, do send it my way!*
 

So, here we go. I think I've successfully complained about every option on the market.
