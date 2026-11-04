# Treasure Hunter Game Art Bible

Status: initial evidence-backed specification for the local/private recreation.
Unknown values remain explicitly unknown until verified from runtime capture or
source metadata.

## 1. Fidelity Objective

Reproduce Treasure Hunter - Survival as closely as the available evidence allows.
Do not modernize, reinterpret, recolor, rescale, or add visual mechanics merely to
make the recreation look more polished.

Evidence priority:

1. Direct `720x1600` runtime screenshot or recording.
2. User-supplied extracted asset from Treasure Hunter 4.3.6.
3. Unity object, animation, scene, or static-analysis metadata.
4. Clearly marked inference.

If a screen, state, frame order, pivot, or color is not evidenced, record it as
unknown instead of inventing it.

## 2. Scope And Provenance

The user authorizes supplied Treasure Hunter assets for this local/private build.
Manifest entries for those assets use:

- `provenance.status`: `user_supplied_extracted` or `user_supplied_capture_derived`
- `provenance.distribution_scope`: `local_only`

This authorization is not evidence of public redistribution rights. Existing
Emberfield assets with no recorded origin use `unknown` provenance until verified.

## 3. Camera And Presentation

- Perspective: top-down 2D pixel art.
- Reference capture size: `720x1600`, portrait.
- Current Godot logical viewport: `720x1600`.
- Current desktop test window: `360x800`.
- Rendering: Godot GL Compatibility with nearest-neighbor texture filtering.
- World actors and props use Y sorting where scene behavior requires overlap.

The desktop override is a presentation scale, not a second art coordinate system.
Visual comparisons should render at or normalize to `720x1600`.

## 4. Pixel-Art Standards

- Preserve original source pixels; do not apply smoothing or interpolation.
- Prefer integer positions and integer display scales for UI and fixed art.
- Do not redraw extracted sprites unless a missing state requires reconstruction.
- Preserve transparent margins when they encode pivot or effect space.
- Do not trim a sprite until the pivot and animation sequence are documented.
- Keep contact shadows behind actors and below their feet/ground anchor.
- Keep a near-black one-pixel outline where present in the reference asset.

## 5. Tiles And Environment

- Current field tile baseline: `16x16` pixels.
- Verified Greenwood base color: `#3c784a`.
- Field ground is low-frequency and mostly flat, with sparse darker/lighter marks.
- Reference field trees are large isolated landmarks rather than dense tile noise.
- Tree collisions belong at the trunk footprint; canopies may overlap actors.
- Small bushes and stumps are normally decorative unless gameplay evidence says otherwise.

Extracted environment art may be a complete prop, a cropped sprite, a tile, or a
piece of a larger composition. The manifest must identify which form is verified.

## 6. Actor Scale And Anchors

Actor dimensions vary and must not be forced into one universal frame size.
Verified examples currently integrated:

| Actor | Source dimensions | Current use |
| --- | ---: | --- |
| Mosqui | `31x33` | Static extracted sprite with runtime motion/squash |
| Snailu | `25x22` | Static extracted sprite with runtime motion/squash |
| Astromophy | `38x35` | Static extracted sprite with runtime motion/squash |

For every animated actor, document source frames, frame rectangle, pivot, foot
point, display scale, collision-foot offset, and verified effect/weapon sockets.

## 7. Direction Standard

Manifest-facing canonical directions:

```text
up
up_right
right
down_right
down
down_left
left
up_left
```

| Canonical | Known aliases |
| --- | --- |
| `up_right` | `right_up`, `top_right` |
| `down_right` | `right_down`, `bottom_right` |
| `down_left` | `left_down`, `bottom_left` |
| `up_left` | `left_up`, `top_left` |

Four-direction sprites declare aliases for missing diagonals. Gameplay must not
guess aliases absent from the manifest or an approved fallback contract.

## 8. Animation Standard

Core states:

```text
idle
move
attack
hurt
death
```

Optional states:

```text
skill
dig
gather
cast
charge
mounted_idle
mounted_move
```

