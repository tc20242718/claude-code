import os,subprocess,json,shutil
H=os.path.expanduser("~")
D=os.path.join(H,"Documents")
os.makedirs(D,exist_ok=True)
docs={
"MacMini-Operations-Runbook.md":"""# MacMini-AI-Coach Operations Runbook

## Daily Tasks
### Morning Check (9 AM)
- lsof -i :11434
- lsof -i :8000
- ps aux | grep telegram | grep -v grep

### Afternoon Check (3 PM)
Send /status via Telegram — expected response under 10 seconds

### Evening Check (6 PM)
- tail -20 ~/.openclaw/logs/agent.log

## Weekly Tasks (Tuesday 2 AM)
- Ollama inference test
- Model baseline: cold 8-15s, warm 2-5s

## Monthly Tasks (Last Friday)
- Security: ps aux | grep -E "ollama|openclaw|telegram"
- Disk: df -h
- Backups: ls -lh ~/.macmini-backups/

## Alert Thresholds
- Ollama timeout >120s: restart service + check memory
- Memory >85%: check processes, restart bot
- Disk >80%: clear logs
- Errors >5/hour: check logs, escalate

## Rollback
### Ollama
cp ~/.ollama/config.json.backup.2026-04-26 ~/.ollama/config.json
launchctl stop com.ollama.OllamaServer && sleep 3 && launchctl start com.ollama.OllamaServer

### OpenClaw
cp ~/.openclaw/openclaw.json.backup.2026-04-26 ~/.openclaw/openclaw.json
""",
"MacMini-User-Guide.md":"""# MacMini-AI-Coach User Guide

## Expected Response Times
- /status: 2-5s (max 10s)
- /wiki search: 3-8s (max 15s)
- /learn save: 2-4s (max 10s)
- /draft post: 8-15s (max 30s)
- Cold load (first msg after 30m idle): 8-12s (max 20s)

## Common Workflows
### Save to Knowledge Base
/learn Save this: [paste content]

### Search Knowledge Base
/wiki What do I have on [topic]?

### Draft Content
/draft linkedin Write about [topic]

### System Health
/status

### Cloud Escalation
/escalate [complex query]

## Troubleshooting
**Timeout >30s:** Check lsof -i :11434, retry after 30s
**Bot unresponsive:** SSH in, check ps aux | grep telegram, restart OpenClaw
**System errors:** Send /status, check ~/.openclaw/logs/agent.log
""",
"MacMini-Disaster-Recovery.md":"""# MacMini-AI-Coach Disaster Recovery Runbook

## Scenario 1: Ollama Won't Start
kill -9 $(lsof -t -i:11434) 2>/dev/null || true
cp ~/.ollama/config.json.backup.2026-04-26 ~/.ollama/config.json
launchctl stop com.ollama.OllamaServer
sleep 5
launchctl start com.ollama.OllamaServer
lsof -i :11434

## Scenario 2: OpenClaw Config Corrupted
cp ~/.openclaw/openclaw.json.backup.2026-04-26 ~/.openclaw/openclaw.json
python3 -m json.tool < ~/.openclaw/openclaw.json > /dev/null && echo OK

## Scenario 3: Obsidian Vault Sync Lost
cd ~/Library/CloudStorage/ProtonDrive-tcaiapi2025@gmail.com-folder/Documents/vault
git reset --hard origin/main && git clean -fd

## Scenario 4: Out of Memory
top -l 1 | head -20
launchctl stop com.ollama.OllamaServer
sleep 5 && launchctl start com.ollama.OllamaServer

## Scenario 5: Complete System Restore
cp ~/.ollama/config.json.backup.2026-04-26 ~/.ollama/config.json
cp ~/.openclaw/openclaw.json.backup.2026-04-26 ~/.openclaw/openclaw.json
launchctl stop com.ollama.OllamaServer
sleep 3 && launchctl start com.ollama.OllamaServer

## Backup Locations
- Ollama:    ~/.ollama/config.json.backup.2026-04-26
- OpenClaw:  ~/.openclaw/openclaw.json.backup.2026-04-26
- Archive:   ~/.macmini-backups/2026-04-26/
""",
"MacMini-Hermes-Learning-Loop-Spec.md":"""# Hermes Learning Loop Technical Specification

## Feedback Threshold
- User rating >= 4/5: add to learning buffer
- 5+ similar queries: skill generation candidate
- Similarity threshold: cosine similarity >= 0.75

## Pattern Detection
1. Extract intent from query
2. Extract key entities
3. Score similarity to prior queries
4. Cluster similar queries

## Skill Generation Pipeline
1. Identify common underlying question
2. Generate skill prompt template (tag v1.0)
3. Test on past queries (must score >85%)
4. Deploy if passing

## Versioning
- v1.0 Initial generation
- v1.1 Minor improvement
- v2.0 Major rewrite (rollback if accuracy drops >5% on 10+ queries)

## Current Skills
- QuantumShield v1.2 Stable 94%
- TruthEngine   v1.0 Stable 88%
- DeepResearch  v1.1 Stable 91%
- HonestFriend  v1.0 Stable 89%
- GrokSkills    v1.3 Stable 92%

## Safe Words
- pineapple: exit skill mode, return to general agent
- blue moon:  activate humility mode in TruthEngine

## Learning Loop
Query > Response > Rate(1-5) > Buffer(>=4) > Cluster > Generate > Test > Deploy > Monitor
"""}
print("\n=== Part 5: Creating Documentation ===")
for name,content in docs.items():
    p=os.path.join(D,name)
    open(p,"w").write(content)
    print("  created:",p)
