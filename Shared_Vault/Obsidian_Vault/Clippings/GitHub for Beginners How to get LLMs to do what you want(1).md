---
title: "GitHub for Beginners: How to get LLMs to do what you want"
source: https://github.blog/ai-and-ml/github-copilot/github-for-beginners-how-to-get-llms-to-do-what-you-want/?&utm_campaign=LCM_CopilotProOnboarding_dev&utm_source=github&utm=medium=email
author:
  - "[[Kedasha Kerr]]"
published: 2025-03-31
created: 2025-09-04
description: Learn how to write effective prompts and troubleshoot results in this installment of our GitHub for Beginners series.
tags:
  - clippings
  - CoPilot
  - GitHub
---
Welcome back to season two of GitHub for Beginners, a series designed to help you navigate GitHub more confidently! So far, we’ve explored how to use GitHub Copilot and some of its essential features. Today, we will be learning all about large language models (LLMs) and the basics of prompt engineering.

![](https://www.youtube.com/watch?v=LAF-lACf2QY)

LLMs are powerful, and the way we interact with them via prompts matters. For example, have you ever tried asking an LLM a question, but it can’t really figure out what you’re trying to ask? Understanding the power of prompts (and the limitations that come with them) can help you become even more productive.

In this post, we’ll explore:

- How LLMs work and how prompts are processed.
- How to engineer the most effective prompts.
- How to troubleshoot prompts when we don’t get the outcomes we want.

Let’s get started!

## What’s an LLM?

Large language models are a type of AI that are trained on a large (hence the name) amount of text data to understand and generate human-like language.

By [predicting the next word](https://github.blog/ai-and-ml/generative-ai/how-ai-code-generation-works/) in a sentence based on the context of the words that came before it, LLMs respond to humans in a way that is relevant and coherent. Sort of like an ultra-smart autocomplete!

![This image shows the process of using an LLM: entering prompt text, LLM analysis, and then receiving a response.](https://github.blog/wp-content/uploads/2025/03/01-llm-process.png?resize=1024%2C565)

When it comes to using LLMs, there are three important things to understand:

- **Context:** This is the surrounding information that helps an LLM understand what you’re talking about. Just like when you have a conversation with a friend, the more context you offer, the more likely the conversation will make sense.

![This image shows a visual example of what it’s like to gain context within a text message thread between two friends, and then a flow chart showing how the conversation went from no context at all to achieving full context.](https://github.blog/wp-content/uploads/2025/03/08-context.png?resize=1024%2C598)

- **Tokens:** For LLMs, text is broken down into units of tokens. This could be a word, part of a word, or even just one single letter. AI models process tokens to generate responses, so the number of tokens you use with an LLM can impact its response. Too few tokens can lead to a lack of context, but too many could overwhelm the AI model or run into its built-in token limits.

![This image is a visual representation of how a rare word like “Supercalifragilisticexpialidocious” would be broken down into six smaller, more common tokens, or subword pieces.](https://github.blog/wp-content/uploads/2025/03/02-tokens.png?resize=1024%2C568)

- **Limitations:** LLMs are powerful, but not all-powerful. Instead of understanding language like humans, LLMs rely on patterns and probabilities from training data. Taking a deeper dive into training data is beyond the scope of this post, but as a general rule, the ideal data set is diverse and broad. Models are never perfect—sometimes they can [hallucinate](https://github.blog/ai-and-ml/llms/demystifying-llms-how-they-can-do-things-they-werent-trained-to-do/#hallucinations), provide incorrect answers, or give nonsensical responses.

![This image depicts how common sense reasoning plays into prompting LLMs. It explores a prompt, shares how humans and LLMs would each understand the prompt, and shares a potential hallucination.](https://github.blog/wp-content/uploads/2025/03/09-limitations.png?resize=1024%2C568)

## What is a prompt?

A prompt is a natural language request that asks an LLM to perform a specific task or action. A prompt gives the model context via tokens, and works around the model’s potential limitations, so that the model can give you a response. For example, if you prompt an LLM with “Write a JavaScript function to calculate the factorial of a number,” it will use its training data to give you a function that accomplishes that task.

![This image shares four steps in which an LLM might process your prompt. The four steps are: input prompt, tokenization, processing, and response generation.](https://github.blog/wp-content/uploads/2025/03/03-prompt-process.png?resize=1024%2C575)

Depending on how a specific model was trained, it might process your prompt differently, and present different code. Even the same model can produce different outputs. These models are nondeterministic, which means you can prompt it the same way three times and get three different results. This is why you may receive different outputs from various models out in the world, like OpenAI’s GPT, Anthropic’s Claude, and Google’s Gemini.

Now that we know what a prompt is, how do we use prompts to get the outputs we want?

## What is prompt engineering?

Imagine that a friend is helping you complete a task. It’s important to give them clear and concise instructions if there’s a specific way the task needs to be done. The same is true for LLMs: a well-crafted prompt can help the model understand and deliver exactly what you’re looking for. The act of crafting these prompts is prompt engineering.

That’s why crafting the right prompt is so important: when this is done well, [prompt engineering](https://github.blog/ai-and-ml/generative-ai/prompt-engineering-guide-generative-ai-llms/) can drastically improve the quality and relevance of the outputs you get from an LLM.

Here are a few key components of effective prompting:

- An effective prompt is **clear and precise**, because ambiguity can confuse the model.
- It’s also important to provide *enough* **context**, but not too much detail, since this can overwhelm the LLM.
- If you don’t get the answer you’re expecting, don’t forget to **iterate and refine** your prompts!

Let’s try it out!

**Example: How to refine prompts to be more effective**  
Imagine you’re using GitHub Copilot and say: `Write a function that will square numbers in a list` in a new file with no prior code to offer Copilot context. At first, this seems like a straightforward and effective prompt. But there are a lot of factors that aren’t clear:

- What language should the function be written in?
- Do you want to include negative numbers?
- Will the input ever have non-numbers?
- Should it affect the given list or return a new list?

How could we refine this prompt to be more effective? Let’s change it to: `Write a Python function that takes a list of integers and returns a new list where each number is squared, excluding any negative numbers.`

This new prompt is clear and specific about what language we want to use, what the function should do, what constraints there are, and the expected input type. When we give GitHub Copilot more context, the output will be better aligned with what we want from it!

![This image consists of white text on a black background sharing that prompt engineering is the same thing as being a good communicator.](https://github.blog/wp-content/uploads/2025/03/04-good-communicator.png?resize=1024%2C612)

Just like coding, prompt engineering is about effective communication. By crafting your prompts thoughtfully, you can more effectively use tools like GitHub Copilot to make your workflows smoother and more efficient. That being said, working with LLMs means there will still be some instances that call for a bit of troubleshooting.

## How to improve results when prompting LLMs

As you continue working with GitHub Copilot and other LLM tools, you may occasionally not get the output you want. Oftentimes, it’s because your initial prompt wasn’t specific enough. Here are a few scenarios you might run into when prompting LLMs.

### Prompt confusion

It’s easy to mix multiple requests or be unclear when writing prompts, which can confuse the model you’re using. Say you highlight something in Visual Studio Code and tell Copilot `fix the errors in this code and optimize it.` Is the AI supposed to fix the errors or optimize it first? For that matter, what is it supposed to optimize for? Speed, memory, or readability?

![This image depicts how to overcome prompt confusion, or mixing multiple requests or unclear instructions. First, you’d fix errors, then optimize code, and finally add tests.](https://github.blog/wp-content/uploads/2025/03/05-prompt-confusion.png?resize=1024%2C612)

To solve this, you need to break your prompt down into concrete steps with context. We can adjust this prompt by separating our asks: `First, fix the errors in the code snippet. Then, optimize the fixed code for better performance.` Building a prompt iteratively makes it more likely that you’ll get the result you want because the specific steps the model needs to take are more clear.

### Token limitations

Remember, tokens are units of words or partial words that a model can handle. But there’s a limit to how many tokens a given model can handle at once (this varies by model, too—and [there are different models available with GitHub Copilot](https://docs.github.com/en/copilot/using-github-copilot/ai-models)). If your prompt is too long or the expected output is very extensive, the LLM may hallucinate, give a partial response, or just fail entirely.

![This image depicts how to overcome token limitations, since LLMs have a maximum token limit for input and output. You would need to break down large inputs into smaller chunks.](https://github.blog/wp-content/uploads/2025/03/06-token-limitations.png?resize=1024%2C612)

That means you want to keep your prompts concise. Again, it’s important to iterate on smaller sections of your prompt, but it’s also crucial to only provide necessary context. Does the LLM actually need an entire code file to return your desired output, or would just a few lines of code in a certain function do the trick? Instead of asking it to generate an entire application, can you ask it to make each component step-by-step?

It’s easy to assume that the LLM knows more than it actually does. If you say `add authentication to my app,` does the model know what your app does? Does it know which technologies you may want to use for authentication?

![This image depicts how to overcome assumption errors, or when you assume LLM has context it doesn’t have. You’d need to explicitly state requirements, outline specific needs, mention best practices if needed, and then iterate with edge cases and restraints.](https://github.blog/wp-content/uploads/2025/03/07-assumption-errors.png?resize=1024%2C612)

When crafting a prompt like this, you’ll need to explicitly state your requirements. This can be done by outlining specific needs, mentioning best practices if you have any, and once again, iterating with edge cases and restraints. By stating your requirements, you’ll help ensure the LLM doesn’t overlook critical aspects of your request when it generates the output.

## Prompt engineering best practices

Prompt engineering can be tricky to get the hang of, but you’ll get better the more you do it. Here are some best practices to remember when working with GitHub Copilot or any other LLM:

- Give the model enough context while considering any limitations it might have.
- Prompts should be clear, concise, and precise for the best results.
- If you need multiple tasks completed, break down your prompts into smaller chunks and iterate from there.
- Be specific about your requirements and needs, so that the model accurately understands the constraints surrounding your prompt.

We covered quite a bit when it comes to prompt engineering. We went over what LLMs are and why context is important, defined prompt engineering and crafting effective prompts, and learned how to avoid common pitfalls when working with large language models.

- If you want to watch this demo in action, we’ve created a **[YouTube tutorial](https://youtu.be/LAF-lACf2QY)** that accompanies this blog.
- If you have any questions, pop them in the [**GitHub Community thread**](https://github.com/orgs/community/discussions/152688) and we’ll be sure to respond.
- Remember to [sign up for GitHub Copilot](https://gh.io/gfb-copilot) (if you haven’t already) to get started for free.
- Join us for the next part of the series where we’ll walk through security best practices.

Happy coding!

## Tags:

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