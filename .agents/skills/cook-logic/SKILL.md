---
name: cook-logic
description: Implement an approved Treasure Hunter gameplay feature in Agent B's worktree while preserving Agent A art contracts and shared ownership boundaries.
---

# Cook Logic

This skill belongs to Agent B. Agent A may inspect it but must not use it to edit
gameplay-owned files.

## Input

- Approved gameplay plan.
- Current art-to-logic handoff and stable asset/event contracts.

## Output

Gameplay implementation, gameplay tests, logic reports, and logic-to-art handoff.

## Acceptance Criteria

- Stable gameplay IDs and asset keys are preserved or migrated by an approved plan.
- No Agent A-owned file is overwritten.
- Behavior changes have executed test evidence.
- Visual requirements are expressed through agreed contracts, not hard-coded
  proprietary asset paths in unrelated systems.

## Failure Handling

Stop when art metadata, visual events, or a shared runtime file requires Agent A
coordination. Propose the contract through the handoff.
