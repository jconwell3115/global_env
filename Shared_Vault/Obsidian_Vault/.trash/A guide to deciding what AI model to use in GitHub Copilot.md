---
title: A guide to deciding what AI model to use in GitHub Copilot
source: https://github.blog/ai-and-ml/github-copilot/a-guide-to-deciding-what-ai-model-to-use-in-github-copilot/?utm_campaign=LCM_CopilotProOnboarding_dev&utm_source=github&utm=medium=email
author:
  - "[[Klint Finley]]"
published: 2025-04-24
created: 2025-09-04
description: Explore a framework—including a few strategies—for evaluating whether any given AI model is a good fit for your use.
tags:
  - clippings
  - GitHub
  - CoPilot
---
To ensure that you have access to the best technology available, we’re continuously adding support for new models to [GitHub Copilot](https://github.com/features/copilot). That being said, we know it can be hard to keep up with so many new models being released all the time.

All of this raises an obvious question: Which model should you use?

You can [read our recent blog post](https://github.blog/ai-and-ml/github-copilot/which-ai-model-should-i-use-with-github-copilot/) for an overview of the models currently available in Copilot and their strengths, or [check out our documentation](https://docs.github.com/en/copilot/using-github-copilot/ai-models/choosing-the-right-ai-model-for-your-task) for a deep dive comparing different models and tasks. But the AI landscape moves quickly. **In this article we’ll explore a framework—including a few strategies—for evaluating whether any given AI model is a good fit for *your* use, even as new models continue to appear at a rapid pace.**

It’s hard to go wrong with our base model, which has been fine-tuned specifically for programming-related tasks. But depending on what you’re working on, you likely have varying needs and preferences. There’s no single “best” model. Some may favor a more verbose model for chat, while others prefer a terse one, for example.

We spoke with several developers about their model selection process. Keep reading to discover how to apply their strategies to your own needs.

*💡 Watch the video below for tips on prompt engineering to get the best results.*

![](https://www.youtube.com/watch?v=LAF-lACf2QY)

## Why use multiple models?

There’s no reason you have to pick one model and stick with it. Since you can easily switch between models for both [chat](https://docs.github.com/en/copilot/using-github-copilot/ai-models/changing-the-ai-model-for-copilot-chat) and [code completion](https://docs.github.com/en/copilot/using-github-copilot/ai-models/changing-the-ai-model-for-copilot-code-completion) with GitHub Copilot, you can use different models for different use cases.

> It's kind of like dogfooding your own stack: You won’t know if it really fits your workflow until you've shipped some real code with it.

\- Anand Chowdhary, FirstQuadrant CTO and co-founder

### Chat vs. code completion

Using one model for chat and another for autocomplete is one of the most common patterns we see among developers. Generally, developers prefer autocompletion models because they’re fast and responsive, which they need if they’re looking for suggestions as they think and type. Developers are more tolerant of latency in chat, when they’re in more of an exploratory state of mind (like considering a complex refactoring job, for instance).

### Reasoning models for certain programming tasks

Reasoning models like OpenAI o1 often respond slower than traditional LLMs such as GPT-4o or Claude Sonnet 3.5. That’s in large part because these models break a prompt down into parts and consider multiple approaches to a problem. That introduces latency in their response times, but makes them more effective at completing complex tasks. Many developers prefer these more deliberative models for particular tasks.

For instance, Fatih Kadir Akın, a developer relations manager, uses o1 when starting new projects from scratch. “Reasoning models better ‘understand’ my vision and create more structured projects than non-reasoning models,” he explains.

FirstQuadrant CTO and co-founder Anand Chowdhary favors reasoning models for large-scale code refactoring jobs. “A model that rewrites complex backend code without careful reasoning is rarely accurate the first time,” he says. “Seeing the thought process also helps me understand the changes.”

When creating technical interview questions for her newsletter, GitHub Senior Director of Developer Advocacy, Cassidy Williams mixes models for certain tasks. When she writes a question, she uses GPT-4o to refine the prose, and then Claude 3.7 Sonnet Thinking to verify code accuracy. “Reasoning models help ensure technical correctness because of their multi-step process,” she says. “If they initially get something wrong, they often correct themselves in later steps so the final answer is more accurate.”

> There’s some subjectivity, but I compare model output based on the code structure, patterns, comments, and adherence to best practices.

\- Portilla Edo, cloud infrastructure engineering lead

## What to look for in a new AI model

Let’s say a new model just dropped and you’re ready to try it out. Here are a few things to consider before making it your new go-to.

### Recentness

Different models use different training data. That means one model might have more recent data than another, and therefore might be trained on new versions of the programming languages, frameworks, and libraries you use.

“When I’m trying out a new model, one of the first things I do is check how up to date it is,” says Xavier Portilla Edo, a cloud infrastructure engineering lead. He typically does this by creating a project manifest file for the project to see what version numbers Copilot autocomplete suggests. “If the versions are quite old, I’ll move on,” he says.

### Speed and responsiveness

As mentioned, developers tend to tolerate more latency in a chat than in autocomplete. But responsiveness is still important in chat. “I enjoy bouncing ideas off a model and getting feedback,” says Rishab Kumar, a staff developer evangelist at Twilio. “For that type of interaction, I need fast responses so I can stay in the flow.”

### Accuracy

Naturally, you need to evaluate which models produce the best code. “There’s some subjectivity, but I compare model output based on the code structure, patterns, comments, and adherence to best practices,” Portilla Edo says. “I also look at how readable and maintainable the code is—does it follow naming conventions? Is it modular? Are the comments helpful or just restating what the code does? These are all signals of quality that go beyond whether the code simply runs.”

## How to test an AI model in your workflow

OK, so now you know what to look for in a model. But how do you actually evaluate it for responsiveness and correctness? You use it, of course.

### Start with a simple app

Akın will generally start with a simple todo app written in vanilla JavaScript. “I just check the code, and how well it’s structured,” he says. Similarly, Kumar will start with a websocket server in Python. The idea is to start with something that you understand well enough to evaluate, and then layer on more complexity. “Eventually I’ll see if it can build something in 3D using 3js,” Akın says.

Portilla Edo starts by prompting a new model he wants to evaluate in Copilot Chat. “I usually ask it for simple things, like a function in Go, or a simple HTML file,” he says. Then he moves on to autocompletion to see how the model performs there.

### Use it as a “daily driver” for a while

Chowdhary prefers to just jump in and start using a model. “When a new model drops, I swap it into my workflow as my daily driver and just live with it for a bit,” he says. “Available benchmarks and tests only tell you part of the story. I think the real test is seeing if it actually improves your day to day.”

For example, he checks to see if it actually speeds up his debugging jobs or produces cleaner refactors. “It’s kind of like dogfooding your own stack: You won’t know if it really fits your workflow until you’ve shipped some real code with it,” he says. “After evaluating it for a bit, I decide whether to stick with the new model or revert to my previous choice.”

## Take this with you

What just about everyone agrees on is that the best way to evaluate a model is to use it.

The important thing is to keep learning. “You don’t need to be switching models all the time, but it’s important to know what’s going on,” Chowdhary says. “The state of the art is moving quickly. It’s easy to get left behind.”

### Additional resources

- [Choosing the right AI model for your task](http://docs.github.com/en/copilot/using-github-copilot/ai-models/choosing-the-right-ai-model-for-your-task)
- [Examples for AI model comparison](https://docs.github.com/en/copilot/using-github-copilot/ai-models/comparing-ai-models-using-different-tasks)
- [Which AI models should I use with GitHub Copilot?](https://github.blog/ai-and-ml/github-copilot/which-ai-model-should-i-use-with-github-copilot/)

## Written by

## Related posts

[AI & ML](https://github.blog/ai-and-ml/)

### Building smarter interactions with MCP elicitation: From clunky tool calls to seamless user experiences

Explore how MCP elicitation transforms AI tool interactions by gathering missing information upfront.

[AI & ML](https://github.blog/ai-and-ml/)

### 5 tips for writing better custom instructions for Copilot

This guide offers five essential tips for writing effective GitHub Copilot custom instructions, covering project overview, tech stack, coding guidelines, structure, and resources, to help developers get better code suggestions.

[AI & ML](https://github.blog/ai-and-ml/)

### Spec-driven development with AI: Get started with a new open source toolkit

Developers can use their AI tool of choice for spec-driven development with this open source toolkit.