# Asset Replacement Plan

- Stage: BRAINSTORM · 2026-11-07
- Inputs: [ASSET_INVENTORY.md](../reports/ASSET_INVENTORY.md),
  [ASSET_LICENSE_AUDIT.md](../reports/ASSET_LICENSE_AUDIT.md)
- Rule: replace first, verify in game, then retire the excluded asset in an approved PR. Nothing
  is deleted in BRAINSTORM or PLAN.

## 1. Asset priority (from the directive)

1. Original Emberfield assets (`PixelArt` ASCII sprites, anything newly authored)
2. Verified-licence assets with documented commercial-use rights
3. New original pixel art
4. Properly licensed third-party packs (licence text checked in)

## 2. Production routes

| Route | Good for | Limits | Who |
| --- | --- | --- | --- |
| **A. `PixelArt` ASCII** (existing) | 8–32 px monsters, pets, mounts, icons, HUD glyphs, props; prototype frames | Low animation fidelity; slow for large sheets | Claude can author in code |
| **B. Procedural PNG generation** (tool script, palette-locked) | Tile variations, icon recolours per rarity/tier, rune and material icons | Needs a hand-made base | Claude, scripted |
| **C. Verified third-party packs** | Tilesets, hero base bodies, UI frames, SFX, music | Licence verification; style matching | Owner purchases/selects; Claude verifies licence text and records it |
| **D. Commissioned / owner-made art** | Heroes, bosses, key art, logo | Cost/time | Owner |

Honest constraint: routes A/B can deliver a consistent, original, shippable *low-fi* style for
most of the roster. Polished heroes and bosses, plus tilesets for 6 biomes, realistically need
route C or D. The plan doesn't depend on any one route: every runtime reference goes through an
**asset ID**, so a sprite can be upgraded later without code changes.

## 3. Replacement map — excluded runtime assets

| Excluded asset (`assets/treasure_hunter/…`) | Used by | Replacement | Route |
| --- | --- | --- | --- |
| `monsters/mosqui*.png` | `GameContent` `slime`, `MonsterVisualCatalog` | Gnatling: existing `mosquito` ASCII sprite, redesigned silhouette + 4-frame flap | A |
| `monsters/snailu*.png` | `shroom`, `snailu` | Bramble Snail: existing `snail` ASCII, new shell pattern + 4-frame crawl | A |
| `monsters/astromophy.png` | `boar` | Bristle Boar: existing `boar` ASCII + charge frames | A |
| `monsters/turtle_atlas.png`, `turtle_icon.png` | `turtle` | Mossback Tortoise: new ASCII sprite + shell-up frames | A |
| `field/tree_cluster, tree_medium, bush, stump` | `world_props.gd` | TX Plant sheet (if verified) or new ASCII trees/bush/stump (`field_stump` exists) | A / C |
| `npcs/donx/*` | quest/HUD portrait | Warden Captain portrait (original) | A / D |
| `items/weapons/card_28..30` | reference equipment | Retired with `th_weapon_*` (SAVE_MIGRATION) | — |
| `items/ingredients/card_64/66/69` | metadata only | Material icons via route B | B |
| `items/potions/card_900..905` | metadata only | Elixir icons via route B | B |
| `ui/reference/*` (57 files) | `mobile_hud.gd`, `game_menu.gd`, `startup_gate.gd`, `action_button.gd`, `virtual_joystick.gd`, `equipment_detail_panel.gd` | **Original Ember UI kit**: 9-slice panel, buttons (4 states), joystick base/knob, hotbar frame, slot frames ×6 rarity, icons (attack, craft, back, close, menu, chat, map…) | A + B (or C for frames) |

Additionally retired (non-runtime): `docs/original-captures/`, `docs/research/treasure-hunter-survival/`,
`docs/treasure_hunter_xapk_analysis.md`, `tools/treasure_hunter_device.sh`, reference sections of
`docs/architecture/asset-manifest.json` and `game-art-bible.md`, `.agents/skills/**` that encode
reference-parity workflows. These are moved out of the repo or deleted only with owner approval
(D3/D8).

## 4. Unverified assets currently in use

| Asset | Plan |
| --- | --- |
| `assets/tilesets/TX *` | Owner confirms source + licence. If verified, keep as the T1 tileset and record it. If not, replace with an original T1 tileset (route B/C) before any public build |
| `assets/soldiers/**` | Keep for development. Replace with original hero sheets (C/D) before release |
| `assets/enemies/skeleton_hammer/**` | Same as above; Bone Grunt/Archer/Colossus visuals |
| `assets/items/item_icons.png` | Verify or replace with a route-B icon set |
| `assets/Shop/**`, `assets/blacksmith/**` | Verify (the `.aseprite` source suggests team-made) |
| `assets/Font/*.ttf` | Add licence text (Pixellari is commonly distributed as free for commercial use — **must be confirmed from the author's licence file**) |
| `icon.svg` (Godot default) | Replace with an Emberfield logo/icon |

## 5. New assets needed (by milestone)

| Milestone | Assets |
| --- | --- |
| P0 | Ember UI kit; 4 T1 monster replacements; Warden Captain portrait; logo/icon |
| P1 | T1 tileset (if TX not verified); breakable tile sprites ×6 biomes (crack stages); day/night light textures; tool icons |
| P2 | Rarity frames ×6; material/ingredient icons (~60, route B); gloves/cloak icons; rune icons ×6 families × 5 tiers |
| P3 | Dodge animation, status FX (burn, poison, bleed, chill, shock, stun), elite aura, hit sparks |
| P4 | Station sprites ×10, crop growth stages ×12, processing icons |
| P5 | T2–T6 tilesets, monster rosters (~22), boss sprites (~8), landmarks, chests, keys, map icons |
| P6 | Building sprites ×25 with level variants, walls, traps, towers, Hollowfolk units |
| P7 | 8 new pets × 3 evolutions; 6 new mounts; skins |
| P8 | NPC portraits, codex illustrations (small) |
| Audio (from P1) | ~12 music tracks, ~120 SFX |

## 6. Provenance registry

Extend `docs/architecture/asset-manifest.json` (currently Agent A-owned; ownership change is part
of decision D1/D4) with required fields for every **production** asset:

```json
"provenance": {
  "status": "original | verified | unverified | excluded",
  "source": "url or 'in-repo: sense/globals/pixel_art.gd'",
  "creator": "...",
  "license": "SPDX id or licence name",
  "license_file": "assets/<pack>/LICENSE.txt",
  "commercial_use": true,
  "modification": true,
  "attribution": "text or null",
  "distribution_restrictions": "text or null"
}
```

Plus `CREDITS.md` at the repo root, generated from the manifest.

### Provenance gate (automated test, P0)
- Fails if any `res://` texture/audio/font loaded by a scene or script lacks a manifest record
  with status `original` or `verified`. During migration, `unverified` is allowed behind a
  `--dev` flag.
- Fails if any runtime file references `res://assets/treasure_hunter/`.

## 7. Style guide (art bible replacement)

A new `docs/design/ART_BIBLE.md` (PLAN stage) will define the 16-px grid, character heights,
outline rules (1 px dark outline, selective), the master palette (~48 colours), biome accent
ramps, animation frame counts and timings, UI 9-slice metrics, and rarity frame shapes.
