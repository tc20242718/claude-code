---
name: slide-deck
description: Use when the user wants to create a slide deck, presentation, or pitch from a topic description, document, or set of talking points.
---

# Slide Deck Skill

## Presentation Design Principles

### Structure First
Before writing any slide content:
1. Define the presentation goal (inform, persuade, sell, report)
2. Identify the audience (executives, technical team, customers, investors)
3. Determine the length (number of slides = roughly 1-2 minutes per slide)
4. Choose a narrative arc (problem-solution, before-after, journey, data story)

### Slide Hierarchy
Every presentation needs:
- **Title slide**: Name, subtitle, presenter, date
- **Agenda/Contents**: For presentations over 10 slides
- **Hook slide**: The compelling opening (a question, a statistic, a story)
- **Body slides**: Content following the chosen arc
- **Summary/Key takeaways**: The 3 things to remember
- **CTA/Next steps**: What happens after this presentation
- **Appendix** (optional): Supporting detail for Q&A

## Slide Content Rules

- One idea per slide (if you need "and also", that's two slides)
- Headline is the conclusion, not the topic ("Revenue grew 40% YoY" not "Revenue")
- Maximum 6 bullets per slide; maximum 8 words per bullet
- Use data visualization for any numbers (describe chart type if visual tools not available)
- Speaker notes contain the full narrative; slides contain the skeleton

## Output Format

Claude will output slides as structured markdown:

```
## Slide [N]: [Slide Title]
**Visual**: [Description of chart, image, or diagram]
**Content**:
- Bullet 1
- Bullet 2
**Speaker Notes**: [Full talking points for this slide]
```

## Presentation Templates

### Pitch Deck (investor/sales)
1. Problem, 2. Solution, 3. Market size, 4. Product demo, 5. Traction,
6. Business model, 7. Competition, 8. Team, 9. Ask

### Executive Summary
1. Situation, 2. Complication, 3. Resolution, 4. Action required

### Technical Deep Dive
1. Context, 2. Current state, 3. Problem definition, 4. Proposed approach,
5. Trade-offs, 6. Implementation plan, 7. Risks and mitigations, 8. Timeline

### Status Report
1. Summary (RAG status), 2. Accomplishments, 3. Issues, 4. Next steps, 5. Decisions needed

## Delivery

Provide the full slide deck in markdown format, then offer:
- Export hints for Google Slides, PowerPoint, Reveal.js, or Marp
- Design theme recommendations based on the audience
- Shortened executive summary version if appropriate
