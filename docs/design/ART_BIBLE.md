# Cinderwild Art Bible

- Stage: PLAN (draft for owner approval) · 2026-11-08
- Scope: every original sprite, tile, icon and UI element. Replaces the retired reference-parity
  art bible in `docs/architecture/game-art-bible.md`.
- Rule: original work only. Reference-game assets may inform general scale and readability, never
  shapes, silhouettes, layouts or palettes (AGENTS.md).

## 1. Identity

**Warm embers against cold grey ash.** Cinderwild's world is a green frontier ringed by grey ash
and white frost. The UI and highlights carry the "ember" (orange-gold), so the player's things
always feel warm against a hostile world.

| Pillar | In practice |
| --- | --- |
| Readable at phone size | Strong 1 px dark outlines on actors; 2-tone shading max on small sprites |
| Warm vs cold | Player, UI, loot = warm accents; Ash and Snow zones = desaturated or cold ramps |
| Chunky, not noisy | No dithering on sprites < 32 px; flat clusters of 2+ pixels |
| One light source | Top-left light; shadows fall bottom-right |

## 2. Grid, scale and camera

| Item | Value |
| --- | --- |
| Tile | 16×16 px |
| Viewport / camera | 720×1600 logical, camera zoom 2 (existing) → 1 art pixel = 2 screen pixels at 360×800 |
| Player/hero | 16×24 body in a 24×24 cell, feet on the bottom row |
| Small monster | 16×16 (Gnatling, Bramble Snail, Puffcap) |
| Medium monster | 24×24 (Bristle Boar, Mossback Tortoise, Briar Wolf) |
| Large / elite | 32×32 |
| Boss | 48×48 to 64×64 |
| Pets | 12×12 to 16×16 |
| Mount (with rider offset) | 24×24 to 32×24 |
| Item icon | 16×16 art, shown at 2× or 3× in slots |
| UI glyph | 8×8 or 12×12 |
| Props | trees 32×48, bush 16×16, stump 16×16, rocks 16×16 |

Filtering: nearest. Scaling: integers only. Sprite origins: bottom-centre for actors and props
(y-sort friendly), centre for icons and FX.

## 3. Master palette (30 colours)

Every asset uses only these colours (the PixelArt palettes reference them by name). Hex values
are original to Cinderwild.

| Ramp | Colours (dark → light) |
| --- | --- |
| Ink | `#14101a` `#2a2433` `#4a4256` |
| Stone/ash grey | `#6b6470` `#8f8994` `#b7b2ba` |
| Snow | `#d9e3ec` `#f4f7fb` |
| Frost blue | `#2c4a6e` `#4f7fae` `#8fbde0` |
| Meadow green | `#1f3d2b` `#356b3c` `#5ea04f` `#a3d16b` |
| Earth brown | `#3b2618` `#6a4426` `#9b6a3c` `#c99b62` |
| Ember (signature) | `#5c1f17` `#a3361f` `#e0612a` `#f59e3b` `#ffd36b` |
| Ash-ember (zone accent) | `#3a2a2a` `#7a4a3a` |
| Poison/arcane | `#4b2a6e` `#8a5ac8` |
| Life red | `#b8263b` |
| Gold | `#ffe9a8` |

Zone mood ramps:
- **Normal**: meadow green + earth brown, ember highlights.
- **Ash**: stone grey + ash-ember + ink, ember glow from vents.
- **Snow**: snow + frost blue + stone grey, almost no green.

Rarity colours (frame shape differs too, for colour-blind players):

| Rarity | Colour | Frame |
| --- | --- | --- |
| Common | `#b7b2ba` | plain 1 px |
| Uncommon | `#5ea04f` | notched corners |
| Rare | `#4f7fae` | double line |
| Epic | `#8a5ac8` | studded corners |
| Legendary | `#f59e3b` | flame tips |
| Mythic | `#e0612a` + `#ffd36b` | animated 2-frame flicker |

## 4. Outlines and shading

- Actors and items: 1 px outline in `#14101a`. Selective outline (lighter ramp colour) only on
  the lit top-left edge for sprites ≥ 32 px.
- Tiles and terrain: no outline. Separate with value contrast.
- Shading: base + one shadow + one highlight on 16 px sprites. ≥ 32 px may add a second shadow.
- No pure black or pure white except `#14101a` / `#f4f7fb`.

## 5. Animation standards

| Action | Frames | Timing |
| --- | --- | --- |
| Idle | 2–4 | 0.20–0.30 s/frame |
| Walk/move | 4 | 0.12 s/frame |
| Attack | 3–5 (windup, strike, recover) | windup ≥ 0.4 s total (combat telegraph rule) |
| Hurt | 1–2 | 0.10 s, white flash via shader |
| Death | 3–4 | 0.12 s/frame, then fade |
| Gather / interact | 3 | 0.12 s/frame |

Directions: monsters may use 1 direction + horizontal flip; the player uses 4 directions (8 later).

## 6. UI kit rules

- Panels: 9-slice, 1 px ink outline, 1 px inner bevel (`#4a4256` top, `#14101a` bottom), body
  `#2a2433` at 94% opacity.
- Primary button: ember (`#e0612a` body, `#ffd36b` top highlight, `#5c1f17` bottom edge).
  Secondary: frost (`#4f7fae`). Disabled: stone grey.
- States: normal, pressed (1 px down, darker), disabled (desaturated), focus (1 px gold ring).
- Text: pixel font at integer sizes (8/16/24 logical), ink shadow 1 px down.
- HUD layout: designed fresh for Cinderwild (portrait card top-left, minimap top-right,
  joystick bottom-left, action cluster bottom-right). Layout proportions are chosen for thumb
  reach and are reviewed so they don't mirror any specific reference screen.

## 7. Production pipeline

1. Author small sprites as ASCII rows + named palette in `sense/globals/pixel_art.gd` (existing
   system) or `sense/art/*.gd` modules. Larger sheets (≥ 32 px, many frames) may be PNGs drawn by
   the owner/artist or produced by `tools/art/` scripts, then recorded in the manifest.
2. Register each asset under a stable asset ID (manifest + catalog).
3. Render test → screenshot → review against this bible → fix.
4. Provenance record `original`, creator, date.

## 8. Fonts

`Pixellari.ttf` and `pixel.ttf` are `unverified`. Until licences are confirmed, they stay for
development. A verified pixel font (or an original bitmap font built from ASCII glyphs) is needed
before any public build.
