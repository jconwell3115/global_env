---
title: The End-to-End Data Scientist’s Prompt Playbook
source: https://towardsdatascience.com/the-end-to-end-data-scientists-prompt-playbook/
author:
  - "[[Sara Nobrega]]"
published: 2025-09-08
created: 2025-09-10
description: "Part 3: Prompts for docs, DevOps, and stakeholder communication"
tags:
  - clippings
  - Data_Science
  - Education
  - Automation
  - AI
---
[Skip to content](https://towardsdatascience.com/the-end-to-end-data-scientists-prompt-playbook/#wp--skip-link--target)

Part 3: Prompts for docs, DevOps, and stakeholder communication

10 min read

![](https://towardsdatascience.com/wp-content/uploads/2025/09/39341ae4-cfa8-48aa-b4c0-730e7e2ea8a8.jpg)

Image generated with DALL-E.

Ever feel proud of your **code**, your **modeling**, and the **accuracy** you’ve achieved, knowing it could really make a **difference** for your team but then you **struggle** to **share** those findings with your team and stakeholders?

That’s a very common feeling among data scientists and ML engineers.

In this article, I’m sharing my go-to prompts, workflows, and tiny tricks that turn dense, sometimes abstract, model **outputs** into sharp and clear **business narratives** people actually care about.

If you work with **stakeholders** or **managers** who don’t live in notebooks all day, this is for you. And just like my other guides, I’ll keep it practical and copy-pasteable.

This article is the third and last part of **3-article series** regarding prompt engineering for data scientists.

The **End-to-End** Data Science Prompt Engineering Series is:

- **Part 1:** [Prompt Engineering for Planning, Cleaning, and EDA](https://towardsdatascience.com/become-a-better-data-scientist-with-these-prompt-engineering-hacks/)
- [**Part 2:** Prompt Engineering for Features, Modeling, and Evaluation](https://towardsdatascience.com/advanced-prompt-engineering-for-data-science-projects/)
- **Part 3: Prompts for Docs, DevOps, and Stakeholder Communication** (this article)

👉 All the **prompts** in this article are available at the **end** of this article as a cheat sheet 😉

In this article:

1. Why LLMs Are a Game-Changer for Data Storytelling
2. The Communication Lifecycle, Reimagined with LLMs
3. Prompts for Docs, DevOps, and Stakeholder Communication
4. Prompt Engineering cheat sheet

---

## 1) Why LLMs Are a Game-Changer for Data Storytelling

LLMs mix fluent **writing** with **contextual** reasoning. In practice, that means they can:

1. rephrase tricky **metric** s in plain English (or any other language),
2. draft executive-level **summaries** in seconds, and
3. adapt **tone** and **format** for any audience—board, product, legal, you name it.

Early research is showing that GPT-style models can actually boost **understanding** for **non-technical** readers by double digits. That’s a pretty big jump compared to just staring at raw charts or graphs.

And because LLMs “ **speak stakeholder**,” they help you defend decisions without drowning folks in jargon.

If prompt engineering felt like hype before, here it becomes a real edge: **clear stories**, fewer meetings, faster buy-in.

## 2) The Communication Lifecycle, Reimagined with LLMs

After training an evaluating a model, you will probably:

- Interpret model results (SHAP, coefficients, confusion matrices).
- Summarize EDA and call out caveats.
- Draft executive briefs, slide scripts, and “what to do next.”
- Standardize tone across memos and decks.
- Close the loop with versioned prompts and quick updates.

Now: imagine a **helper** that writes the first draft, explains **trade-offs**, calls out missing context, and keeps voice **consistent** across authors.

That’s what LLMs can be, if you prompt them well!

## 3) Prompts & Patterns for Interpretation, Reporting, and Stakeholder Engagement

#### 3.1 SHAP & Feature-Importance Narratives

**Best practice:** Feed the model a structured table and ask for an executive-ready summary plus actions.

```markdown
## System  
You are a senior data storyteller experienced in risk analytics and executive communication.  

## User  
Here are SHAP values in the format (feature, impact): {shap_table}.  

## Task  
1. Rank the top-5 drivers of risk by absolute impact.  
2. Write a ~120-word narrative explaining:  
   - What increases risk  
   - What reduces risk  
3. End with two concrete mitigation actions.  

## Constraints & Style  
- Audience: Board-level, non-technical.  
- Format: Return output as Markdown bullets.  
- Clarity: Expand acronyms if present; flag and explain unclear feature names.  
- Tone: Crisp, confident, and insight-driven.  

## Examples  
- If a feature is named \`loan_amt\`, narrate it as "Loan Amount (the size of the loan)".  
- For mitigation, suggest actions such as "tighten lending criteria" or "increase monitoring of high-risk segments".  

## Evaluation Hook  
At the end, include a short self-check: "Confidence: X/10. Any unclear features flagged: [list]."
```

  
**Why it works:** The structure forces ranking → narrative → action. Stakeholders get the “so what?” not just bars on a chart.

#### 3.2 Confusion-Matrix Clarifications

Imagine your project is all about **fraud detection** for a financial platform.

You’ve trained a good model, your precision and recall scores look great, and you feel proud of how it’s performing. But now comes the part where you need to explain those results to your **team**, or worse, to a room full of **stakeholders** who don’t really understand about model metrics.

Here’s a handy table that explains the confusion-matrix terms into simple English explanations:

| Metric | Plain-English Translation | Prompt Snippet |
| --- | --- | --- |
| False Positive | “Alerted but not actually fraud” | *Explain FP as wasted review cost.* |
| False Negative | “Missed the real fraud” | *Frame FN as revenue loss/risk exposure.* |
| Precision | “How many alerts were right” | *Relate to QA false alarms.* |
| Recall | “How many real cases we caught” | *Use a ‘fishing-net holes’ analogy.* |

  
**Prompt to Explain Model Results Simply**

```markdown
## System  
You are a data storyteller skilled at explaining model performance in business terms.  

## User  
Here is a confusion matrix: [[TN:1,500, FP:40], [FN:25, TP:435]].  

## Task  
- Explain this matrix in ≤80 words.  
- Stress the business cost of false positives (FP) vs false negatives (FN).  

## Constraints & Style  
- Audience: Call-center VP (non-technical, focused on cost & operations).  
- Tone: Clear, concise, cost-oriented.  
- Output: A short narrative paragraph.  

## Examples  
- "False positives waste agent time by reviewing customers who are actually fine."  
- "False negatives risk missing real churners, costing potential revenue."  

## Evaluation Hook  
End with a confidence score out of 10 on how well the explanation balances clarity and business relevance.
```

#### 3.3 ROC & AUC—Make the Trade-off Concrete

ROC curves and AUC scores are one of the favorite metrics of DSs, great for evaluating model performance, but they are generally too abstract for business conversations.

To make things real, tie model **sensitivity** and **specificity** to actual business limits: like time, money, or human workload.

**Prompt:**

```markdown
“Highlight the trade-off between 95% sensitivity and marketing cost; suggest a cut-off if we must review ≤60 leads/day.”
```

This kind of framing turns abstract metrics into concrete, operational decisions.

#### 3.4 Regression Metrics Cheat-Sheet

When you’re working with regression models, the metrics can feel like a set of random letters (MAE, RMSE, R²). Great for model tuning, but not so great for storytelling.

That’s why it helps to reframe these numbers using simple business analogies:

| Metric | Business Analogy | One-liner Template |
| --- | --- | --- |
| MAE | “Average dollars off per quote” | *“Our MAE of $2 means the typical quote error is $2.”* |
| RMSE | “Penalty grows for big misses” | *“RMSE 3.4 → rare but costly misses matter.”* |
| R² | “Share of variance we explain” | *“We capture 84% of price drivers.”* |

---

💥Don´t forget to check [**Part 2** of this series](https://towardsdatascience.com/advanced-prompt-engineering-for-data-science-projects/), where you will learn how to improve your **modeling** and **feature engineering**.

---

#### 4) Summarizing EDA—With Caveats Up Front

EDA is where the real detective work begins. But let’s face it: those auto-generated profiling reports (like `pandas-profiling` or summary JSONs) can be overwhelming.

The next prompt is useful to change EDA outputs into short and human-friendly summaries.

**Guided EDA narrator (pandas-profile or summary JSON in, brief out):**

```markdown
## System  
You are a data-analysis narrator with expertise in exploratory data profiling.  

## User  
Input file: pandas_profile.json.  

## Task  
1. Summarize key variable distributions in ≤150 words.  
2. Flag variables with >25% missing data.  
3. Recommend three transformations to improve quality or model readiness.  

## Constraints & Style  
- Audience: Product manager (non-technical but data-aware).  
- Tone: Accessible, insight-driven, solution-oriented.  
- Format:  
  - Short narrative summary  
  - Bullet list of flagged variables  
  - Bullet list of recommended transformations  

## Examples  
- Transformation examples: "Standardize categorical labels", "Log-transform skewed revenue variable", "Impute missing age with median".  

## Evaluation Hook  
End with a self-check: "Confidence: X/10. Any flagged variables requiring domain input: [list]."
```

### 5) Executive Summaries, Visual Outlines & Slide Narratives

After the data modeling and generation of insights, there’s one final challenge: telling your data **story** in a way decision-makers actually **care about**.

  
**Framework snapshots**

- **Executive Summary Guide prompt:** Intro, Key Points, Recommendations (≤500 words).
- **Storytell-style summary:** Main points, key stats, trend lines (≈200 words).
- **Weekly “Power Prompt”:** Two short paragraphs + “Next Steps” bullets.

**Composite prompt**

```markdown
## System  
You are the Chief Analytics Communicator, expert at creating board-ready summaries.  

## User  
Input file: analysis_report.md.  

## Task  
Draft an executive summary (≤350 words) with the following structure:  
1. Purpose (~40 words)  
2. Key findings (Markdown bullets)  
3. Revenue or risk impact estimate (quantified if possible)  
4. Next actions with owners and dates  

## Constraints & Style  
- Audience: C-suite executives.  
- Tone: Assertive, confident, impact-driven.  
- Format: Structured sections with headings.  

## Examples  
- Key finding bullet: "Customer churn risk rose 8% in Q2, concentrated in enterprise accounts."  
- Action item bullet: "By Sept 15: VP of Sales to roll out targeted retention campaigns."  

## Evaluation Hook  
At the end, output: "Confidence: X/10. Risks or assumptions that need executive input: [list]."
```

#### 6) Tone, Clarity, and Formatting

You’ve got the insights and conclusions. It’s time to make them clear, confident, and easy to understand.

Experienced data scientists know what how you say something is sometimes even more important than what you’re saying!

| Tool/Prompt | What it’s for | Typical Use |
| --- | --- | --- |
| “Tone Rewriter” | Formal ↔ casual, or “board-ready” | Customer updates, exec memos |
| Hemingway-style edit | Shorten, punch up verbs | Slide copy, emails |
| “Tone & Clarity Review” | Assertive voice, fewer hedges | Board materials, PRR summaries |

**Universal rewrite prompt**

```markdown
Revise the paragraph for senior-executive tone; keep ≤120 words. 
Retain numbers and units; add one persuasive stat if missing.
```

#### 7) End-to-End LLM Communication Pipeline

1. **Model outputs →** SHAP/metrics → explanation prompts.
2. **EDA findings →** summarization prompts or LangChain chain.
3. **Self-check →** ask the model to flag unclear features or missing KPIs.
4. **Tone & format pass →** dedicated rewrite prompt.
5. **Version control →** store `.prompty` files alongside notebooks for reproducibility.

#### 8) Case Studies

| Org / Project | LLM Use | Outcome |
| --- | --- | --- |
| Fintech credit scoring | SHAP-to-narrative (“SHAPstories”) inside dashboards | +20% stakeholder understanding; 10× faster docs |
| Healthcare startup | ROC interpreter in a Shiny app | Clinicians aligned on a 92% sensitivity cut-off in minutes |
| Retail analytics | Embedded table summaries | 3-hour write-ups reduced to ~12 minutes |
| Large wealth desk | Research Q&A assistant | 200k monthly queries; ≈90% satisfaction |
| Global CMI team | Sentiment roll-ups via LLM | Faster cross-market reporting for 30 regions |

#### 9) Best-Practice Checklist

- Define audience, length, and tone in the **first two lines** of every prompt.
- Feed **structured inputs** (JSON/tables) to reduce hallucinations.
- Embed **self-evaluation** (“rate clarity 0–1”; “flag missing KPI”).
- Keep **temperature ≤0.3** for deterministic summaries; raise it for creative storyboards.
- **Never paraphrase numbers** without units; keep the original metrics visible.
- Version-control prompts + outputs; tie them to **model versions** for audit trails.

---

#### 10) Common Pitfalls & Guardrails

| Pitfall | Symptom | Mitigation |
| --- | --- | --- |
| Invented drivers | Narrative claims features not in SHAP | Pass a strict **feature whitelist** |
| Overly technical | Stakeholders tune out | Add “grade-8 reading level” + business analogy |
| Tone mismatch | Slides/memos don’t sound alike | Run a batch tone-rewrite pass |
| Hidden caveats | Execs miss small-N or sampling bias | Force a **Limitations** bullet in every prompt |

This “pitfalls first” habit mirrors how I close my DS-lifecycle pieces, because misuse almost always happens early, at the time of prompting.

---

**Steal-this-workflow takeaway:** Treat every metric as a story waiting to be told, then use prompts to standardize how you tell it. Keep the actions close, the caveats closer, and your voice unmistakably yours.

Thank you for reading!

---

👉 **Get the full prompt cheat sheet** + weekly updates on practical AI tools when you subscribe to **[Sara’s AI Automation Digest](https://saranfn.substack.com/)** — *helping tech professionals automate real work with AI, every week.* You’ll also get access to an AI tool library.

I offer **mentorship**  on career growth and transition  [here](https://topmate.io/sara_nobrega).

**If you want to support my work**, you can  [buy me my **favorite coffee**](https://buymeacoffee.com/saranobregu): a cappuccino. 😊

---

### References

[Enhancing the Interpretability of SHAP Values Using Large Language Models](https://arxiv.org/pdf/2409.00079)

[How to Summarize a Data Table Easily: Prompt an Embedded LLM](https://www.quadratichq.com/blog/how-to-summarize-a-data-table-easily-prompt-an-embedded-llm)

[Tell Me a Story! Narrative-Driven XAI With Large Language Models](https://www.insead.edu/faculty-research/publications/journal-articles/tell-me-a-story-narrative-driven-xai-large-language)

[Using LLMs to Improve Data Communication – Dataquest](https://www.dataquest.io/blog/llms-to-improve-data-communication/)

---

Written By

Sara Nobrega

Towards Data Science is a community publication. Submit your insights to reach our global audience and earn through the TDS Author Payment Program.

[Write for TDS](https://towardsdatascience.com/questions-96667b06af5/)

## Related Articles

- ![Photo by Jas Min on Unsplash](https://towardsdatascience.com/wp-content/uploads/2023/11/0qG6Cj83CoqDo5jLb-scaled.jpg)
	Photo by Jas Min on Unsplash
	## The Creative, Occasionally Messy World of Textual Data
	Our weekly selection of must-read Editors’ Picks and original features
	3 min read
- ![Image by author](https://towardsdatascience.com/wp-content/uploads/2024/04/1uaVWQu6H49BlVl6OAsM83g.png)
	Image by author
	## Deep Dive into Sora’s Diffusion Transformer (DiT) by Hand ✍︎
	Explore the secret behind Sora’s state-of-the-art videos
	13 min read
- ![Credit: Arthur Osipyan, Unsplash](https://towardsdatascience.com/wp-content/uploads/2023/06/1cjwosgUXyO6xbCChC90JQA.jpeg)
	Credit: Arthur Osipyan, Unsplash
	## Beware of Unreliable Data in Model Evaluation: A LLM Prompt Selection case study with Flan-T5
	You may choose suboptimal prompts for your LLM (or make other suboptimal choices via model…
	12 min read
- ## Beating ChatGPT 4 in Chess with a Hybrid AI model
	Better but not the best, GPT4 cheated but lost the match!
	7 min read
- ![](https://towardsdatascience.com/wp-content/uploads/2023/06/087HNzG4rYaQmzRB3-scaled.jpg)
	## If Oral and Written Communication Made Humans Develop Intelligence… What’s Up with Language Models?
	Essay A discussion at the frontier between science and fiction. Human intelligence, with its extraordinary…
	15 min read
- ![](https://towardsdatascience.com/wp-content/uploads/2023/11/17MonaLlO4zTNeFQT0ATKbw.png)
	## Using LLMs to evaluate LLMs
	You can ask ChatGPT to act in a million different ways: as your nutritionist, language…
	8 min read
- ![](https://towardsdatascience.com/wp-content/uploads/2023/11/1R-fWNo-SVYYmm_tepIoVuw.jpeg)
	## A beginner’s guide to building a Retrieval Augmented Generation (RAG) application from scratch
	\# Retrieval Augmented Generation, or RAG, is all the rage these days because it introduces…
	12 min read

Some areas of this page may shift around if you resize the browser window. Be sure to check heading and document order.