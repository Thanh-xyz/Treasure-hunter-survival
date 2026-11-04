# Asset-Grounded Field Visual Pass

## Overview
- **Target files:** `sense/maps/field/world_props.gd`, `sense/maps/field/field_map.gd`, `sense/entities/enemies/monster/monster.gd`, `sense/entities/player/player.gd`, `sense/globals/game_content.gd`, `sense/globals/pixel_art.gd`
- **Reference captures:** `docs/original-captures/original-combat-find-astromophy.png`, `docs/original-captures/original-field-search-west.png`, `docs/original-captures/original-next-gameplay.png`
- **Static-analysis source:** `/home/thanh/Documents/1.Projects/assets-ths`
- **State:** green field exploration with player, Mosqui, Snailu and Astromophy visible near large vegetation props.

## Visual Measurements
- Source viewport is `720x1600`; the clone's logical viewport is `360x800`, so source-screen measurements are rendered at roughly `0.5x` in the clone.
- Dominant field ground is `#3c784a` with sparse low-contrast marks.
- Extracted source sprite dimensions: Mosqui `31x33`, Snailu `25x22`, Astromophy `38x35`.
- Large captured field tree occupies about `240x300` source pixels, or `120x150` clone pixels.
- Standalone field bush occupies about `80x90` source pixels, or `40x45` clone pixels.
- Source props use a near-black one-pixel outline, compact green highlight clusters and a dark green oval contact shadow.

## Layout
- Preserve all fixed HUD anchors and gameplay interactions already implemented.
- The field remains mostly uninterrupted grass; trees and bushes are large isolated landmarks rather than a dense noisy forest tile set.
- Large tree bases are valid collision anchors. Their canopies may overlap actors through existing Y sorting.
- Small bushes and stumps remain non-blocking decoration.

## Components

### Ground
- Flat base `#3c784a`.
- At most a few isolated one-pixel darker/lighter marks in each `16x16` tile.
- No visible checkerboard or high-frequency texture.

### Field tree cluster
- Source-capture-derived local reference asset supplied by the user, color-keyed against the known ground color.
- Display around `0.5x`, nearest-neighbor filtering.
- Includes its original dark oval contact shadow and optional adjacent bush where present.
- Collision remains a small footprint at the trunk only.

### Bush
- Source-capture-derived local reference asset supplied by the user, color-keyed against the known ground color.
- Display around `0.5x`, nearest-neighbor filtering.
- Used sparingly as standalone field decoration.

### Stump
- Source-capture-derived local reference asset with a taller broken rim, dark bark outline and compact footprint.

### Monsters
- Use the three user-supplied extracted sprites for Mosqui, Snailu and Astromophy.
- Load them as curated local assets rather than importing the full 1.7 GB extraction.
- Use nearest-neighbor filtering and per-monster scale values that account for the source `720x1600` capture versus the clone `360x800` logical viewport.
- Preserve the existing red HP strip and cream outlined name label.
- Use the extracted source-facing orientation; horizontal motion may flip the sprite.

### Player
- Keep the existing clean-room guest animation because the static extraction does not provide a complete verified directional frame set.
- Add a small dark-green oval contact shadow behind the avatar.
- Preserve current nameplate and HP plate behavior.

## Interactions
| Element | Affordance | Mechanism | Scope |
| --- | --- | --- | --- |
| Tree/resource node | collision or gather target | existing `StaticBody2D` / `ResourceNode` behavior | on-device |
| Bush/stump | visual landmark | no interaction | on-device |
| Monster sprite | movement/target/combat feedback | existing monster AI and hit logic | on-device/LAN |
| Player sprite | movement/attack/dig feedback | existing animation state machine | on-device/LAN |

## States & Deltas

### Quiet field
- Source-like tree clusters and bushes replace the Emberfield `TX Plant` atlas art.
- Ground stays visually flat and readable.

### Nearby monster
- Mosqui, Snailu or Astromophy use the extracted source silhouette and palette.
- Shadow, name and HP strip remain visually attached during movement and squash animation.

### Mounted or attacking player
- Player contact shadow remains below the avatar/mount and does not cover combat effects.

## Assets
- `assets/treasure_hunter/field/tree_cluster.png`: derived from the user's original runtime capture for local parity.
- `assets/treasure_hunter/field/tree_medium.png`: derived from the user's original runtime capture for local parity.
- `assets/treasure_hunter/field/bush.png`: derived from the user's original runtime capture for local parity.
- `assets/treasure_hunter/field/stump.png`: derived from the user's original runtime capture for local parity.
- `assets/treasure_hunter/monsters/mosqui.png`: curated from the user's XAPK extraction.
- `assets/treasure_hunter/monsters/snailu.png`: curated from the user's XAPK extraction.
- `assets/treasure_hunter/monsters/astromophy.png`: curated from the user's XAPK extraction.
- All textures use nearest-neighbor sampling. The full extraction is never copied into the project.

## Verification
- Render `tests/RenderFieldEnvironment.tscn` before and after the pass.
- Compare against the three reference captures at the `360x800` logical presentation scale.
- Run `tests/SurvivalTests.tscn`, `tests/LegacySystemTests.tscn`, main-scene boot and `git diff --check`.
- If monster scripts change, also run the LAN combat/player harnesses.

## Distribution Note
- The curated source-derived assets are appropriate for the user's requested local/private replica. Before public distribution, replace them with licensed or independently recreated equivalents unless the user holds redistribution rights.
