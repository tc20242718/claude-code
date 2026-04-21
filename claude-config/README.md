# Claude Code Config Snapshot

This directory contains a snapshot of the Claude Code global configuration installed during the skills setup session.

## Contents

| File/Dir | Description |
|----------|-------------|
| `settings.json` | Global Claude Code settings — MCP servers, hooks, permissions |
| `CLAUDE.md` | Global memory file — persistent context loaded every session |
| `dreaming.sh` | Nightly memory consolidation script |
| `stop-hook-git-check.sh` | Stop hook — validates git state before session ends |
| `skills/*/SKILL.md` | 22 installed skill definitions |

## MCP Servers Configured

| Server | Purpose | Requires |
|--------|---------|---------|
| context7 | Injects current library docs into context | — |
| playwright | Browser automation and control | — |
| taskmaster | Breaks PRDs into structured tasks | — |
| container-use | Isolated containerized agent environments | Dagger binary |
| firecrawl | Converts websites to LLM-ready data | `FIRECRAWL_API_KEY` |
| brave-search | Clean web search for AI agents | `BRAVE_API_KEY` |
| memory (mem0) | Codebase memory MCP | `MEM0_API_KEY` |
| exa | Semantic search engine for agents | `EXA_API_KEY` |

## Restore on a Fresh Machine

```bash
# 1. Copy skills
cp -r claude-config/skills/* ~/.claude/skills/

# 2. Copy config files
cp claude-config/settings.json ~/.claude/settings.json
cp claude-config/CLAUDE.md ~/.claude/CLAUDE.md
cp claude-config/dreaming.sh ~/.claude/dreaming.sh
cp claude-config/stop-hook-git-check.sh ~/.claude/stop-hook-git-check.sh

# 3. Make scripts executable
chmod +x ~/.claude/dreaming.sh ~/.claude/stop-hook-git-check.sh

# 4. (Optional) Schedule nightly dreaming at 3 AM
crontab -e
# Add: 0 3 * * * ~/.claude/dreaming.sh >> ~/.claude/dreaming.log 2>&1

# 5. Set API keys for MCP servers that need them
export FIRECRAWL_API_KEY=...
export BRAVE_API_KEY=...
export MEM0_API_KEY=...
export EXA_API_KEY=...
```

## Skills Installed

| Skill | When to use |
|-------|------------|
| `auto-researcher` | Iterative AI experiment/improve loop |
| `brand-guidelines` | Enforce consistent brand voice across outputs |
| `canva` | Design briefs and Canva API integration |
| `collaborative-writing` | Interactive document editing with Claude |
| `deep-research` | Multi-source research with citations |
| `document-utility` | Table extraction, format conversion, merging |
| `frontend-design` | UI components, a11y, responsive layouts |
| `gpt-researcher` | Autonomous web research reports |
| `marketing` | Copywriting, SEO, email campaigns |
| `memory` | Save/recall/consolidate long-term memories |
| `memory-import` | Import ChatGPT or external memories |
| `n8n` | Workflow automation design |
| `reduce-tokens` | Compress responses to minimize token usage |
| `remotion` | Programmatic video with React |
| `security-testing` | AI prompt injection red-teaming |
| `session-start-hook` | Set up SessionStart hooks |
| `skill-creator` | Generate new skills from workflow descriptions |
| `slide-deck` | Generate presentations from descriptions |
| `spreadsheet` | Design spreadsheets from plain English |
| `superpowers` | TDD, systematic debugging, engineering discipline |
| `web-artifacts` | Self-contained HTML/CSS/JS widgets |
| `website-audit` | Full site audit (perf, SEO, a11y, security) |
