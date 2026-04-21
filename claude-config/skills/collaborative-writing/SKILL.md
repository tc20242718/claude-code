---
name: collaborative-writing
description: Use when the user wants to write a document interactively with Claude - alternating between user input, Claude drafting, user review, and iterative refinement rather than one-shot generation.
---

# Collaborative Writing Skill

## Session Setup

At the start of a collaborative writing session, establish:
1. Document type (article, report, proposal, story, email, etc.)
2. Target audience and their assumed knowledge level
3. Desired length (approximate word count or page count)
4. Tone (formal, conversational, persuasive, informative)
5. Review style preference: line-by-line or section-by-section

## The Collaboration Loop

### User's Turn
The user provides one of:
- A new section direction ("Now write about X")
- Feedback on Claude's draft ("Make this more concise", "Add an example here")
- A sentence or paragraph to build from
- A structural decision ("Let's skip this section and jump to conclusions")

### Claude's Turn
Claude will:
1. Acknowledge what the user provided
2. Draft the next section or revision
3. Highlight any choices made that could go differently ("I framed this as a problem-solution - want me to try a narrative approach instead?")
4. Ask one specific question to guide the next step

### Always Track
Maintain a running outline at the top of the working document:
```
## Document Outline (current progress)
- [x] Introduction
- [x] Section 1: Background
- [ ] Section 2: Analysis (in progress)
- [ ] Section 3: Recommendations
- [ ] Conclusion
```

## Revision Modes

When the user requests revisions, use one of these modes:
- **Micro**: Word and sentence level (grammar, word choice, clarity)
- **Macro**: Structure and argument level (reorganize, strengthen logic)
- **Tone**: Adjust voice without changing content
- **Condense**: Reduce word count while preserving meaning

Announce which mode you're applying.

## Version Control

After significant revisions, offer to show a before/after comparison for the changed section. Label versions as v1, v2, etc. and confirm before overwriting a version the user may want to keep.

## Completion

When the document is complete:
1. Present the full final document
2. Provide a word count
3. Offer a final review pass for consistency of voice and style
4. Suggest next steps (formatting, publishing, distribution)
