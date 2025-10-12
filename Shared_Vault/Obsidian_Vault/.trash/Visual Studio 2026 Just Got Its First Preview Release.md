---
title: "Visual Studio 2026 Just Got Its First Preview Release"
source: "https://www.howtogeek.com/visual-studio-2026-just-got-its-first-preview-release/"
author:
  - "[[Corbin Davenport]]"
published: 2025-09-10
created: 2025-09-12
description: "Microsoft's full-featured IDE has a new coat of paint, plus some AI stuff."
tags:
  - "clippings"
---
The first preview release of Visual Studio 2026 has arrived. As you might expect from a new Microsoft product, the big selling point is more AI integration, but there are some great performance improvements and visual tweaks as well for developers to enjoy.

[Visual Studio](https://visualstudio.microsoft.com/) is Microsoft’s full-featured integrated development environment (IDE), primarily for use with.NET and C++ programming languages, but also supporting other languages. That’s not to be confused for [Visual Studio Code](https://code.visualstudio.com/), which is a lighter text editor and modular IDE for more platforms.

Microsoft has now introduced an Insiders Channel for the next major update, Visual Studio 2026. It replaces the Preview Channel that was previously used for public testing.

## Performance & Design

According to Microsoft, Visual Studio 2026 has faster performance than previous releases, especially in large codebases. The blog post explained, “In 2026, the loops you run most – opening solutions, navigating code, building, and pressing F5 – tighten up. You’ll notice that first launch feels snappier, big solutions feel lighter, and the time between an idea and a running app keeps shrinking.” The speedup should be noticeable across both x86 and ARM-based computers—initial support for ARM Windows PCs [arrived in 2022](https://devblogs.microsoft.com/visualstudio/arm64-visual-studio-is-officially-here/) with the release of Visual Studio 2022 17.4.

![Various themes in Visual Studio 2026.](https://static0.howtogeekimages.com/wordpress/wp-content/uploads/2025/09/old_fluent-ui.png?q=70&fit=crop&w=500&dpr=1)

There’s also a refreshed look and feel that takes some inspiration from the Fluent design language, which is already used across Outlook, Office, and many Windows 11 applications. It has “crisper lines, improved iconography, and better spacing of visual elements,” as well as new color themes for customization. This is mostly just aesthetic tweaks, though—you won’t have to relearn where the important menus and buttons are located.

Microsoft said in the blog post, “Managing extensions is straightforward, and a plethora of new color themes help your environment feel personal – comfortable for long sessions, focused when the pressure is on, and accessible by default. It’s a design that respects your attention and helps you stay oriented, even in the largest solutions.”

## AI Features

Of course, it wouldn’t be a Microsoft software update in 2025 if there wasn’t AI somewhere. Visual Studio 2026 has AI “woven into the daily rhythms of coding,” though the functionality is similar to what [already exists in Visual Studio 2022](https://visualstudio.microsoft.com/github-copilot/) and Visual Studio Code.

There’s a Copilot Chat in the sidebar where you can ask questions, code suggestions as you type in the editor, automation with AI agents, and other fun stuff. You can more language models from Anthropic, Google, or OpenAI, so you aren’t strictly limited to Copilot. However, only the chat features can use a custom model—code completion will still use Copilot. There’s also no option to use a local language model running on your own PC.

Most of the AI features listed in this update are already available in Visual Studio 2022, either through updates to GitHub Copilot or other rollouts. Adaptive paste, custom models, and MCP support were added in [Visual Studio 17.14](https://learn.microsoft.com/en-us/visualstudio/releases/2022/release-notes?tabs=allfeatures), which started rolling out on September 9, 2025.

## Get Visual Studio 2026

You can [download the Visual Studio 2026 Insiders build](https://visualstudio.microsoft.com/insiders/) from Microsoft’s website, in the usual Community, Professional, and Enterprise versions. The official system requirements call for a 64-bit x86 or ARM PC, at least 4GB RAM (16GB is recommended), and 2.5GB of drive space. It works on Windows 10 and 11, as well as Windows Server 2019, 2022, and 2025.

Source: [Microsoft Dev Blogs](https://devblogs.microsoft.com/visualstudio/visual-studio-2026-insiders-is-here/)