#!/usr/bin/env python3
"""
MacMini-AI-Coach deployment setup.
Creates all 4 documentation files and runs Parts 4-7.
Usage: python3 setup.py
"""
import os, subprocess, sys, json

HOME = os.path.expanduser("~")
DOCS = os.path.join(HOME, "Documents")
os.makedirs(DOCS, exist_ok=True)

# ── Part 5: Documentation files ─────────────────────────────────────────────

OPERATIONS_RUNBOOK = """\
# MacMini-AI-Coach Operations Runbook

## Daily Tasks

### Morning Check (9 AM)
```bash
lsof -i :11434
lsof -i :8000
ps aux | grep telegram | grep -v grep
```

### Afternoon Check (3 PM)
Send via Telegram: /status — expected response <10 seconds

### Evening Check (6 PM)
```bash
tail -20 ~/.openclaw/logs/agent.log 2>/dev/null || echo "No logs found"
```

## Weekly Tasks (Tuesday 2 AM)

### LLM Inference Test
```bash
curl -s http://localhost:11434/api/chat \\
  -d '{"model":"qwen3:14b","messages":[{"role":"user","content":"test"}],"stream":false}' \\
  | python3 -m json.tool | grep done
```

### Model Baseline (expected)
- Cold load: 8-15s
- Warm load: 2-5s

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
```

## Alert Thresholds

| Alert          | Threshold      | Action                         |
|----------------|----------------|--------------------------------|
| Ollama timeout | >120s response | Restart service + check memory |
| Memory         | >85%           | Check processes, restart bot   |
| Disk           | >80%           | Clear logs                     |
| Errors         | >5/hour        | Check logs, escalate           |

## Rollback Procedures

### Ollama config
```bash
cp ~/.ollama/config.json.backup.2026-04-26 ~/.ollama/config.json
launchctl stop com.ollama.OllamaServer && sleep 3 && launchctl start com.ollama.OllamaServer
```

### OpenClaw config
```bash
cp ~/.openclaw/openclaw.json.backup.2026-04-26 ~/.openclaw/openclaw.json
# Restart OpenClaw
```
"""

USER_GUIDE = """\
# MacMini-AI-Coach User Guide

## Expected Response Times

| Task                                 | Expected | Max |
|--------------------------------------|----------|-----|
| /status                              | 2-5s     | 10s |
| /wiki search                         | 3-8s     | 15s |
| /learn save                          | 2-4s     | 10s |
| /draft post                          | 8-15s    | 30s |
| Cold load (first msg after 30m idle) | 8-12s    | 20s |

## Common Workflows

### Save to Knowledge Base
```
/learn Save this: [paste content]
```

### Search Knowledge Base
```
/wiki What do I have on [topic]?
```

### Draft Content
```
/draft linkedin Write about [topic]
```

### System Health
```
/status
```

### Cloud Escalation (when local model insufficient)
```
/escalate [complex query]
```

## Troubleshooting

**Timeout (>30s):**
- Check: `lsof -i :11434`
- Retry after 30s (warm model)

**Bot unresponsive:**
- SSH in, check: `ps aux | grep telegram`
- Restart OpenClaw

**System errors:**
- Send /status to verify health
- Check `~/.openclaw/logs/agent.log`
"""

DISASTER_RECOVERY = """\
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

## Scenario 2: OpenClaw Config Corrupted
```bash
cp ~/.openclaw/openclaw.json.backup.2026-04-26 ~/.openclaw/openclaw.json
cat ~/.openclaw/openclaw.json | python3 -m json.tool > /dev/null && echo "Valid JSON" || echo "Invalid"
```

## Scenario 3: Obsidian Vault Sync Lost
```bash
cd ~/Library/CloudStorage/ProtonDrive-tcaiapi2025@gmail.com-folder/Documents/vault
git status
git reset --hard origin/main
git clean -fd
```

## Scenario 4: Out of Memory
```bash
top -l 1 | head -20
launchctl stop com.ollama.OllamaServer
sleep 5
launchctl start com.ollama.OllamaServer
```

## Scenario 5: Complete System Restore
```bash
cp ~/.ollama/config.json.backup.2026-04-26 ~/.ollama/config.json
cp ~/.openclaw/openclaw.json.backup.2026-04-26 ~/.openclaw/openclaw.json
launchctl stop com.ollama.OllamaServer
sleep 3
launchctl start com.ollama.OllamaServer
sleep 10
lsof -i :11434
lsof -i :8000
```

## Backup Locations

| Item           | Path                                              |
|----------------|---------------------------------------------------|
| Ollama config  | ~/.ollama/config.json.backup.2026-04-26           |
| OpenClaw config| ~/.openclaw/openclaw.json.backup.2026-04-26       |
| Archive        | ~/.macmini-backups/2026-04-26/                    |
| Vault          | git remote origin/main                            |
"""

