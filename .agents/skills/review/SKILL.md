---
name: review
description: Review completed Treasure Hunter art or logic diffs for correctness, fidelity, ownership, provenance, regressions, performance, and missing validation before PR.
---

# Review

## Input

- Full feature diff, plan, test evidence, manifests, and relevant handoffs.

## Procedure

- Review findings first, ordered by severity with file references.
- Check scope and ownership, stable IDs, asset duplication, import size,
  transparency, animation metadata, visual evidence, runtime compatibility, and
  documentation drift.
- Compare the final result with the approved plan and Treasure Hunter references.

## Output

Review findings, residual risks, testing gaps, and PR readiness decision.

## Acceptance Criteria

- High/medium findings are resolved or explicitly accepted.
- Diff contains no unrelated or other-agent changes.
- Test evidence covers the changed behavior or records honest blockers.

## Failure Handling

Route defects to COOK and missing validation to TEST. Do not approve based only on
the author's summary.
