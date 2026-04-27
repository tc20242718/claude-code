#!/usr/bin/env bash
# Part 4: Integration Tests
# Run on Mac Mini as: bash part4-integration-tests.sh

set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"
  local result="$2"
  if [[ "$result" == "ok" ]]; then
    echo "✅ $label"
    ((PASS++))
  else
    echo "❌ $label — $result"
    ((FAIL++))
  fi
}

echo "=== Part 4: Integration Tests ==="
echo ""

# Test 4.1: Ollama inference
echo "--- Test 4.1: Ollama qwen3:14b inference ---"
RESPONSE=$(curl -sf http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:14b",
    "messages": [{"role": "user", "content": "Explain capital preservation in 2 sentences."}],
    "stream": false
  }' 2>&1) || true

if echo "$RESPONSE" | python3 -m json.tool 2>/dev/null | grep -q '"done": true'; then
  echo "Response preview:"
  echo "$RESPONSE" | python3 -m json.tool | head -20
  check "Ollama qwen3:14b inference" "ok"
else
  check "Ollama qwen3:14b inference" "no 'done: true' in response — is Ollama running on :11434?"
fi

echo ""

# Test 4.2: OpenClaw routing
echo "--- Test 4.2: OpenClaw API routing ---"
OC_RESPONSE=$(curl -sf http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3:14b","messages":[{"role":"user","content":"What is 2+2?"}]}' \
  2>&1) || true

if echo "$OC_RESPONSE" | python3 -m json.tool 2>/dev/null | grep -q '"choices"'; then
  echo "Response preview:"
  echo "$OC_RESPONSE" | python3 -m json.tool | head -20
  check "OpenClaw routing on :8000" "ok"
else
  check "OpenClaw routing on :8000" "no 'choices' in response — is OpenClaw running?"
fi

echo ""

# Test 4.3: Port listeners
echo "--- Test 4.3: Port listeners ---"
if lsof -i :11434 &>/dev/null; then
  check "Ollama listening on :11434" "ok"
else
  check "Ollama listening on :11434" "port not open"
fi

if lsof -i :8000 &>/dev/null; then
  check "OpenClaw listening on :8000" "ok"
else
  check "OpenClaw listening on :8000" "port not open"
fi

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
[[ $FAIL -eq 0 ]] && echo "✅ All integration tests passed" || echo "❌ Fix failures before proceeding to Part 5"
