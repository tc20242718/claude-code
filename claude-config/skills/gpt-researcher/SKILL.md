---
name: gpt-researcher
description: Use when the user wants to autonomously compile a comprehensive research report on a topic using GPT Researcher — an agent that searches the web, reads sources, and synthesizes findings into a long-form report with citations.
---

# GPT Researcher Skill

## What is GPT Researcher

GPT Researcher is an autonomous research agent that:
1. Generates a research plan for the given topic
2. Runs multiple web searches in parallel
3. Reads and extracts content from sources
4. Synthesizes everything into a structured report with citations

## Installation

```bash
pip install gpt-researcher
```

## Required API Keys

```bash
export OPENAI_API_KEY=your_key      # LLM backbone
export TAVILY_API_KEY=your_key      # Web search (free tier: 1000/month at tavily.com)
```

## Running a Research Task

```python
import asyncio
from gpt_researcher import GPTResearcher

async def research(query: str, report_type="research_report"):
    researcher = GPTResearcher(
        query=query,
        report_type=report_type,
        report_source="web",
    )
    await researcher.conduct_research()
    return await researcher.write_report()

report = asyncio.run(research("Impact of LLMs on software engineering 2025"))

# Save to file
with open("report.md", "w") as f:
    f.write(report)
```

## Report Types

| Type | Description |
|------|-------------|
| `research_report` | Full report with sections and citations (~2000 words) |
| `detailed_report` | Extended deep-dive (~5000 words) |
| `outline_report` | Structured outline only |
| `resource_report` | Annotated bibliography |
| `subtopic_report` | Focused report on one aspect |

## Configuration

```python
researcher = GPTResearcher(
    query="your topic",
    report_type="research_report",
    tone="objective",       # objective, analytical, persuasive
    verbose=True,           # show progress
    max_subtopics=5,
)
```

## Workflow with Claude

- If `TAVILY_API_KEY` + `OPENAI_API_KEY` available → use GPT Researcher for autonomous web research
- If only Claude available → use the `deep-research` skill instead
- After GPT Researcher produces a report → use Claude to refine, summarize, or extract action items

## Troubleshooting Install

If `pip install gpt-researcher` fails due to build errors (sgmllib3k, docopt):
```bash
# Install build tools first
apt-get install -y python3-dev build-essential
pip install gpt-researcher
```
