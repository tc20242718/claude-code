# MacMini-AI-Coach Disaster Recovery Runbook

## Scenario 1: Ollama Won't Start

```bash
kill -9 $(lsof -t -i:11434) 2>/dev/null || true
cp ~/.ollama/config.json.backup.2026-04-26 ~/.ollama/config.json
launchctl stop com.ollama.OllamaServer
sleep 5
launchctl start com.ollama.OllamaServer
sleep 10
lsof -i :11434
```

---

## Scenario 2: OpenClaw Config Corrupted

```bash
cp ~/.openclaw/openclaw.json.backup.2026-04-26 ~/.openclaw/openclaw.json
cat ~/.openclaw/openclaw.json | python3 -m json.tool > /dev/null \
  && echo "✅ Valid JSON" || echo "❌ Invalid JSON — check backup"
# Restart OpenClaw via its normal start mechanism
```

---

## Scenario 3: Obsidian Vault Sync Lost

```bash
cd ~/Library/CloudStorage/ProtonDrive-tcaiapi2025@gmail.com-folder/Documents/vault
git status
git reset --hard origin/main
git clean -fd
```

---

## Scenario 4: Out of Memory

```bash
top -l 1 | head -20
launchctl stop com.ollama.OllamaServer
sleep 5
launchctl start com.ollama.OllamaServer
```

---

## Scenario 5: Complete System Restore

```bash
# Step 1: Restore all configs
cp ~/.ollama/config.json.backup.2026-04-26 ~/.ollama/config.json
cp ~/.openclaw/openclaw.json.backup.2026-04-26 ~/.openclaw/openclaw.json

# Step 2: Restart services
launchctl stop com.ollama.OllamaServer
sleep 3
launchctl start com.ollama.OllamaServer
sleep 10

# Step 3: Verify
lsof -i :11434
lsof -i :8000
curl -s http://localhost:11434/api/chat \
  -d '{"model":"qwen3:14b","messages":[{"role":"user","content":"test"}],"stream":false}' \
  | python3 -m json.tool | grep done
```

---

## Backup Locations

| Item | Path |
|------|------|
| Ollama config | `~/.ollama/config.json.backup.2026-04-26` |
| OpenClaw config | `~/.openclaw/openclaw.json.backup.2026-04-26` |
| Archive | `~/.macmini-backups/2026-04-26/` |
| Vault | git remote `origin/main` |
