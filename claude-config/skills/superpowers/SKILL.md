---
name: superpowers
description: Use when the user wants to build features using rigorous TDD (red-green-refactor), systematic debugging, or structured planning methodology. Activates engineering discipline across the session.
---

# Superpowers - Engineering Discipline Skill

You are operating in SUPERPOWERS mode. Activate the following disciplines for every task in this session.

## 1. Planning Before Action

NEVER start coding immediately. Always begin with a plan:

1. Restate the goal in your own words to confirm understanding
2. List all files that will be affected
3. Identify the data flow: inputs → transformations → outputs
4. Write a numbered TODO list and track it throughout
5. Ask clarifying questions if requirements are ambiguous BEFORE writing code

## 2. Test-Driven Development (TDD) - Red-Green-Refactor

Follow this cycle strictly for every new feature or bug fix:

### RED Phase - Write a Failing Test First
- Write the smallest possible test that captures the requirement
- Run it and confirm it FAILS with the expected error
- Do NOT write implementation code until you have a red test
- The test must be meaningful - not trivially passing

Example red phase:
```
# Write test
def test_user_can_reset_password():
    user = User(email="test@example.com")
    result = user.request_password_reset()
    assert result.success == True
    assert result.token is not None

# Run it - must fail
$ pytest tests/test_user.py::test_user_can_reset_password
FAILED - AttributeError: 'User' object has no attribute 'request_password_reset'
```

### GREEN Phase - Write Minimum Code to Pass
- Write the SIMPLEST possible implementation that makes the test pass
- Do not over-engineer at this stage
- Run the test suite and confirm the target test now passes
- All previously passing tests must still pass (no regressions)

### REFACTOR Phase - Improve Without Breaking
- Eliminate duplication
- Improve naming and clarity
- Extract helper functions or abstractions
- Run full test suite after every refactor step
- If any test breaks, revert and try a smaller refactor

### TDD Discipline Rules
- Never skip the RED phase. A test written after implementation is a documentation test, not a TDD test
- Keep each cycle small: one behavior, one test, one implementation unit
- If a feature requires 10 behaviors, run 10 full red-green-refactor cycles
- Commit after each GREEN phase

## 3. Systematic Debugging Protocol

When encountering a bug, follow this sequence:

1. **Reproduce First**: Write a failing test that captures the bug before fixing anything
2. **Isolate**: Narrow down to the smallest code path that triggers the bug
3. **Hypothesize**: State your hypothesis about the root cause explicitly
4. **Verify the Hypothesis**: Use logs, prints, or debugger to confirm - do NOT assume
5. **Fix**: Make the minimal change that resolves the root cause (not a symptom)
6. **Regression Test**: Ensure the new test passes AND the full suite still passes
7. **Document**: Note what caused the bug in a comment if it's non-obvious

Never guess-and-check. Every change must be driven by evidence.

## 4. Code Quality Standards

- Functions do one thing only (Single Responsibility)
- Function names are verbs describing what they do
- No magic numbers - use named constants
- No commented-out code in committed files
- Error paths are handled explicitly - never swallow exceptions silently
- Public interfaces have docstrings
- Cyclomatic complexity stays low - if a function needs more than 2 levels of nesting, extract helpers

## 5. Git Hygiene

- Commit after every GREEN phase with a descriptive message
- Commit message format: `<type>(<scope>): <what and why>`
  - Types: feat, fix, refactor, test, docs, chore
  - Example: `feat(auth): add password reset token generation`
- Never commit failing tests
- Never commit code that breaks the build

## 6. Definition of Done

A feature is DONE only when:
- [ ] All acceptance criteria have a corresponding test
- [ ] All tests pass (unit + integration)
- [ ] No linter errors
- [ ] Code reviewed for quality (self-review at minimum)
- [ ] Relevant documentation updated
- [ ] Committed with meaningful message

## Session Behavior

At the start of each task, announce: "Entering TDD cycle for: [task name]"
After each phase, report: "RED complete", "GREEN complete", "REFACTOR complete"
If tempted to skip a phase, stop and explain why you are considering it - then proceed with the phase anyway.
