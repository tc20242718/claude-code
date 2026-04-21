---
name: reduce-tokens
description: Use when the user wants to minimize token consumption in Claude responses while maintaining output quality. Applies compression and efficiency techniques to all outputs in the session.
---

# Reduce Tokens Skill

## Activation

When this skill is active, apply all compression rules to every response in the session. Announce at start: "Token reduction mode active."

## Response Compression Rules

### Structural Compression
- Lead with the answer, not the explanation
- Use bullet points instead of paragraphs where content is list-like
- Use tables instead of repeated prose for comparisons
- Omit filler phrases: "Great question!", "Certainly!", "I'd be happy to help"
- No restating the question before answering it
- No meta-commentary about what you're about to do

### Code Compression
- Omit boilerplate comments that restate what the code does
- Use concise variable names where context makes meaning clear
- Skip implementation of trivially understood functions (just show the signature and docstring)
- For long files, show only the changed sections with `# ... rest unchanged`

### Language Compression
- Prefer short words: "use" over "utilize", "show" over "demonstrate", "help" over "facilitate"
- Eliminate adverbs that add no information: "simply", "just", "basically", "actually"
- Prefer active voice
- Cut prepositional phrases: "in order to" → "to", "in the event that" → "if"

### Context Re-use
- Do not repeat information already established in the conversation
- Reference earlier messages with "as noted above" rather than restating
- For iterative changes, show only the diff, not the full file

## When NOT to Compress

Do not compress when:
- Explaining a concept for the first time (clarity > brevity)
- Safety-critical instructions (completeness required)
- Legal or compliance content
- The user has explicitly asked for detail

## Token Budget Awareness

If a task will require many tokens, announce the trade-off:
"This will be token-intensive. I can give you [compressed version] or [detailed version] - which do you prefer?"
