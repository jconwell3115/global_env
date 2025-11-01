---
title: "Copilot ask, edit, and agent modes: What they do and when to use them"
source: "https://github.blog/ai-and-ml/github-copilot/copilot-ask-edit-and-agent-modes-what-they-do-and-when-to-use-them/?utm_campaign=LCM_CopilotProOnboarding_dev&utm_source=github&utm=medium=email"
author:
  - "[[Ashley Willis]]"
published: 2025-05-02
created: 2025-09-01
description: "An introduction to GitHub Copilot's three distinct modes and a practical guide for integrating them effectively into your workflow."
tags:
  - "clippings"
---
If you have opened Copilot Chat in VS Code lately and didn’t notice the tiny dropdown hiding at the bottom, you’re not alone. It’s easy to miss, especially when you’re heads down trying to get something shipped. That little menu is where you can switch between ask, edit, and agent modes—three ways you can integrate Copilot into your workflow.

<video controls="" src="https://github.blog/wp-content/uploads/2025/05/7628641195839613148mode-selector.mp4"></video>

But here’s the thing: Each of these modes does something pretty different. And depending on what kind of developer you are, how much context you have, or how much control you’re comfortable giving [GitHub Copilot](https://github.com/features/copilot), you might have a very different experience with each one.

I’ve been using all three in different ways, from building apps and testing ideas to playing with frameworks I haven’t touched in a while. I’ve also spent time talking to other developers about what’s working for them.

Below is what I’ve learned so far. This isn’t *the* manual (for that, look at the [VS Code documentation](https://code.visualstudio.com/docs/copilot/chat/copilot-chat#_chat-mode)). It’s more of a guide for how to think about these tools, as you navigate where they fit into your own workflow.

## Ask mode: The quick gut check

Ask mode is the simplest of the three—and if you are a long-time user of GitHub Copilot, it might be the only time you’ve thought about bringing up the Chat window.

Here’s how it works: You highlight some code, type a question into Copilot Chat, and it generates an answer. It might explain what the code does, suggest how to test it, give you a code snippet that implements what you are asking about, or remind you how to handle a particular edge case.

Ask mode is fast, helpful, and focused entirely on answering your programming question without touching your code. You can stay in your editor and ask questions that Copilot can answer using all the context of your current editor environment. Think of it like a quiet little whisper in your editor saying, “Hey, here’s what I think this means.”

And it’s not just about your code. You can ask it anything related to programming—like how to use a certain library, how to structure a SQL query, and even which search algorithm is more efficient for a given dataset.

Need help styling something with Tailwind? Want a refresher on closures in JavaScript? Curious how to debounce an input in React? Copilot can help with that, too.

There’s no project commitment, no architectural decisions, and no code changes. Just answers, right when you need them. It’s the lowest-friction way to get unstuck when a question is standing in the way of you and building what’s next.

## Edit mode: You’re still in charge, just moving faster

Edit mode in VS Code is where things start to get more interesting. It lets you pick any number of files in your project you want to change and describe the update in natural language. Then, Copilot will immediately apply inline, review-ready code edits across those files.

Edit mode is perfect when you know what you want to do but don’t necessarily want to write it all out yourself. You highlight a block of code, type in an instruction—perhaps something like “add error handling” or “refactor this using async/await”—and Copilot rewrites the code for you. But (and this is important) it doesn’t save anything without showing you the diff first.

That’s what makes edit mode so reliable. Copilot does the work, but you get the final say. You’re not handing over the reins. You’re speeding things up while staying fully in the loop.

You can also [bring custom instructions](https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot) into edit mode if you want to level it up a bit. It’s a way to teach Copilot how you and your team like to write code, including your style preferences, how verbose or concise you want it to be, what your team’s standards are, how formal or casual you want it when it explains things, and even what language you want your comments written in. Setting up those preferences is like giving Copilot a playbook ahead of time—so when you say “clean this up,” it already knows what “clean” actually means to you.

I’ve found myself reaching for edit mode when I’m deep in a brownfield app and don’t want to touch the rest of the system, or when I’m just trying to get through a handful of small but annoying improvements with surgical precision. It’s not trying to redesign your architecture. It’s not going to rename things you didn’t ask it to. It’s just here to make the thing you’re working on better and faster, with less mental overhead.

Honestly, once you get used to it, it’s hard to go back.

## Agent mode: A lot of power, when you’re ready for it

Now let’s talk about Agent mode. Agent mode lets you hand it a high-level prompt and then watch as Copilot autonomously plans the steps, selects the right files, runs tools or terminal commands, and iterates on code edits until the task is complete.

It is by far the most powerful mode in Copilot Chat—and also the newest, which means for a lot of people, it’s still the least familiar. Agent mode can reason across your entire project, take multi-step actions, and hold onto a significant amount of context across a session. You can ask it to build features, fix bugs, create files, clean up routing logic, or even scaffold an entire section of an app based on a single prompt.

<video controls="" src="https://github.blog/wp-content/uploads/2025/05/sn0404-agent-dark.mp4"></video>

At first glance, agent mode can look like an expanded version of edit mode—and in some respects, it is. But there’s a crucial distinction: Instead of only rewriting the lines you specify, agent mode analyzes related code, identifies additional changes that may be required, and applies them across the project to keep everything consistent.

Another key distinction? Agent mode applies edits automatically rather than waiting for explicit approval, while still surfacing any potentially risky commands for review before they run.

The workflow is closer to a continuous-edit “driver” model: The developer defines the goal, and Copilot executes updates without stopping for permission at every step.

For some developers, that feels natural and empowering. For others, it can feel like giving up a little more control than you are used to.

One thing that makes agent mode even better in real-world projects is [custom instructions](https://code.visualstudio.com/docs/copilot/copilot-customization#_custom-instructions), which I mentioned above. This is where you can really start shaping how Copilot behaves across a session.

For example, here are the custom instructions we used with agent mode in one of our demo projects:

```markdown
This is a Next.js-based travel application with TypeScript that helps users search for trips, manage bookings, view travel guides, and track points. The application uses React components, server components, and client components as part of the Next.js App Router architecture. Please follow these guidelines when contributing:

## Code Standards

### Required Before Each Commit
- Run \`npm run lint\` to ensure code follows project standards
- Make sure all components follow Next.js App Router patterns
- Client components should be marked with 'use client' when they use browser APIs or React hooks
- When adding new functionality, make sure you update the README
- Make sure that the repository structure documentation is correct and accurate in the Copilot Instructions file
- Ensure all tests pass by running \`npm run test\` in the terminal

### TypeScript and React Patterns
- Use TypeScript interfaces/types for all props and data structures
- Follow React best practices (hooks, functional components)
- Use proper state management techniques
- Components should be modular and follow single-responsibility principle

### Styling
- You must prioritize using Tailwind CSS classes as much as possible. If needed, you may define custom Tailwind Classes / Styles. Creating custom CSS should be the last approach.

## Development Flow
- Install dependencies: \`npm install\`
- Development server: \`npm run dev\`
- Build: \`npm run build\`
- Test: \`npm run test\`
- Lint: \`npm run lint\`

## Repository Structure
- \`app/\`: Next.js App Router pages and layouts organized by route
- \`components/\`: Reusable React components
  - \`components/ui/\`: UI components (buttons, inputs, etc.)
  - \`components/__tests__/\`: Component tests
- \`lib/\`: Core logic and services
  - \`lib/data/\`: Data models and mock data
  - \`lib/types/\`: TypeScript type definitions
- \`public/\`: Static assets
- \`tests/\`: Test files and test utilities
- \`README.md\`: Project documentation

## Key Guidelines
1. Make sure to evaluate the components you're creating, and whether they need 'use client'
2. Images should contain meaningful alt text unless they are purely for decoration. If they are for decoration only, a null (empty) alt text should be provided (alt="") so that the images are ignored by the screen reader.
3. Follow Next.js best practices for data fetching, routing, and rendering
4. Use proper error handling and loading states
5. Optimize components and pages for performance
```

If you’ve ever noticed that agent mode sometimes forgets how it structured your backend when it later builds the frontend, you’re not imagining things. The context window is big (and getting bigger all the time), but it’s still finite. Instead of stuffing every little reminder into your prompts, you can use custom instructions to set some ground rules ahead of time: things like how you want APIs called, naming patterns you want followed, or even stylistic preferences across your codebase. It gives agent mode a stronger foundation to work from, which means you get more consistency without needing to micromanage every step.

I won’t go too deep into custom instructions here (the [VS Code documentation does a great job](https://code.visualstudio.com/docs/copilot/copilot-customization#_custom-instructions)), but if you are working across multiple sessions or building something bigger than a one-off script, they are absolutely worth looking into. It has made a noticeable difference for me, especially on side projects where I want to move fast but keep some structure in place.

I have had some really strong results using agent mode this way. I’ve started projects by dropping a README into a new repo, setting a clear vision for what I want, and letting Copilot take the first pass. It builds out components, layouts, routes, and even seeds the content. It isn’t perfect straight out of the gate (and it shouldn’t be), but it gets me so much closer to a usable starting point than building from scratch. The more detailed and thoughtful my initial prompts and setup, the better agent mode performs.

Of course, it’s still important to stay engaged. Occasionally, agent mode might suggest running a command you don’t expect. Or it might touch a file you thought you had agreed to leave alone. And sometimes, it just takes a little longer to reason through things, especially on bigger projects.

In live demo situations where time is tight, that unpredictability can definitely make things more… exciting. But when I’m building day-to-day, especially when experimenting or kicking off a new project, agent mode fits naturally into my creative process.

Working with agent mode is a lot like pairing with that brilliant friend who moves fast and sometimes thinks three steps ahead. If you’re aligned, amazing things can happen. If you’re not, you might have to nudge them back onto the path you want.

The key is good communication prompt files, thoughtful initial instructions, and clear nudges along the way. This keeps the collaboration productive and fun.

## So what does this mean for senior developers?

This question has come up a lot in conversations with my team. Agent mode definitely feels like the future when you use it, but just because it is powerful does not mean it is always the right tool for the job. Sometimes you’ll be working on part of a codebase that needs to be handled with a little more precision. If you are tweaking a couple of files or making a targeted change in a sensitive system, ask or edit mode might be the better fit.

A lot of the time, the most experienced developers are the ones who know exactly which parts of a system should be touched carefully, or maybe not touched at all, to avoid bigger problems later. That isn’t about being cautious for the sake of it. It’s about understanding the complexity that lives under the surface.

And here’s something important: Agent mode isn’t just for people who are new to building software. In a lot of ways, it actually works best when the person using it knows how to give clear, strong instructions—and the nuances of code and algorithmic structures. If you know how your system is structured, where the fragile edges are, and when to review changes vs. when to trust the flow, you’re in a great spot to get real value out of agent mode. That is senior dev territory.

Of course, strong opinions come with the territory too. Agent mode is doing its best, but unless you are explicit about the rules you want it to follow, it isn’t going to automatically pick up your conventions. That is where custom instructions come into the picture. When senior engineers write down the things they normally just know: the naming patterns, the design principles, the places to be careful, and commit those into version control alongside the project, it gives the entire team a better experience. It doesn’t just make agent mode faster—it helps it give you better suggestions, too.

There will still be plenty of moments where edit mode feels like the better choice. When you just need a second set of eyes without handing over the whole keyboard, edit mode keeps you moving without ever getting too far ahead. And that’s fine.

Honestly, I think that as a community we could do a better job showing how agent mode complements expertise instead of only showing it in greenfield examples. Demos that start from zero are easy to understand. But in the real world, most developers are iterating on existing systems—not spinning up a new app every week. Showing how Copilot fits into that kind of work—the messy, important middle—is where things really get exciting.

## Take this with you

Ask, edit, and agent modes aren’t three versions of the same tool. They’re three completely different and unique experiences within GitHub Copilot. Ask mode is the quick way to get an answer to your question. Edit mode is the assistant telling you what it recommends across your files. And agent mode is the assistant that just goes ahead and does what it thinks you are asking for—which is great as long as it’s following your spoken (and unspoken) instructions.

If you’ve only tried one mode so far, now’s a good time to play around. Try using agent mode with a fresh repository. Or try using edit mode on a complex refactoring job you’ve been putting off. And maybe try using ask mode when you’re trying to remember what a slice reducer does because it’s Monday and your brain’s still booting up.

All of these tools are designed to complement your judgment. They’re here to help you do your job better, whatever that looks like for you.

And no matter what, always read the diff.

## Written by

## Related posts

[AI & ML](https://github.blog/ai-and-ml/)

### Under the hood: Exploring the AI models powering GitHub Copilot

Learn how GitHub Copilot’s evolving models and infrastructure center developer choice and power agentic workflows.

[AI & ML](https://github.blog/ai-and-ml/)

### How we accelerated Secret Protection engineering with Copilot

Learn how the Secret Protection engineering team collaborated with GitHub Copilot coding agent to expand validity check coverage.

[AI & ML](https://github.blog/ai-and-ml/)

### How to use GitHub Copilot on github.com: A power user’s guide

Explore how to use GitHub Copilot on github.com to automate tasks, assign agents, prototype ideas, and streamline your entire workflow — all without an IDE.