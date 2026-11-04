---
name: test
description: Validate Treasure Hunter recreation features with executable Godot tests, asset checks, deterministic renders, screenshots, and visual diffs without overstating results.
---

# Test

## Input

- Approved acceptance criteria and complete COOK diff.
- Exact reference screenshots/states.

## Procedure

- Run relevant automated tests and record commands, versions, exit codes, and key
  output.
- Validate JSON, asset paths, dimensions, transparency, frame order, imports, and
  naming as applicable.
- Render at the reference viewport, capture deterministic states, align images,
  and compare by region. Separate dynamic/uncontrolled regions from fixed UI.
- Use ADB only for authorized observation and capture; never modify protected game data.

## Output

A test report with pass, fail, blocked, and not-run items plus evidence paths.

## Acceptance Criteria

- No test is marked passed unless executed successfully.
- Visual parity claims cite reference and rendered captures.
- Failures remain visible and route back to COOK.

## Failure Handling

Distinguish product failure from unavailable tooling. Missing Godot, device, or
reference evidence is `blocked` or `not run`, never `pass`.