- `idle` and `move` normally loop.
- `attack`, `hurt`, and `death` normally do not loop.
- Record actual integrated behavior even when it violates the desired standard.
- FPS, frame count, order, loop flag, hit frame, and transitions require evidence;
  otherwise use `null`.
- Static sprites may use procedural motion, but that is not a recovered source animation.

Current Emberfield player scene exposes eight-direction idle/move names by reusing
four directional source sheets; diagonal left/right states alias the corresponding
horizontal sheet. Attack uses four directional sheets. All run at five FPS before
runtime speed scaling. This describes the present clone, not confirmed Treasure
Hunter source timing.

## 9. UI Visual Language

Verified runtime characteristics:

- Portrait HUD with character/stat blocks near the top corners.
- Vertical action/equipment rails along the left and right edges.
- Eight-slot hotbar across the bottom.
- Dark charcoal or muted purple-gray panels with gray trim.
- Amber/orange active controls and highlights.
- Red HP, green positive/readiness states, cream primary text, and outlined pixel labels.
- Square or lightly rounded controls with compact multi-line borders.
- Dense inventory layout with character preview, equipment rails, currencies,
  stat rows, tabs, and item grid.

Current UI constants in `sense/ui/mobile/ui_theme.gd` are provisional until each
screen is measured against reference captures.

## 10. Color Palette

| Token | Value | Evidence |
| --- | --- | --- |
| `field.greenwood.base` | `#3c784a` | Runtime capture measurement/current field pass |
| `ui.positive` | bright green | Reference HUD; exact value not yet measured |
| `ui.hp` | dark red/red | Reference HUD; exact value not yet measured |
| `ui.active` | amber/orange | Reference controls; exact value not yet measured |
| `ui.panel` | charcoal/purple-gray | Reference menus; exact value not yet measured |

Only exact measured values belong in numeric palette tokens. Descriptive colors
remain non-numeric until sampled and verified.

## 11. Naming Convention

Stable manifest asset IDs use:

```text
<category>.<subject>.<identity>.<variant>
```

Examples:

```text
actor.monster.mosqui.default
actor.monster.snailu.default
environment.field.tree.cluster
ui.inventory.frame.epic
```

Repository filenames use lowercase snake case unless an existing asset must retain
its original name. Animation frame exports should use:

```text
<identity>_<state>_<direction>_<frame>.png
```

Gameplay IDs and asset IDs are separate contracts.

## 12. Folder Structure

```text
assets/treasure_hunter/
  actors/characters/
  actors/monsters/
  actors/pets/
  actors/mounts/
  environment/field/
  environment/town/
  environment/dungeon/
  environment/homestead/
  items/
  ui/
  effects/
  audio/
```

Existing `field` and `monsters` directories remain valid during incremental
migration. Do not move them without auditing references.

## 13. Import And Performance Rules

- Use lossless PNG for pixel sprites and UI unless another format is justified.
- Disable filtering and mipmaps for pixel art.
- Avoid duplicate source/texture copies.
- Do not copy the complete external export into the repository.
- Validate dimensions, alpha, naming collisions, and references before import.
- Prefer atlases only when frame metadata remains auditable.
- Record large textures and expected memory impact before integration.

## 14. Asset Reuse Policy

Allowed for the local/private build:

- User-supplied extracted Treasure Hunter assets.
- User-supplied runtime-capture-derived crops.
- Existing Emberfield assets.
- Clean-room reconstructions based on observed layout and behavior.

Integration states:

```text
source_verified
reference_only
selected
integrated
reconstructed
rejected
unknown
```

Do not relabel extracted assets as MIT or publish them without a separate rights decision.

## 15. Visual Validation

For each screen/state:

1. Name the exact reference screenshot or recording timestamp.
2. Reproduce a deterministic clone state.
3. Capture at `720x1600` or normalize without interpolation.
4. Compare fixed regions separately from dynamic player, time, ping, and network content.
5. Record layout, color, typography, scale, missing elements, and animation deltas.
6. Repeat until known mismatches are resolved.

Numeric diff thresholds will be set only after a stable Godot baseline exists.
