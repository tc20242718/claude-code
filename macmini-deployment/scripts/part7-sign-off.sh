#!/usr/bin/env bash
# Part 7: Final Sign-Off — Archive Baseline Snapshot
# Run on Mac Mini as: bash part7-sign-off.sh

set -euo pipefail

BACKUP_DIR=~/.macmini-backups/2026-04-26

echo "=== Part 7: Final Sign-Off ==="
echo ""

echo "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

echo "Archiving Ollama config..."
cp ~/.ollama/config.json "$BACKUP_DIR/"

echo "Archiving OpenClaw config..."
cp ~/.openclaw/openclaw.json "$BACKUP_DIR/"

echo "Archiving documentation..."
cp ~/Documents/MacMini-*.md "$BACKUP_DIR/" 2>/dev/null || echo "  ⚠️  No MacMini-*.md docs found in ~/Documents — run Part 5 first"

echo ""
echo "✅ Baseline snapshot archived to $BACKUP_DIR"
echo ""
echo "Contents:"
ls -lh "$BACKUP_DIR/"

echo ""
echo "=== Sign-Off Complete ==="
echo ""
echo "Next steps:"
echo "  1. Resolve known issues (see handoff §5)"
echo "  2. Monitor for 72 hours via daily Telegram /status"
echo "  3. Plan Telegram natural-language upgrade sprint"
