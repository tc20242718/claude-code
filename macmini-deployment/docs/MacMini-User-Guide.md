# MacMini-AI-Coach User Guide

## Expected Response Times

| Task | Expected | Max |
|------|----------|-----|
| /status | 2–5 s | 10 s |
| /wiki search | 3–8 s | 15 s |
| /learn save | 2–4 s | 10 s |
| /draft post | 8–15 s | 30 s |
| Cold load (first msg after 30 min idle) | 8–12 s | 20 s |

---

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

### System Health Check

```
/status
```

### Cloud Escalation (when local model is insufficient)

```
/escalate [complex query]
```

---

## Troubleshooting

**Timeout (>30 s):**
- SSH in and run: `lsof -i :11434`
- Retry after 30 s — the model may be loading from cold start

**Bot unresponsive:**
- SSH in, check: `ps aux | grep telegram`
- Restart OpenClaw via its normal start mechanism

**System errors:**
- Send `/status` to verify overall health
- Check `~/.openclaw/logs/agent.log`
