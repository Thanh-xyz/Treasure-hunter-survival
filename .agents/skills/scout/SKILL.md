---
name: scout
description: Perform read-only investigation of the Emberfield repository, Treasure Hunter evidence, worktrees, GitHub state, skills, tests, and agent dependencies before planning changes.
---

# Scout

## Input

- Repository/worktree paths.
- Reference asset and capture paths.
- Current coordination files and handoffs.

## Procedure

- Inspect the full tracked tree, relevant ignored evidence, docs, plans, skills,
  history, remote refs, PRs, tests, and active worktree diffs.
- Inventory formats, dimensions, transparency, animation evidence, dependencies,
  provenance, and integration status without converting assets.
- Verify important handoff claims against actual files.

## Output

A scout report containing architecture, migration progress, evidence inventory,
ownership conflicts, blockers, and recommended questions for brainstorming.

## Acceptance Criteria

- Repository inspection is read-only.
- Facts cite paths or command evidence.
- Unknown metadata is not guessed.
- The report lists files inspected, validation evidence, risks, and next stage.

## Failure Handling

If required evidence is unavailable, document the gap. If unexpected concurrent
changes appear, pause dependent work until they are identified or accepted.
