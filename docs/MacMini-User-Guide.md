# MacMini-AI-Coach User Guide

## Expected Response Times

| Task                                  | Expected | Max  |
|---------------------------------------|----------|------|
| /status                               | 2–5s     | 10s  |
| /wiki search                          | 3–8s     | 15s  |
| /learn save                           | 2–4s     | 10s  |
| /draft post                           | 8–15s    | 30s  |
| Cold load (first msg after 30m idle)  | 8–12s    | 20s  |

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
- Send `/status` to verify health
- Check `~/.openclaw/logs/agent.log`
