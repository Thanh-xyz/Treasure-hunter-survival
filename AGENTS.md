# Cinderwild Agent Rules

These rules apply to the entire repository (folder and Godot `config/name`: `emberfield`).
Cinderwild is an **original** 2D pixel-art survival RPG. It aims for gameplay breadth and depth comparable to Treasure Hunter – Survival, built through
independent design, implementation and content. Preserve the existing Godot 4.6 project and its
architecture; never replace it with a new scaffold.

Superseded on 2026-11-07 by owner approval: the earlier "Treasure Hunter Recreation" rules
(pixel parity, runtime captures as visual source of truth, `local_only` extracted assets). The
Agent A / Agent B split is stood down; their branches and worktrees are kept untouched as an
archive.

## Design sources

- Current design: `docs/design/` (start at `GAME_DESIGN_DOCUMENT.md`) and roadmap
  `docs/design/ROADMAP.md`.
- Current state: `docs/reports/SCOUT_REPORT.md` and companion reports.
- When code and design disagree, record the difference and ask; don't silently pick one.

## Workflow

Use the following stages in order:

`SCOUT -> BRAINSTORM -> PLAN -> HUMAN APPROVAL -> IMPLEMENT -> TEST -> REVIEW -> PR -> MAIN`

- Record the active stage and its evidence.
- Do not silently skip a stage or claim validation that was not executed.
- Human approval may be specific or a standing approval for a clearly defined plan. Stop when
  scope, architecture, a save format, or a shared contract expands beyond that approval.
- Tasks marked 🔒 in the roadmap always need explicit approval before IMPLEMENT.
- Every feature uses a dedicated branch and receives testing and review.
- Never commit directly to `main`, force-push, rewrite history, or delete branches/worktrees
  without explicit approval. Never push or open a PR without the owner asking.

## Originality and assets

The game's title, lore, characters, monsters, bosses, items, icons, maps, tilesets, UI, animations,
quests, dialogue, audio and balance numbers must be original.

- Research the reference game only through lawful public sources (store pages, official site,
  public wiki, public videos). Use it for general mechanics, never for names, text, numbers, maps,
  layouts or art.
- **Never use as a production resource**: anything in
  `/home/thanh/Documents/1.Projects/assets-ths` (decompiled XAPK, extracted images and configs),
  `assets/treasure_hunter/**`, `docs/original-captures/**`, or data copied from them. These are
  status `excluded`. Existing uses are replaced and then retired per
  `docs/design/ASSET_REPLACEMENT_PLAN.md`; don't delete them before the replacement passes and
  the owner approves.
- Owner decision 2026-11-07: reference-game assets are **not used** in the game. They may be
  consulted only for general style cues (resolution, sprite scale, readability). Never trace,
  redraw, recolour or closely imitate a specific sprite, icon, UI element or design.
- The `excluded` status changes only if a written licence from the rights holder of the reference
  game, covering use in this project, is stored under `docs/legal/` and approved by the owner. A
  general statement that the material is "authorised" is not enough.
- Owner decision 2026-11-08: game graphics (characters, monsters, tiles, items, UI) come from free,
  licence-verified packs found online (CC0 preferred: Ninja Adventure, Kenney). Do not author new
  art. Copy only the files used into `assets/<pack>/` together with the pack's licence file, and
  register them with `tools/provenance/register_third_party.py`.
- Asset priority: original Cinderwild assets → verified-licence assets with documented
  commercial use → new original pixel art → properly licensed third-party packs.
- Every production asset needs a provenance record (source, creator, licence, commercial use,
  modification, attribution, restrictions). Assets without one are `unverified`: allowed in
  development, never in a public or commercial build.
- Reference assets by stable asset ID, not hard-coded paths in gameplay data.
- Do not modify the reference game's data or bypass platform protections.

## Visual style

- 2D pixel art, 16 px tile grid, nearest-neighbour filtering, integer scaling.
- Keep palettes, scale and outline rules consistent (art bible to be added in PLAN).
- Visual features follow `specification -> render -> screenshot -> review -> fix`. Don't claim a
  visual result without a render.

## Implementation boundaries

- Keep gameplay IDs stable unless an approved migration covers saves, quests, LAN snapshots and
  tests (`docs/design/SAVE_MIGRATION_PLAN.md`). Never silently discard player data.
- Gameplay rules live in pure functions/services shared by offline play and the LAN host, never
  only in presentation code or only in `LanSession`.
- Content and balance live in data tables, not UI code.
- Do not install dependencies, convert assets, or change architecture outside an approved plan.
- Do not mark a feature complete without passing tests; placeholders are never "complete".

## Testing

- Godot 4.6 headless suites in `tests/`. Run them with `user://` isolated (for example
  `XDG_DATA_HOME`/`XDG_CONFIG_HOME` pointing at a temporary directory) so real player saves are
  never touched.
- Report real pass/fail output. Known harness warnings must be listed, not hidden.

## Stage closeout

Every stage reports findings, files inspected or modified, validation evidence, risks,
unresolved questions, and the proposed next stage.
