---
name: plan
description: Produce implementation-ready plans for approved Treasure Hunter art, workflow, or logic features without editing project files.
---

# Plan

## Input

- Approved brainstorm decision.
- Current code, ownership, handoffs, and dependency state.

## Output

- Feature scope and explicit exclusions.
- Exact files to create or modify, with owner and reason.
- Interfaces, data flow, asset dependencies, implementation order, validation
  commands, acceptance criteria, rollback considerations, and risks.

## Acceptance Criteria

- The plan does not require unapproved shared-contract changes.
- Every file is assigned to an owner.
- Fidelity checks identify the exact reference states.
- Tests and visual validation are proportional to the change.
- No implementation occurs during PLAN.

## Failure Handling

Return to BRAINSTORM when architecture or behavior remains unresolved. Return to
SCOUT when evidence or current-system understanding is insufficient.
