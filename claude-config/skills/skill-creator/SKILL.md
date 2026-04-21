---
name: skill-creator
description: Use when the user wants to create a new Claude Code skill file from a workflow description, task pattern, or set of instructions they want Claude to follow consistently.
---

# Skill Creator Skill

## Process for Creating a New Skill

### Step 1: Gather Requirements
Ask the user:
1. What is the skill's name? (lowercase, hyphenated, no spaces)
2. When should Claude activate this skill? (trigger description for frontmatter)
3. What workflow or behavior should Claude follow when this skill is active?
4. Are there any tools, APIs, or environment variables required?
5. What is the expected output format?

### Step 2: Analyze the Workflow
Before writing the skill:
- Identify the distinct phases of the workflow
- Determine decision points where Claude needs to ask the user for input
- Identify quality checks that should happen before output delivery
- Note any external dependencies (APIs, tools, permissions)

### Step 3: Write the SKILL.md

Use this template:

```markdown
---
name: [skill-name]
description: [When to activate - written as a sentence starting with "Use when..."]
---

# [Skill Display Name]

## Overview
[One paragraph describing what this skill does and why]

## Prerequisites
[List any required tools, API keys, or permissions]

## Workflow

### Phase 1: [Name]
[Instructions]

### Phase 2: [Name]
[Instructions]

## Quality Checklist
- [ ] [Check 1]
- [ ] [Check 2]

## Output Format
[Describe the expected output structure]
```

### Step 4: Validate the Skill

Before delivering the skill file:
- [ ] Frontmatter has both `name` and `description` fields
- [ ] Description clearly tells Claude WHEN to use the skill
- [ ] Instructions are specific and actionable (not vague principles)
- [ ] All phases are ordered logically
- [ ] Quality checklist captures what "done" means
- [ ] No circular references or impossible requirements

### Step 5: Deliver and Install

Provide the complete SKILL.md content and the installation path:
```
~/.claude/skills/[skill-name]/SKILL.md
```

Confirm the skill is discoverable by checking `~/.claude/skills/` directory structure.
