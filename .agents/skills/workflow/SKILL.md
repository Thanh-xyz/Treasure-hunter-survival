---
name: workflow
description: Govern staged Treasure Hunter recreation work across Agent A and Agent B, including approvals, ownership, evidence, worktrees, handoffs, and integration gates.
---

# Workflow

Use this skill before routing any non-trivial project feature.

## Input

- User objective and approved scope.
- Current branch/worktree status.
- Shared coordination records and the other agent's latest handoff.

## Procedure

1. Identify the current stage in `SCOUT -> BRAINSTORM -> PLAN -> HUMAN APPROVAL -> COOK -> TEST -> REVIEW -> PR -> INTEGRATION -> MAIN`.
2. Confirm file ownership and active worktree changes.
3. Route the task to the matching stage skill.
4. Preserve evidence labels: verified, inferred, provisional, unknown.
5. Treat a standing human approval as valid only within its documented scope.
6. Stop on unapproved architecture, ownership, destructive action, or shared-contract expansion.

## Output

- Active stage, scope, owner, dependencies, and required report/handoff.
- The next permitted stage and its entry conditions.

## Acceptance Criteria

- No stage is silently skipped.
- No agent edits another agent's worktree or owned files.
- No validation or fidelity claim lacks execution evidence.

## Failure Handling

Record the blocker and remain in the current stage. Do not work around ownership,
approval, or destructive-operation restrictions.
