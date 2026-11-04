# Treasure Hunter Recreation Agent Rules

These rules apply to the entire repository. Preserve the existing Godot 4.6
project and its architecture; never replace it with a new scaffold.

## Workflow

Use the following stages in order:

`SCOUT -> BRAINSTORM -> PLAN -> HUMAN APPROVAL -> COOK -> TEST -> REVIEW -> PR -> INTEGRATION -> MAIN`

- Record the active stage and its evidence.
- Do not silently skip a stage or claim validation that was not executed.
- Human approval may be a specific approval or a standing approval for a clearly
  defined plan. Stop when scope, ownership, architecture, or a shared contract
  expands beyond that approval.
- Every feature uses a dedicated branch and receives testing and review.
- Never commit directly to `main`, force-push, rewrite another agent's commits,
  or run destructive Git operations without explicit approval.

## Worktrees And Ownership

- Agent A worktree: `/home/thanh/Documents/1.Projects/treasure-hunter/art`.
- Agent B worktree: `/home/thanh/Documents/1.Projects/treasure-hunter/logic`.
- Never edit, checkout, reset, rebase, amend, or commit in another agent's
  worktree.

Agent A owns:

- `docs/architecture/game-art-bible.md`
- `docs/architecture/asset-manifest.json`
- `.agents/skills/**`
- This `AGENTS.md`
- Art reports and art-to-logic handoffs

Agent B owns gameplay systems, gameplay data/configuration, gameplay tests, and
logic reports/handoffs. Every other file is shared. Before editing a shared file,
read its recent history, the other agent's handoff, and active worktree diff.
Never overwrite concurrent work.

## Coordination

At the start of every stage, inspect:

- `../shared/coordination/decisions.md`
- `../shared/coordination/dependencies.md`
- `../shared/coordination/conflicts.md`
- `../shared/status/agent-a.md`
- `../shared/status/agent-b.md`
- `../shared/handoffs/agent-a-to-b.md`
- `../shared/handoffs/agent-b-to-a.md`

Update only the current agent's status and handoff. Shared contract changes must
be proposed in a handoff and approved before implementation.

## Visual Fidelity

Treasure Hunter - Survival runtime captures are the visual source of truth.
Use evidence in this order: direct captures, user-supplied extracted assets,
static metadata, then explicitly marked inference. Unknown facts remain unknown.
Do not redesign, modernize, recolor, rescale, or invent missing visual states.

The supplied Treasure Hunter assets are authorized for this local/private build.
Mark them `local_only` in provenance records so they are not accidentally treated
as public redistribution assets.

Every visual feature follows:

`inventory -> specification -> render -> screenshot -> visual diff -> fix`

Do not claim pixel parity without comparison evidence.

## Implementation Boundaries

- Keep gameplay IDs stable unless an approved migration covers saves, quests,
  LAN snapshots, and tests.
- Prefer stable art asset IDs over hard-coded source paths in gameplay data.
- Do not bulk-copy the external 1.7 GB export into the repository.
- Do not install dependencies, convert assets, or change architecture outside an
  approved plan.
- Do not modify the reference game's data or bypass platform protections.

## Stage Closeout

Every stage reports findings, files inspected or modified, validation evidence,
risks, unresolved questions, and the proposed next stage.
