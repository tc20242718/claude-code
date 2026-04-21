---
name: frontend-design
description: Use when building UI components, designing layouts, improving user experience, or implementing design systems. Applies best practices for component architecture, accessibility, and visual design.
---

# Frontend Design Skill

## Design-First Approach

Before writing any code, define:
1. The user's goal (what task are they completing?)
2. The component's states (default, loading, error, empty, success)
3. The responsive breakpoints needed
4. Accessibility requirements (keyboard nav, screen reader, contrast)

## Component Architecture

- One component = one responsibility
- Separate presentational components from container/logic components
- Props should be the minimal interface needed - do not pass data the component does not use
- Compose small components rather than building monolithic ones
- Co-locate styles, tests, and stories with the component file

## Visual Design Principles

- Use a consistent spacing scale (e.g. 4px base unit: 4, 8, 12, 16, 24, 32, 48, 64)
- Typography: no more than 2-3 font families, clear hierarchy (h1 > h2 > body > caption)
- Color: maintain WCAG AA contrast (4.5:1 for body text, 3:1 for large text)
- Interactive elements need clear focus states (never remove outline without replacement)
- Motion should be purposeful - use transitions ≤300ms for micro-interactions

## Accessibility (a11y) Checklist

Every component must satisfy:
- [ ] Keyboard navigable (Tab, Enter, Escape, Arrow keys where appropriate)
- [ ] Screen reader labels (aria-label, aria-describedby, role attributes)
- [ ] Color is not the only information carrier
- [ ] Form inputs have associated labels
- [ ] Images have descriptive alt text (empty alt="" for decorative images)
- [ ] Focus management on modal/dialog open and close

## Responsive Design

- Mobile-first: write base styles for mobile, use min-width media queries to scale up
- Test at 320px, 768px, 1024px, 1440px breakpoints minimum
- Touch targets minimum 44x44px
- Avoid fixed pixel widths on containers

## State Management in UI

Handle all component states explicitly:
- Loading: skeleton screens preferred over spinners for content areas
- Error: actionable error messages with retry options
- Empty: helpful empty states with a call to action
- Success: brief, non-blocking confirmation

## CSS/Styling

- Use CSS custom properties (variables) for theming
- Avoid deeply nested selectors (max 3 levels)
- Use logical properties (margin-inline, padding-block) for RTL support
- Prefer CSS Grid for 2D layouts, Flexbox for 1D
