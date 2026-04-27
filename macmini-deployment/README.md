# MacMini-AI-Coach Deployment

Parts 1–3 of the handoff were completed live on 2026-04-26.
This directory contains everything needed to complete Parts 4–7.

## Structure

```
macmini-deployment/
├── scripts/
│   ├── part4-integration-tests.sh   # Run and verify Ollama + OpenClaw
│   ├── part6-checklist.sh           # Pre-deployment master checklist
│   └── part7-sign-off.sh            # Archive baseline snapshot
└── docs/
    ├── MacMini-Operations-Runbook.md
    ├── MacMini-User-Guide.md
    ├── MacMini-Disaster-Recovery.md
    └── MacMini-Hermes-Learning-Loop-Spec.md
```

## Execution Order on Mac Mini

```bash
# 1. Copy docs to ~/Documents
cp docs/MacMini-*.md ~/Documents/

# 2. Run integration tests
bash scripts/part4-integration-tests.sh

# 3. Run pre-deployment checklist (all items must show ✅)
bash scripts/part6-checklist.sh

# 4. Archive baseline snapshot
bash scripts/part7-sign-off.sh
```

## Known Issues (Resolve After Deployment)

### Primary model mismatch

`openclaw.json` defaults to `ollama/llama3.1:8b` but Telegram `/status` reports `ollama/qwen3:14b`.
Verify and align:

```bash
cat ~/.openclaw/agents/main/agent/models.json | grep -A5 '"primary"'
cat ~/.openclaw/openclaw.json | grep '"primary"'
```

### Hermes & NemoClaw status

```bash
lsof -i :9000   # Hermes
lsof -i :9100   # NemoClaw
ps aux | grep -E "hermes|nemoclaw"
```

### Telegram natural-language routing (next sprint)

Current: slash-command only (`/status`, `/learn`, `/wiki`).
Target: natural language intent classifier on `qwen3:14b` — separate sprint, ~2–3 hours.
