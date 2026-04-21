#!/usr/bin/env bash
# Nightly memory consolidation ("dreaming") for Claude Code.
# Run this at 3 AM via cron:
#   0 3 * * * /root/.claude/dreaming.sh >> /root/.claude/dreaming.log 2>&1
#
# What it does:
#   1. Finds today's Claude Code session logs
#   2. Calls Claude to extract and consolidate key memories
#   3. Appends them to ~/.claude/CLAUDE.md (deduplicating against existing entries)

set -euo pipefail

DATE=$(date +%Y-%m-%d)
MEMORY_FILE="$HOME/.claude/CLAUDE.md"
LOG_DIR="$HOME/.claude/sessions"
DREAMING_LOG="$HOME/.claude/dreaming.log"

echo "[$DATE 03:00] Dreaming started..." >> "$DREAMING_LOG"

# Find session files modified in the last 24 hours
RECENT_SESSIONS=$(find "$LOG_DIR" -name "*.jsonl" -newer "$MEMORY_FILE" -type f 2>/dev/null | head -20)

if [ -z "$RECENT_SESSIONS" ]; then
    echo "[$DATE 03:00] No new sessions to consolidate." >> "$DREAMING_LOG"
    exit 0
fi

# Extract user messages from session logs (JSONL format)
CONTEXT=$(for f in $RECENT_SESSIONS; do
    # Pull human-turn content from session JSONL
    python3 -c "
import json, sys
for line in open('$f'):
    try:
        obj = json.loads(line)
        # Session JSONL stores messages; extract human turns
        if isinstance(obj, dict):
            role = obj.get('role', '')
            content = obj.get('content', '')
            if role == 'human' and isinstance(content, str) and len(content) > 20:
                print(content[:500])
    except:
        pass
" 2>/dev/null
done | head -200)

if [ -z "$CONTEXT" ]; then
    echo "[$DATE 03:00] Could not extract session content." >> "$DREAMING_LOG"
    exit 0
fi

# Ask Claude to extract memorable facts from today's sessions
PROMPT="You are consolidating memories from today's Claude Code sessions into long-term memory.

Here are excerpts from today's user messages:
---
$CONTEXT
---

Current memory file contents:
---
$(cat "$MEMORY_FILE")
---

Extract any new facts worth remembering: user preferences, decisions made, project context, or important information stated by the user.

Rules:
- Only include facts explicitly stated by the user (not inferred)
- Skip anything already in the memory file
- Format as a markdown bullet list grouped by category: Preferences, Projects, Decisions, People, Notes
- If nothing new is worth remembering, output exactly: NO_NEW_MEMORIES

Output only the new memory entries or NO_NEW_MEMORIES."

NEW_MEMORIES=$(claude --print "$PROMPT" 2>/dev/null || echo "")

if [ -z "$NEW_MEMORIES" ] || [ "$NEW_MEMORIES" = "NO_NEW_MEMORIES" ]; then
    echo "[$DATE 03:00] No new memories to add." >> "$DREAMING_LOG"
    exit 0
fi

# Append new memories to the memory file under the appropriate sections
echo "" >> "$MEMORY_FILE"
echo "<!-- Dreaming: $DATE -->" >> "$MEMORY_FILE"
echo "$NEW_MEMORIES" >> "$MEMORY_FILE"

echo "[$DATE 03:00] Dreaming complete. New memories added." >> "$DREAMING_LOG"
echo "$NEW_MEMORIES" >> "$DREAMING_LOG"
