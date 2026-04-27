#!/usr/bin/env bash
# Part 6: Pre-Deployment Master Checklist
# Run on Mac Mini as: bash part6-checklist.sh

set -uo pipefail

PASS=0
WARN=0
FAIL=0

ok()   { echo "✅ $1"; ((PASS++)); }
warn() { echo "⚠️  $1 — $2"; ((WARN++)); }
fail() { echo "❌ $1 — $2"; ((FAIL++)); }

echo "=== PRE-DEPLOYMENT MASTER CHECKLIST ==="
echo ""

echo "--- OLLAMA ---"
if ollama --version &>/dev/null; then
  ok "Ollama installed ($(ollama --version))"
else
  fail "Ollama installed" "command not found"
fi

if grep -q '"keep_alive": "30m"' ~/.ollama/config.json 2>/dev/null; then
  ok "keep_alive=30m"
else
  fail "keep_alive=30m" "value missing or incorrect in ~/.ollama/config.json"
fi

if lsof -i :11434 &>/dev/null; then
  ok "Ollama running on :11434"
else
  fail "Ollama running on :11434" "port not open"
fi

if ollama list 2>/dev/null | grep -q "qwen3"; then
  ok "qwen3:14b downloaded"
else
  fail "qwen3:14b downloaded" "not found in ollama list"
fi

echo ""
echo "--- OPENCLAW ---"
if grep -q '"timeout": 300000' ~/.openclaw/openclaw.json 2>/dev/null; then
  ok "OpenClaw timeout=300000ms"
else
  fail "OpenClaw timeout=300000ms" "value missing or incorrect"
fi

if [ -f ~/.ollama/config.json.backup.2026-04-26 ]; then
  ok "Ollama config backup exists"
else
  warn "Ollama config backup" "~/.ollama/config.json.backup.2026-04-26 not found"
fi

if [ -f ~/.openclaw/openclaw.json.backup.2026-04-26 ]; then
  ok "OpenClaw config backup exists"
else
  warn "OpenClaw config backup" "~/.openclaw/openclaw.json.backup.2026-04-26 not found"
fi

echo ""
echo "--- SECURITY ---"
if command -v clamscan &>/dev/null; then
  ok "ClamAV installed"
else
  warn "ClamAV" "clamscan not found in PATH"
fi

if ps aux | grep -i lulu | grep -v grep &>/dev/null; then
  ok "LuLu firewall running"
else
  warn "LuLu" "process not detected"
fi

echo ""
echo "--- DOCUMENTATION ---"
for doc in \
  "MacMini-Operations-Runbook.md" \
  "MacMini-User-Guide.md" \
  "MacMini-Disaster-Recovery.md" \
  "MacMini-Hermes-Learning-Loop-Spec.md"
do
  if [ -f ~/Documents/"$doc" ]; then
    ok "$doc"
  else
    fail "$doc" "not found in ~/Documents/"
  fi
done

echo ""
echo "=== CHECKLIST SUMMARY ==="
echo "  Passed:   $PASS"
echo "  Warnings: $WARN"
echo "  Failed:   $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "❌ Fix all failures before proceeding to Part 7."
  exit 1
elif [[ $WARN -gt 0 ]]; then
  echo "⚠️  Warnings present — review before proceeding."
else
  echo "✅ All checks passed. Ready for Part 7."
fi
