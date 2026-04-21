---
name: memory
description: Use when the user wants to save something to long-term memory, recall what Claude remembers about them or their projects, consolidate the current session into memory, or manage persistent context across sessions.
---

# Memory Skill

Claude Code persists memories in two places:
- **Global** (`~/.claude/CLAUDE.md`): facts, preferences, and context that apply across all projects
- **Project** (`<project>/.claude/memory/*.md`): project-specific knowledge

## Commands

### `/memory save <fact>`
Save a specific fact to global memory. Append it under the appropriate section in `~/.claude/CLAUDE.md`.

Categories: People, Projects, Preferences, Decisions, Context

Example: `/memory save I prefer TypeScript over JavaScript for new projects`

### `/memory recall`
Read and summarize the contents of `~/.claude/CLAUDE.md` plus the current project's memory files. Present organized by category.

### `/memory consolidate`
Review the current session conversation and extract:
1. New facts about the user or their preferences
2. Decisions made
3. Project context established
4. Things the user asked to remember

Then append them (no duplicates) to `~/.claude/CLAUDE.md` and/or the project memory directory. Announce what was saved.

### `/memory forget <topic>`
Remove entries about a specific topic from memory files. Show what will be deleted and confirm before writing.

### `/memory show`
Print the raw contents of `~/.claude/CLAUDE.md`.

## Memory File Format

`~/.claude/CLAUDE.md` uses this structure:

```markdown
# Claude Memory

## About the User
- [facts about the user, their role, background]

## Preferences
- [coding style, communication style, tool preferences]

## Projects
- [active projects and their key context]

## Decisions
- [important decisions made, with date]

## People & Relationships
- [team members, contacts, roles]

## Notes
- [miscellaneous important context]
```

## Rules

- Never duplicate an existing memory entry
- When consolidating, prefer specific facts over vague ones ("uses Python 3.11 on macOS" not "uses Python")
- Date-stamp decisions: "YYYY-MM-DD: decided to..."
- If unsure whether something is worth remembering, ask the user first
- Memory entries should be one line each — no paragraphs
