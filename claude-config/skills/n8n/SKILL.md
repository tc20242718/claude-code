---
name: n8n
description: Use when the user wants to build workflow automations, connect APIs, schedule tasks, or create no-code/low-code automation pipelines using n8n.
---

# n8n Workflow Automation Skill

## What is n8n

n8n is a self-hosted workflow automation tool. Workflows are directed graphs of nodes — each node is a trigger, action, or transformation. Connects 400+ services.

## Running n8n

```bash
# With Docker (recommended):
docker run -it --rm \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Or npm global install:
npm install -g n8n && n8n start

# Open UI at: http://localhost:5678
```

## Workflow Design Patterns

### Trigger → Action (simplest)
```
[Schedule/Webhook/Email] → [HTTP Request/DB/Notification]
```

### ETL Pipeline
```
[Trigger] → [Fetch Data] → [Transform] → [Filter] → [Write Output]
```

### AI-Augmented Workflow
```
[Trigger] → [Fetch Data] → [Claude/OpenAI node] → [Parse Response] → [Store/Notify]
```

## When Asked to Build a Workflow

1. Clarify the trigger (schedule, webhook, form, email, app event)
2. Identify data sources and destinations
3. Identify transformations or conditions needed
4. Output a workflow spec:

```
## Workflow: [Name]

**Trigger**: [type and config]

**Nodes**:
1. [Node name] - [type] - [what it does]
   Config: { key: value }
2. [Node name] - [type] - [what it does]

**Data flow**:
- Node 1 output `X` → Node 2 input `Y`

**Error handling**: [behavior on failure]

**Credentials needed**: [service: credential type]
```

## Calling Claude from n8n

Add an **HTTP Request** node:
- Method: POST
- URL: `https://api.anthropic.com/v1/messages`
- Headers: `x-api-key: {{ $env.ANTHROPIC_API_KEY }}`, `anthropic-version: 2023-06-01`
- Body:
```json
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 1024,
  "messages": [{"role": "user", "content": "{{ $json.input }}"}]
}
```

## Key Node Types

| Node | Use case |
|------|---------|
| Schedule Trigger | Cron-style recurring runs |
| Webhook | Receive HTTP events |
| HTTP Request | Call any REST API |
| Code | JavaScript/Python transformations |
| IF / Switch | Conditional branching |
| OpenAI / Claude | LLM calls |
| Gmail / Slack | Email and messaging |
| Google Sheets | Spreadsheet read/write |
| Postgres / MySQL | Database queries |
