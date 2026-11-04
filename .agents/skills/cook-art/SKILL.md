---
name: cook-art
description: Implement an approved Treasure Hunter art, asset, UI-visual, documentation, or visual-validation plan inside Agent A's worktree.
---

# Cook Art

## Input

- Human-approved plan and fidelity references.
- Asset manifest entries and current Agent B handoff.

## Procedure

- Work only in Agent A's worktree and approved files.
- Use the supplied source assets for the local/private build when they match the
  verified reference state.
- Preserve nearest-neighbor sampling, transparency, frame order, pivots, naming,
  and scale evidence.
- Add only selected assets; never bulk-import the external export.
- Do not edit gameplay behavior or shared runtime contracts without approval.

## Output

Approved art/assets/docs plus updated manifest, progress report, and handoff.

## Acceptance Criteria

- Diff contains only approved files.
- Every added asset has provenance and integration metadata.
- No undocumented visual invention replaces missing evidence.
- Work is ready for TEST, not declared complete before TEST and REVIEW.

## Failure Handling

Stop on unclear frame sequence, missing evidence, naming collision, unexpected
shared changes, or a required gameplay contract change. Record the dependency.
