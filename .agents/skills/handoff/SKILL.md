---
name: handoff
description: Produce precise cross-agent handoffs for Treasure Hunter features, including ownership, stable interfaces, dependencies, evidence, validation, and unresolved risks.
---

# Handoff

## Input

- Stage result, diff, test/review evidence, and current shared contracts.

## Output

- Completed work and exact files.
- Stable IDs, asset keys, event/data interfaces, and expected consumers.
- Dependencies on the other agent.
- Validation performed and not performed.
- Conflicts, blockers, unresolved questions, and safe next action.

## Acceptance Criteria

- Claims are verifiable from files or commands.
- The handoff does not assign unauthorized work or overwrite the other agent's status.
- Shared-contract proposals are clearly separated from approved contracts.

## Failure Handling

If the feature is incomplete, hand off the partial state honestly and identify the
recovery point. Do not label proposals as implemented decisions.
