# Agent A Art Scout Report

Date: 2026-11-04
Branch/worktree: `feature/th-game-art-workflow` in the Agent A worktree
Stage: SCOUT complete; no project implementation occurred during SCOUT.

## Architecture

Emberfield is an existing Godot 4.6 GDScript project using GL Compatibility,
nearest-neighbor rendering, a `720x1600` portrait viewport, component-based scenes,
autoload services, code-defined content catalogs, and procedural map generation.

The migration preserves legacy inventory, equipment, crafting, shops, combat, and
dungeon systems while adding survival fields, heroes, pets, mounts, quests,
homestead, bosses, saves, mobile UI, and partial host-authoritative LAN play.

## Existing Visual Migration

- Four capture-derived field props are integrated.
- Mosqui, Snailu, and Astromophy extracted sprites are integrated.
- Greenwood ground color is measured as `#3c784a`.
- Mobile startup, HUD, field, inventory, death, and system states have render or
  capture harnesses, but no complete visual-diff certification exists.
- Player heroes still reuse generic soldier art or generated pixel visuals.

## Reference Evidence

The user-supplied `assets-ths` archive is approximately 1.7 GB. Its UnityPy
manifests contain 23,505 valid PNGs: 5,086 Texture2D exports and 18,419 cropped
sprites. All manifest files opened successfully during SCOUT.

Image transparency audit:

- 23,454 RGBA images and 51 RGB images.
- 23,012 images contain transparent or partially transparent pixels.
- 442 RGBA images contain a fully opaque alpha channel.

Unity metadata reports 1,505 AnimationClip objects, 227 AnimatorControllers, 55
AnimatorOverrideControllers, 2,365 ParticleSystems, and 27 AudioClips. Standalone
audio files were not recovered by the current export.

## Reuse Assessment

Strong local-use candidates include monsters, pets, mounts, environment props,
village structures, UI frames/icons, equipment, and item art. Character animation,
particle effects, exact pivots, sockets, tile composition, and audio require more
metadata or reconstruction.

The user has authorized supplied assets for the local/private build. This does not
convert their provenance into a public redistribution license.

## Clone-App Methodology

The external clone-app Skill exists locally but is not installed in this project.
Its Expo scaffold is incompatible with Godot. The applicable method is retained:
screen/state inventory, visual-token extraction, component specification, render,
screenshot, diff, and correction.

## Git And Coordination

- `origin` exposes only `main`; no integration branch exists.
- Agent A and the migration base started at `e8fc3c7`.
- Agent B created `feature/th-logic-inventory-transactions` and began gameplay changes.
- Agent A's first feature does not touch those files.
- The shared coordination directory was missing at SCOUT completion.

## Tooling Evidence

- GitHub authentication succeeds as `Thanh-xyz`.
- No PRs were present during SCOUT.
- ADB later detected an authorized Samsung SM-A047F with
  `com.megacombat.treasurehunter` installed.
- No Godot executable was available on the inspected command path, so Godot tests
  were not run during SCOUT.

## Risks

- Mixed art/gameplay files can create cross-agent conflicts.
- Extracted frames often lack verified pivot, timing, and animation dependencies.
- Documentation is behind the current autoload and portrait architecture.
- Pixel parity cannot be claimed until deterministic Godot renders are available.

## Fixed HUD World/Resource Row Evidence

- Decoded `level1` GameObjects `16955` (`RegionTime`), `27924` (`Map`), and
  `15928` (`Gold`) each resolve their active Unity UI Image sprite pointer to
  `sharedassets1.assets:5844` (`Panel_Stats`). Their RectTransforms are
  `250x70`, and the image color is opaque white.
- `Map/Line` GameObject `6901` and `Gold/Line` GameObject `14793` both resolve
  to `sharedassets1.assets:6099` (`Line`). Each separator is placed at x=75 in
  a `25x65` RectTransform. The source is `16x48` with 20-pixel top and bottom
  borders.
- `RegionTime` has one active text child and no icon or separator child. `Map`
  and `Gold` use a left icon at x=40 in a `55x55` RectTransform and a right
  text region centered at x=171 in a `150x80` RectTransform.
- This supports a presentation-only replacement of inferred panel styling. It
  does not support changing coordinate calculation, LAN role text, local time,
  currency state, or refresh cadence.

## Fixed Hotbar Frame Evidence

- Decoded `InventoryView/InventorySlotUI Slot1/BG` GameObject `20660` and its
  active Unity UI Image component `118143`. The sprite pointer resolves to
  `sharedassets1.assets:6918` (`Button1_0`), not `Panel_Stats`.
- Sprite `6918` is `48x48` with verified 20-pixel borders on all sides. Direct
  UnityPy decoding and the supplied exported PNG are pixel-identical.
- Each of the eight active `Main/ItemUI_Inventory` child Images separately
  resolves to `sharedassets1.assets:5844` (`Panel_Stats`). The current slot
  texture therefore remains correct; only the outer hotbar frame requires
  replacement.
