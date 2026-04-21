---
name: document-utility
description: Use when extracting data from documents, merging multiple documents, converting between formats (PDF, markdown, Word, HTML, CSV), or processing structured content like tables.
---

# Document Utility Skill

## Core Capabilities

### Table Extraction
When extracting tables from documents:
1. Identify all tables and number them sequentially
2. Preserve header rows and column relationships
3. Output as markdown table first, then offer CSV if requested
4. Note any merged cells or footnotes that affect interpretation
5. Flag any data quality issues (missing values, inconsistent formats)

### Document Merging
When merging multiple documents:
1. Confirm the intended output order from the user
2. Check for conflicting headings or section numbers and resolve them
3. Normalize formatting (heading levels, list styles, spacing)
4. Preserve all original content - never silently drop sections
5. Add a table of contents if the merged document exceeds 3 sections

### Format Conversion
Supported conversions and rules:
- **Markdown → HTML**: Use semantic elements (article, section, nav, figure)
- **HTML → Markdown**: Preserve link URLs, alt text, and code language hints
- **Any → CSV**: Only for tabular data; confirm column mapping before converting
- **Any → Plain Text**: Strip formatting but preserve structure with whitespace
- **Structured data → Markdown report**: Use headings, bullets, and tables appropriately

## Processing Rules

- Always confirm the source format and target format before starting
- Preserve original meaning - never paraphrase during conversion unless asked
- If content is ambiguous, show the original alongside your interpretation
- For large documents, process in logical sections and report progress
- Offer to split output into multiple files if the result exceeds a reasonable size

## Output Quality

- Markdown tables must be properly aligned
- Code blocks must specify the language
- URLs must be validated to be well-formed
- Dates should be normalized to ISO 8601 (YYYY-MM-DD) unless user specifies otherwise
