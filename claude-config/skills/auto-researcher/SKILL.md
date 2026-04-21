---
name: auto-researcher
description: Use when the user wants to run systematic experiments to evaluate or improve an AI model, prompt, or system iteratively - an automated experiment-and-improve loop driven by evidence.
---

# Auto-Researcher Skill

## Overview

This skill implements an iterative experiment-and-improve loop for AI systems, prompts, or models. Each cycle produces a measurable improvement based on evidence from the previous run.

## Experiment Loop Structure

### Cycle N: [Hypothesis]

**1. Define the Experiment**
- Hypothesis: What do you expect will improve and why?
- Variable: What single thing are you changing?
- Control: What stays the same?
- Success metric: How will you measure improvement?
- Sample size: How many test cases will you run?

**2. Run the Experiment**
- Execute the test cases consistently
- Record all outputs, not just the interesting ones
- Note any unexpected behaviors

**3. Analyze Results**
- Compare against baseline (Cycle N-1 or initial state)
- Calculate improvement on the success metric
- Identify failure modes and edge cases
- Note what worked AND what regressed

**4. Update the System**
- Make only the change that the evidence supports
- Document the rationale for the change
- Keep a log of all changes across cycles

**5. Set Next Hypothesis**
- Based on the analysis, what should be tested next?
- Prioritize changes with highest expected impact

## Experiment Log Format

```
## Cycle [N] - [Date]
**Hypothesis**: [statement]
**Change**: [what was modified]
**Results**:
- Metric before: [value]
- Metric after: [value]
- Improvement: [%]
**Key observations**: [qualitative notes]
**Decision**: [keep change / revert / modify]
**Next hypothesis**: [statement]
```

## Guardrails

- Change one variable per cycle (never multiple simultaneously)
- Always compare to the same baseline test set
- Document regressions as carefully as improvements
- Stop condition: when improvement rate falls below threshold (user defines this)
- Maximum cycles: define upfront to avoid infinite loops
