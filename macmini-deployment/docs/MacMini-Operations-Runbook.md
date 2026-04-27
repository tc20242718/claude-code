# MacMini-AI-Coach Operations Runbook

## Daily Tasks

### Morning Check (9 AM)

```bash
lsof -i :11434
lsof -i :8000
ps aux | grep telegram | grep -v grep
```

### Afternoon Check (3 PM)

Send via Telegram: `/status`
Expected response: <10 seconds

### Evening Check (6 PM)

```bash
tail -20 ~/.openclaw/logs/agent.log 2>/dev/null || echo "No logs found"
```

---

## Weekly Tasks (Tuesday 2 AM)

### LLM Inference Test

```bash
curl -s http://localhost:11434/api/chat \
  -d '{"model":"qwen3:14b","messages":[{"role":"user","content":"test"}],"stream":false}' \
  | python3 -m json.tool | grep done
```

### Model Response Baseline (expected)

| State | Expected | Max |
|-------|----------|-----|
| Cold load | 8–15 s | 20 s |
| Warm load | 2–5 s | 10 s |

---

## Monthly Tasks (Last Friday)

### Security Check

```bash
ps aux | grep -E "ollama|openclaw|telegram"
lsof -i :11434
lsof -i :8000
df -h
```

### Backup Verification

```bash
ls -lh ~/.macmini-backups/
git -C ~/Library/CloudStorage/ProtonDrive-tcaiapi2025@gmail.com-folder/Documents/vault status 2>/dev/null
```

---

## Alert Thresholds

| Alert | Threshold | Action |
|-------|-----------|--------|
| Ollama timeout | >120 s response | Restart service + check memory |
| Memory | >85% | Check processes, restart bot |
| Disk | >80% | Clear logs |
| Errors | >5/hour | Check logs, escalate |

---

## Rollback Procedures

### Ollama config

```bash
cp ~/.ollama/config.json.backup.2026-04-26 ~/.ollama/config.json
launchctl stop com.ollama.OllamaServer
sleep 3
launchctl start com.ollama.OllamaServer
```

### OpenClaw config

```bash
cp ~/.openclaw/openclaw.json.backup.2026-04-26 ~/.openclaw/openclaw.json
# Restart OpenClaw via its normal start mechanism
```
