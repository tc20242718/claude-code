---
name: canva
description: Use when the user wants to create social graphics, presentations, banners, logos, or other visual designs using Canva. Generates Canva-ready design briefs, suggests templates, or builds designs via the Canva API if credentials are available.
---

# Canva Design Skill

## Two Modes

### Mode 1: Design Brief (no API key needed)
Generate a detailed brief the user can execute manually in Canva.

### Mode 2: Canva API (requires CANVA_API_TOKEN)
Use the Canva Connect API to create designs programmatically.

---

## Mode 1: Design Brief

When the user describes what they need, produce:

```
## Canva Design Brief

**Design type**: [Social post / Presentation / Banner / Logo / etc.]
**Dimensions**: [e.g. 1080x1080px for Instagram, 1920x1080px for presentation]
**Suggested template search**: "[keyword to search in Canva]"

### Content
- Headline: "[text]"
- Subheadline: "[text]"
- Body copy: "[text]"
- CTA: "[text]"

### Visual Direction
- Color palette: [hex codes]
- Font style: [e.g. "bold sans-serif headline, light body"]
- Image/icon suggestions: [describe what to search for]
- Layout: [describe arrangement]

### Brand Notes
[Any brand guidelines to apply]
```

## Mode 2: Canva API Workflow

Requires: `CANVA_API_TOKEN` environment variable

### Create a design
```bash
curl -X POST \
  -H "Authorization: Bearer $CANVA_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"design_type": {"type": "preset", "name": "SocialMedia"}}' \
  https://api.canva.com/rest/v1/designs
```

### Export the design
```bash
curl -X POST \
  -H "Authorization: Bearer $CANVA_API_TOKEN" \
  -d '{"format": "png"}' \
  https://api.canva.com/rest/v1/designs/{DESIGN_ID}/exports
```

## Common Design Sizes

| Format | Dimensions |
|--------|-----------|
| Instagram Post | 1080 x 1080px |
| Instagram Story | 1080 x 1920px |
| Twitter/X Post | 1600 x 900px |
| LinkedIn Banner | 1584 x 396px |
| Facebook Cover | 851 x 315px |
| Presentation | 1920 x 1080px |
| YouTube Thumbnail | 1280 x 720px |

## Setup

Get a Canva API token at: https://www.canva.com/developers/
Set it with: `export CANVA_API_TOKEN=your_token_here`
