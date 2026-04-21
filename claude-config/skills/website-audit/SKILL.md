---
name: website-audit
description: Use when the user wants a comprehensive analysis of a website covering performance, SEO, accessibility, security, UX, and content quality.
---

# Website Audit Skill

## Audit Scope Declaration

At the start, confirm which audit categories to include:
- [ ] Performance (Core Web Vitals, load time, assets)
- [ ] SEO (on-page, technical, content)
- [ ] Accessibility (WCAG 2.1 AA compliance)
- [ ] Security (headers, HTTPS, vulnerabilities)
- [ ] UX/Design (navigation, mobile, visual hierarchy)
- [ ] Content Quality (clarity, accuracy, completeness)

## Performance Audit

Check and report:
- Largest Contentful Paint (LCP) target: <2.5s
- First Input Delay / Interaction to Next Paint (INP) target: <200ms
- Cumulative Layout Shift (CLS) target: <0.1
- Time to First Byte (TTFB) target: <800ms
- Total page weight and breakdown by asset type
- Number of HTTP requests
- Render-blocking resources
- Image optimization (format, compression, lazy loading, srcset)
- Cache headers on static assets
- CDN usage

## SEO Audit

- Title tag: present, unique, 50-60 chars, includes primary keyword
- Meta description: present, unique, 150-155 chars, includes CTA
- H1: exactly one per page, includes primary keyword
- Heading hierarchy: logical H1→H2→H3 structure
- Canonical tags: correct and consistent
- robots.txt: present and not blocking important pages
- sitemap.xml: present and submitted to Search Console
- Structured data (schema.org): appropriate markup present
- Mobile-friendliness
- Internal linking: no orphan pages, anchor text quality
- Broken links

## Accessibility Audit

WCAG 2.1 AA checklist:
- Color contrast ratios meet minimums
- All images have alt text
- Form elements have labels
- Keyboard navigation works throughout
- Focus indicators visible
- ARIA landmarks present (header, nav, main, footer)
- Skip navigation link present
- No content relies on color alone
- Videos have captions

## Security Audit

HTTP security headers:
- Content-Security-Policy
- X-Frame-Options
- X-Content-Type-Options
- Strict-Transport-Security (HSTS)
- Referrer-Policy
- Permissions-Policy

Additional checks:
- HTTPS enforced with valid certificate
- Mixed content warnings
- Sensitive data in URLs
- Open redirects
- Exposed admin interfaces

## Report Format

```
# Website Audit: [URL]
Date: [date]

## Executive Summary
Overall score: [score/100]
Critical issues: [count]
Warnings: [count]
Passed: [count]

## Critical Issues (fix immediately)
...

## Warnings (fix soon)
...

## Passed Checks
...

## Recommendations Priority List
1. [Highest impact item]
2. ...
```

Rate each finding: Critical / High / Medium / Low