print("\n=== Part 4: Integration Tests ===")
def curl(url,data):
    try:
        r=subprocess.run(["curl","-sf",url,"-H","Content-Type: application/json","-d",data],capture_output=True,text=True,timeout=60)
        return json.loads(r.stdout) if r.stdout.strip() else None
    except:return None
def port(p):
    return subprocess.run(["lsof","-i",f":{p}"],capture_output=True).returncode==0
r=curl("http://localhost:11434/api/chat",'{"model":"qwen3:14b","messages":[{"role":"user","content":"What is 2+2?"}],"stream":false}')
print("  Ollama qwen3:14b  ",("OK done=true" if r and r.get("done") else "FAIL - not responding on :11434"))
r=curl("http://localhost:8000/v1/chat/completions",'{"model":"qwen3:14b","messages":[{"role":"user","content":"What is 2+2?"}]}')
print("  OpenClaw :8000    ",("OK choices present" if r and r.get("choices") else "FAIL - not responding (may not be started)"))
print("  Port :11434       ",("open" if port(11434) else "closed"))
print("  Port :8000        ",("open" if port(8000) else "closed"))
print("\n=== Part 6: Checklist ===")
checks=[
    ("Ollama installed",lambda:subprocess.run(["ollama","--version"],capture_output=True).returncode==0),
    ("keep_alive=30m",lambda:json.load(open(H+"/.ollama/config.json")).get("keep_alive")=="30m"),
    ("Ollama on :11434",lambda:port(11434)),
    ("qwen3 downloaded",lambda:"qwen3" in subprocess.run(["ollama","list"],capture_output=True,text=True).stdout),
    ("OpenClaw timeout=300000",lambda:json.load(open(H+"/.openclaw/openclaw.json"))["models"]["providers"]["ollama"]["timeout"]==300000),
    ("Ollama backup",lambda:os.path.exists(H+"/.ollama/config.json.backup.2026-04-26")),
    ("OpenClaw backup",lambda:os.path.exists(H+"/.openclaw/openclaw.json.backup.2026-04-26")),
    ("ClamAV",lambda:subprocess.run(["which","clamscan"],capture_output=True).returncode==0),
    ("LuLu",lambda:subprocess.run(["pgrep","-i","lulu"],capture_output=True).returncode==0),
]+[("Doc: "+n,eval(f"lambda n='{n}': os.path.exists(os.path.join(D,n))")) for n in docs]
fails=0
for label,fn in checks:
    try:ok=fn()
    except:ok=False
    print(f"  {'OK' if ok else 'FAIL'}  {label}")
    if not ok:fails+=1
print("\n=== Part 7: Sign-Off ===")
bd=H+"/.macmini-backups/2026-04-26"
os.makedirs(bd,exist_ok=True)
for src,dst in [(H+"/.ollama/config.json","ollama-config.json"),(H+"/.openclaw/openclaw.json","openclaw.json")]:
    if os.path.exists(src):shutil.copy2(src,bd+"/"+dst);print("  archived:",dst)
for n in docs:
    p=os.path.join(D,n)
    if os.path.exists(p):shutil.copy2(p,bd+"/"+n);print("  archived:",n)
print("\n=== Done ===")
print(f"  {len(docs)} docs created, {fails} checklist failures")
print("  Next: check primary model mismatch, verify Hermes/NemoClaw ports 9000/9100")
