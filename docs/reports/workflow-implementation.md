# Shared Workflow Implementation

Date: 2026-11-04

## Implemented Structure

```text
.agents/skills/
  workflow
  scout
  brainstorm
  plan
  cook-art
  cook-logic
  test
  review
  git-flow
  handoff
```

Root `AGENTS.md` defines the stage order, worktree isolation, ownership,
coordination paths, fidelity rules, and stage-closeout requirements.

## Stage Contract

```text
SCOUT -> BRAINSTORM -> PLAN -> HUMAN APPROVAL
      -> COOK -> TEST -> REVIEW -> PR -> INTEGRATION -> MAIN
```

Human approval may be scoped standing approval. Agents still stop when scope,
architecture, ownership, destructive operations, or shared contracts expand
beyond that approval.

## Ownership Enforcement

- Agent A owns workflow files, Art Bible, manifest, and art reports/handoffs.
- Agent B owns gameplay systems, data, tests, and logic reports/handoffs.
- All other files are shared and require history, handoff, and conflict checks.
- Agents never edit another agent's worktree.

## Validation Policy

- Tests cannot be marked passed unless executed.
- Visual parity requires reference and rendered comparison evidence.
- Missing tools are recorded as blocked/not run.
- Review checks the full diff, scope, ownership, provenance, performance, and
  compatibility before PR.

## Clone-App Adaptation

The workflow incorporates screenshot inventory, state clustering, design-system
extraction, component specification, and iterative visual diff. It deliberately
excludes Expo/React Native scaffold generation.

The source `clone-app` Skill was inspected from the local ai-app-cloner checkout.
Its applicable principles are carried into the Godot workflow: screens are grouped
into states, navigation and interactions are inventoried, specifications precede
implementation, and the render/screenshot/diff/fix loop is the fidelity engine.
Expo Router, NativeWind, React Native storage, and web build steps are not applicable
to Emberfield and are not executed.

## Validation

All ten Skill directories passed the Codex skill-creator
`quick_validate.py` validator on 2026-11-04. Manifest and ownership checks are
recorded in `docs/reports/game-art-progress.md`.
