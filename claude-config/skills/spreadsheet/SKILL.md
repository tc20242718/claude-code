---
name: spreadsheet
description: Use when the user wants to build a spreadsheet, data model, financial model, tracker, or any tabular data structure from a plain English description.
---

# Spreadsheet Skill

## Requirements Gathering

Before building any spreadsheet, ask:
1. What is the spreadsheet's purpose? (tracking, calculating, reporting, planning)
2. Who will use it and what is their spreadsheet skill level?
3. What data will be entered vs. calculated?
4. How frequently will it be updated?
5. Does it need to connect to other sheets or external data?

## Spreadsheet Design Principles

### Separation of Concerns
- **Inputs sheet**: Raw data entry only, no formulas on this sheet
- **Calculations sheet**: All formulas reference input cells, no manual entry
- **Dashboard/Output sheet**: Summary and visualization, pulls from calculations
- **Reference/Lookup sheet**: Static tables (tax rates, categories, conversion factors)

### Cell Design Rules
- Color code: Yellow = input cell, Blue = formula cell, Green = output/result
- Never hardcode a number in a formula that should be a variable
- Named ranges for key inputs (tax_rate, hourly_rate, start_date)
- No merged cells (they break most automation)
- Headers in Row 1, data starts Row 2

### Formula Best Practices
- Build complex calculations in steps across columns (not one giant nested formula)
- Use IFERROR() to handle edge cases gracefully
- Prefer INDEX/MATCH over VLOOKUP for robustness
- Use structured table references (Table1[Column]) over cell references (A2:A100)
- Add a formula explanation in the cell comment for anything non-obvious

## Output Format

For each spreadsheet design, provide:

```
## Sheet Structure
Sheet 1: [Name] - [Purpose]
Sheet 2: [Name] - [Purpose]

## Column Definitions: [Sheet Name]
| Column | Header | Type | Formula/Notes |
|--------|--------|------|---------------|
| A | Date | Input | YYYY-MM-DD format |
| B | Amount | Input | Currency, 2 decimals |
| C | Category | Input | Dropdown: [list] |
| D | Running Total | Formula | =SUM($B$2:B2) |

## Key Formulas
[Formula name]: `=FORMULA` - explanation of what it calculates

## Validation Rules
- [Column]: [Validation rule and error message]

## Setup Instructions
1. [Step 1]
2. [Step 2]
```

Then provide the spreadsheet as a CSV or markdown table with sample data populated.

## Common Spreadsheet Types

- Budget tracker: income categories, expense categories, monthly vs. actual
- Project timeline: tasks, owner, start, end, status, % complete (Gantt-like)
- Inventory: item, SKU, quantity, reorder point, supplier, cost, price
- KPI dashboard: metric, target, actual, variance, trend
- Employee tracker: name, role, start date, salary, department, manager
