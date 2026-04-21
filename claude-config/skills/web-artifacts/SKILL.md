---
name: web-artifacts
description: Use when building interactive web-based tools - dashboards, calculators, data visualizers, mini-apps, widgets, or any self-contained HTML/CSS/JS artifact.
---

# Web Artifacts Skill

## Artifact Design Principles

### Self-Contained by Default
- All artifacts must work as a single HTML file with no external dependencies unless the user explicitly requests CDN links
- Embed all CSS in `<style>` tags and all JavaScript in `<script>` tags
- Use vanilla JS unless a framework is specifically requested

### Progressive Enhancement
1. Start with HTML that works without JavaScript
2. Add CSS for layout and visual design
3. Add JavaScript for interactivity
4. Each layer should degrade gracefully

## Artifact Categories and Patterns

### Dashboard / Data Visualization
- Use CSS Grid for dashboard layout
- Chart.js (via CDN) for charts when needed
- Static sample data embedded in the script
- Include a data refresh button if appropriate
- Color-code metrics (green=good, yellow=warning, red=critical)

### Calculator / Tool
- Clear input validation with helpful error messages
- Show formula or calculation logic visibly
- Results update in real time (on input event, not button click)
- Mobile-friendly number inputs

### Interactive Widget
- Define the interaction model before coding (click, drag, hover, keyboard)
- Smooth CSS transitions on state changes (≤300ms)
- Persist state to localStorage if user would expect it to survive page reload

### Data Table / Report
- Sortable columns by default
- Search/filter if more than 20 rows
- Export to CSV button
- Paginate if more than 50 rows

## Code Quality for Artifacts

- Meaningful IDs and class names (not `div1`, `thing`, etc.)
- CSS custom properties for all colors and spacing (easy to theme)
- No `console.log` left in delivered artifacts
- Tested in mental model for: empty state, one item, many items, max content

## Delivery Format

Deliver artifacts as:
1. Complete HTML file content in a code block
2. Brief description of how to use it
3. List of customization options the user can request
