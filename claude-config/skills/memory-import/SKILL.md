---
name: memory-import
description: Use when the user wants to import memories, conversation history, or context from an external source (ChatGPT export, text notes, previous AI conversations) into Claude's memory system.
---

# Memory Import Skill

## Overview

Parses external memory sources and converts them into Claude's memory format in `~/.claude/CLAUDE.md`. Supports ChatGPT exports, plain text notes, and structured memory dumps.

## Import Sources

### ChatGPT Memory Export
ChatGPT allows users to export their memory as a JSON or text file.

Process:
1. Ask the user to paste the memory export content
2. Parse each memory item
3. Categorize it (preference, fact, project, person, decision)
4. Deduplicate against existing `~/.claude/CLAUDE.md` entries
5. Append new entries under the appropriate section
6. Report: `Imported N new memories, skipped M duplicates`

### Plain Text Notes
If the user pastes freeform text describing what they want Claude to remember:
1. Extract discrete facts (one idea = one memory entry)
2. Categorize each fact
3. Write to `~/.claude/CLAUDE.md`

### Conversation Transcript
If the user pastes a conversation from another AI:
1. Identify facts stated by the user (not the AI's responses)
2. Identify preferences expressed
3. Identify decisions made
4. Import only user-stated facts — not the AI's outputs or analysis

## Deduplication Rules

Before writing any entry, check if an equivalent entry already exists:
- Exact match → skip
- Semantic match (same fact, different wording) → keep the more specific version
- Contradiction (new fact conflicts with existing) → show both to user and ask which to keep

## Output Format

After import, report:
```
Memory Import Complete
----------------------
Imported: N new entries
Skipped:  M duplicates
Conflicts: K (shown below for your review)

New entries added:
- [entry 1]
- [entry 2]
...
```

## Privacy Note

Remind the user that imported memories are stored in plain text at `~/.claude/CLAUDE.md`. They should not import sensitive credentials, private keys, or personal data they don't want stored in a readable file.
