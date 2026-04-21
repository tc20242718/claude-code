---
name: brand-guidelines
description: Use when the user provides brand guidelines and wants all generated content to match their brand voice, tone, visual identity, and style conventions. Activate at session start when brand consistency is required.
---

# Brand Guidelines Skill

## Session Initialization

At the start of a brand-consistency session, ask the user to provide:
1. Brand voice descriptors (e.g. "conversational but authoritative", "playful but precise")
2. Words/phrases to always use (brand-specific terms)
3. Words/phrases to never use (competitor names, avoided jargon)
4. Tone by channel (formal for legal, casual for social, etc.)
5. Any existing style guide document to reference

Store these as session context and apply them to every output.

## Voice and Tone Application

- **Voice** is consistent (who the brand is) - does not change
- **Tone** adapts to context (how the brand speaks in a given situation)
- Check each output against the provided voice descriptors before delivering it
- If a requested output conflicts with brand guidelines, flag the conflict and offer an alternative

## Content Consistency Checklist

Before delivering any brand content:
- [ ] Correct product/company name spelling and capitalization
- [ ] Approved terminology used (not competitor or generic terms)
- [ ] Voice matches provided descriptors
- [ ] Tone appropriate for the channel/context
- [ ] No claims that are not supported by provided facts
- [ ] CTA language matches brand standard
- [ ] Reading level matches brand standard (use Flesch-Kincaid as reference)

## Style Conventions

If no specific style guide is provided, default to:
- AP Style for editorial content
- Oxford comma in lists
- Numbers: spell out one through nine, numerals for 10+
- Dates: Month DD, YYYY (April 21, 2026)
- Percentages: use % symbol with numerals (15%)
- Em dashes with spaces around them ( — ) in editorial; no spaces in headlines

## Brand Voice Archetypes (reference)

Help users identify their voice using these archetypes:
- **Sage**: Expert, trusted, calm. Words: "insight", "proven", "trusted"
- **Explorer**: Adventurous, curious, pioneering. Words: "discover", "new", "beyond"
- **Everyman**: Approachable, honest, direct. Words: "simple", "real", "for everyone"
- **Jester**: Playful, witty, disruptive. Words: "seriously though", "yeah we know", "plot twist"
- **Ruler**: Authoritative, premium, precise. Words: "exceptional", "uncompromising", "crafted"