HERMES_SPEC = """\
# Hermes Learning Loop Technical Specification

## Feedback Threshold
- User rating >= 4/5 -> add to learning buffer
- 5+ similar queries -> skill generation candidate
- Similarity threshold: cosine similarity >= 0.75

## Pattern Detection
1. Extract intent from query
2. Extract key entities
3. Score similarity to prior queries
4. Cluster similar queries

## Skill Generation Pipeline
1. Identify common underlying question in cluster
2. Generate skill prompt template
3. Tag as v1.0
4. Test on past queries (must score >85%)
5. Deploy if passing

## Versioning

| Version | Meaning           | Rollback trigger                        |
|---------|-------------------|-----------------------------------------|
| v1.0    | Initial generation| -                                       |
| v1.1    | Minor improvement | -                                       |
| v2.0    | Major rewrite     | accuracy drops >5% on 10+ queries       |

## Current Skills

| Skill         | Version | Status | Accuracy |
|---------------|---------|--------|----------|
| QuantumShield | v1.2    | Stable | 94%      |
| TruthEngine   | v1.0    | Stable | 88%      |
| DeepResearch  | v1.1    | Stable | 91%      |
| HonestFriend  | v1.0    | Stable | 89%      |
| GrokSkills    | v1.3    | Stable | 92%      |

## Safe Words

| Word       | Effect                                          |
|------------|-------------------------------------------------|
| pineapple  | Exit skill mode, return to general agent        |
| blue moon  | Activate humility mode in TruthEngine           |

## Learning Loop

User Query -> Agent Response -> User Rates (1-5) -> Buffer if >=4
  -> Cluster Detection -> Skill Generation -> Test (>85%) -> Deploy -> Monitor -> Iterate
"""

DOCUMENTS = {
    "MacMini-Operations-Runbook.md": OPERATIONS_RUNBOOK,
    "MacMini-User-Guide.md": USER_GUIDE,
    "MacMini-Disaster-Recovery.md": DISASTER_RECOVERY,
    "MacMini-Hermes-Learning-Loop-Spec.md": HERMES_SPEC,
}

# ── Part 5: Write docs ───────────────────────────────────────────────────────

print("\n=== Part 5: Creating Documentation ===")
all_docs_ok = True
for name, content in DOCUMENTS.items():
    path = os.path.join(DOCS, name)
    try:
        with open(path, "w") as f:
            f.write(content)
        print(f"  Created: {path}")
    except Exception as e:
        print(f"  ERROR writing {name}: {e}")
        all_docs_ok = False

# ── Part 4: Integration tests ────────────────────────────────────────────────

print("\n=== Part 4: Integration Tests ===")

def curl_json(url, data):
    try:
        r = subprocess.run(
            ["curl", "-sf", url, "-H", "Content-Type: application/json", "-d", data],
            capture_output=True, text=True, timeout=60
        )
        return json.loads(r.stdout) if r.stdout.strip() else None
    except Exception:
        return None

def port_open(port):
    r = subprocess.run(["lsof", "-i", f":{port}"], capture_output=True)
    return r.returncode == 0

# 4.1 Ollama
ollama_resp = curl_json(
    "http://localhost:11434/api/chat",
    '{"model":"qwen3:14b","messages":[{"role":"user","content":"What is 2+2?"}],"stream":false}'
)
if ollama_resp and ollama_resp.get("done"):
    print(f"  Ollama qwen3:14b  ✅  done=true")
else:
    print(f"  Ollama qwen3:14b  ❌  no response on :11434")

# 4.2 OpenClaw
oc_resp = curl_json(
    "http://localhost:8000/v1/chat/completions",
    '{"model":"qwen3:14b","messages":[{"role":"user","content":"What is 2+2?"}]}'
)
if oc_resp and oc_resp.get("choices"):
    print(f"  OpenClaw :8000    ✅  choices present")
else:
    print(f"  OpenClaw :8000    ❌  no response (OpenClaw may not be running)")

# 4.3 Ports
print(f"  Port :11434       {'✅ open' if port_open(11434) else '❌ closed'}")
print(f"  Port :8000        {'✅ open' if port_open(8000) else '❌ closed (expected if OpenClaw not started)'}")

# ── Part 6: Pre-deployment checklist ────────────────────────────────────────

print("\n=== Part 6: Pre-Deployment Checklist ===")

checks = {}

# Ollama version
r = subprocess.run(["ollama", "--version"], capture_output=True, text=True)
checks["Ollama installed"] = (r.returncode == 0, r.stdout.strip())

# keep_alive
try:
    with open(os.path.join(HOME, ".ollama/config.json")) as f:
        cfg = json.load(f)
    checks["keep_alive=30m"] = (cfg.get("keep_alive") == "30m", "")
except Exception as e:
    checks["keep_alive=30m"] = (False, str(e))

# Ollama port
checks["Ollama on :11434"] = (port_open(11434), "")

# qwen3 model
r = subprocess.run(["ollama", "list"], capture_output=True, text=True)
checks["qwen3:14b downloaded"] = ("qwen3" in r.stdout, "")

# OpenClaw timeout
try:
    with open(os.path.join(HOME, ".openclaw/openclaw.json")) as f:
        oc = json.load(f)
    timeout = oc.get("models", {}).get("providers", {}).get("ollama", {}).get("timeout")
    checks["OpenClaw timeout=300000ms"] = (timeout == 300000, f"found {timeout}")
except Exception as e:
    checks["OpenClaw timeout=300000ms"] = (False, str(e))

# Backups
checks["Ollama backup 2026-04-26"] = (
    os.path.exists(os.path.join(HOME, ".ollama/config.json.backup.2026-04-26")), "")
checks["OpenClaw backup 2026-04-26"] = (
    os.path.exists(os.path.join(HOME, ".openclaw/openclaw.json.backup.2026-04-26")), "")

# ClamAV
r = subprocess.run(["which", "clamscan"], capture_output=True)
checks["ClamAV installed"] = (r.returncode == 0, "")

# LuLu
r = subprocess.run(["pgrep", "-i", "lulu"], capture_output=True)
checks["LuLu running"] = (r.returncode == 0, "")

# Docs
for name in DOCUMENTS:
    checks[name] = (os.path.exists(os.path.join(DOCS, name)), "")

fail_count = 0
for label, (ok, note) in checks.items():
    sym = "✅" if ok else "❌"
    suffix = f"  ({note})" if note else ""
    print(f"  {sym}  {label}{suffix}")
    if not ok:
        fail_count += 1

# ── Part 7: Sign-off ─────────────────────────────────────────────────────────

print("\n=== Part 7: Sign-Off ===")
backup_dir = os.path.join(HOME, ".macmini-backups/2026-04-26")
os.makedirs(backup_dir, exist_ok=True)

for src, dst_name in [
    (os.path.join(HOME, ".ollama/config.json"), "config.json.ollama"),
    (os.path.join(HOME, ".openclaw/openclaw.json"), "openclaw.json"),
]:
    if os.path.exists(src):
        import shutil
        shutil.copy2(src, os.path.join(backup_dir, dst_name))
        print(f"  Archived: {dst_name}")
    else:
        print(f"  SKIP (not found): {src}")

for name in DOCUMENTS:
    src = os.path.join(DOCS, name)
    if os.path.exists(src):
        import shutil
        shutil.copy2(src, os.path.join(backup_dir, name))
        print(f"  Archived: {name}")

print(f"\n  Backup directory: {backup_dir}")
import glob
for f in sorted(glob.glob(os.path.join(backup_dir, "*"))):
    size = os.path.getsize(f)
    print(f"    {os.path.basename(f):45s}  {size:>8} bytes")

# ── Summary ───────────────────────────────────────────────────────────────────

print("\n=== Summary ===")
if fail_count == 0:
    print("  ✅ All checks passed. System ready.")
else:
    print(f"  ⚠️  {fail_count} check(s) failed. Review output above.")

print("\nNext steps:")
print("  1. Verify primary model mismatch: openclaw.json vs Telegram /status")
print("  2. Check Hermes/NemoClaw: lsof -i :9000  /  lsof -i :9100")
print("  3. Monitor for 72h — daily /status via Telegram")
