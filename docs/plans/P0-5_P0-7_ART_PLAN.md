# PLAN — P0-5 Original UI Kit, P0-6 Normal-Zone Monsters, P0-7 Props and Portrait

- Stage: PLAN · 2026-11-08 · base `feature/p0-provenance-and-fixtures` (PR #134)
- Style rules: [ART_BIBLE.md](../design/ART_BIBLE.md) (approved together with this plan)
- Goal: every runtime reference to `assets/treasure_hunter/**` is replaced by original art behind
  stable asset IDs. Excluded files are **not deleted** here (that is P0-9 🔒).
- Gameplay behaviour, IDs and save format are unchanged. Display names change only for P0-6.

## Inventory of what must be replaced (measured 2026-11-08)

| Consumer | Excluded files used |
| --- | --- |
| `sense/ui/mobile/mobile_hud.gd` | 22 UI images (panels, portrait frame, hotbar frame, 11 icons, quest suggestion frame, guide portrait) |
| `sense/ui/mobile/game_menu.gd` | 11 (quest panels, tabs, section label, 3 quest icons, back button, login icon) |
| `sense/ui/mobile/startup_gate.gd` | 10 (login panel/tabs/line, buttons, logo, two backgrounds, age notice) |
| `sense/ui/inventory/equipment_detail_panel.gd` | 5 (button, 4 stat icons) |
| `sense/ui/mobile/virtual_joystick.gd` | 2 (ring, handle) |
| `sense/ui/mobile/action_button.gd` | 1 (panel) |
| `sense/globals/game_content.gd` | 3 monster textures (`slime`, `shroom`, `boar` display art) |
| `sense/entities/enemies/monster/monster_visual_catalog.gd` | 2 atlases (`snailu`, `turtle`) |
| `sense/maps/field/world_props.gd` | 4 field props (tree cluster, medium tree, bush, stump) |

Not loaded at runtime (metadata only, nothing to replace now): weapon card icons, stone/elixir
icons, Donx portrait.

## Approach

Original art is produced in-repo with two routes from the art bible:

1. **Code-drawn UI** (`StyleBoxFlat`/9-slice textures generated at startup) for panels, buttons,
   frames, tabs, joystick, hotbar. Crisp, resolution-independent, no image files to license.
2. **ASCII sprites** (`PixelArt`, extended) for icons, monsters, props, portrait, logo glyphs.
   Animated monsters get `SpriteFrames` from ASCII frame lists.

A new `ArtCatalog` (asset ID → Texture2D/StyleBox/SpriteFrames, cached) is the only way UI and
gameplay code get original art. Each ID gets an `original` manifest record.

---

## P0-5 — Ember UI kit

### Files
| File | Change |
| --- | --- |
| `sense/art/ui_kit.gd` (new) | Builds StyleBoxes and 9-slice textures from the art bible palette: `ui.panel.default`, `ui.panel.dark`, `ui.button.primary/secondary/disabled` (+ pressed), `ui.tab.active/inactive`, `ui.frame.portrait`, `ui.frame.hotbar`, `ui.frame.slot.<rarity>`, `ui.joystick.ring/handle` |
| `sense/art/ui_icons.gd` (new) | 16×16 ASCII icons: attack, skill, pet, weapon, map, gold, health, damage, speed, power, back, close, menu, minimize, login, quest main/daily/achievement, dig, craft, chat |
| `sense/art/art_catalog.gd` (new) | Asset-ID lookup and cache for the two modules above and PixelArt |
| `sense/ui/mobile/ui_theme.gd` | Theme built from `ui_kit` |
| `mobile_hud.gd`, `game_menu.gd`, `startup_gate.gd`, `equipment_detail_panel.gd`, `virtual_joystick.gd`, `action_button.gd` | Replace each `preload("res://assets/treasure_hunter/...")` with an `ArtCatalog` ID; review layout so it follows the art bible's HUD rules rather than the captured reference arrangement |
| `startup_gate.gd` | Original title screen: "CINDERWILD" logo from pixel glyphs on a generated ember-and-ash backdrop; remove the copied age/notice image (replace with plain text if a notice is needed) |
| `docs/architecture/asset-manifest.json` | `original` records for every new ID |
| `tests/render_*.gd` | Update existing HUD/menu/startup/equipment renders; outputs reviewed by eye |

### Steps
1. `ui_kit.gd` + `art_catalog.gd` + unit test (every declared ID builds a non-null resource).
2. Icons (ASCII), reviewed in a contact-sheet render (`tests/RenderArtSheet.tscn`, new).
3. Swap consumers file by file, smallest first (joystick → action button → equipment detail →
   game menu → startup gate → mobile HUD). Render after each.
4. Static gate: no `treasure_hunter/ui` reference left.

### Acceptance
- No runtime reference to `assets/treasure_hunter/ui/**` (static + runtime gates).
- Render screenshots of HUD, game menu, startup gate, equipment detail at 360×800: no clipping,
  touch targets ≥ 44 px, text readable; reviewed and attached to the report.
- All existing suites pass.

---

## P0-6 — Normal-zone monster replacements

| ID (unchanged) | New display name | Art | Animation |
| --- | --- | --- | --- |
| `slime` (was "Mosqui") | Gnatling | 16×16 ASCII, new silhouette | idle 2, move 2 (wing flap), attack 3, death 3 |
| `shroom` (was "Snailu") | Bramble Snail | 16×16 ASCII, thorny shell | idle 2, move 4, attack 3, death 3 |
| `boar` (was "Astromophy") | Bristle Boar | 24×24 ASCII | idle 2, move 4, charge windup 2, death 3 |
| `turtle` (reference row, kept until v6) | shown as **Mossback Tortoise** art | 24×24 ASCII, mossy shell | idle 2, shell-up 2, attack 3, death 3 |
| `snailu` (reference row, kept until v6) | uses the Bramble Snail art | — | — |

### Files
`sense/art/monster_sprites.gd` (new ASCII frames), `monster_visual_catalog.gd` (new
`visual: "pixel_frames"` kind building SpriteFrames from ASCII; atlas entries point to new IDs),
`game_content.gd` (display names, drop `texture` paths), manifest records, `tests/RenderMonsters.tscn`
(replaces the per-monster Snailu/Turtle renders).

Combat timings (`attack_duration`, hit time, death duration) stay as they are, so gameplay doesn't
change. The `reference_melee` profile name changes to `timed_melee` in P0-8 along with IDs.

### Acceptance
Gate shows no `treasure_hunter/monsters` reference; monster render sheet reviewed; survival suite
(spawn, kill, loot, quests) passes.

---

## P0-7 — Field props and NPC portrait

| Replace | With |
| --- | --- |
| `field/tree_cluster.png`, `tree_medium.png` | ASCII oak (32×48) and pine (24×40), 2 variants each |
| `field/bush.png`, `stump.png` | ASCII bush 16×16 (2 variants), existing `field_stump` |
| HUD guide portrait (`quest_guide_winbee.png`) | **Warden Captain** 32×32 ASCII portrait (new NPC from the design) |

Files: `sense/art/prop_sprites.gd`, `world_props.gd`, `mobile_hud.gd`, manifest, field render test.

Acceptance: gate shows no `treasure_hunter/field` reference; field render reviewed; collision
shapes unchanged (props keep their footprint).

---

## Order, branches and effort

| Order | Task | Branch | Size |
| --- | --- | --- | --- |
| 1 | P0-5 steps 1–2 (kit + icons) | `feature/p0-5-ui-kit` | M |
| 2 | P0-5 step 3–4 (consumers) | same | L |
| 3 | P0-6 | `feature/p0-6-normal-monsters` | M |
| 4 | P0-7 | `feature/p0-7-props-portrait` | S |

After all three, the static gate reports **0 excluded references**. P0-9 can then retire the files.

## Risks

| Risk | Mitigation |
| --- | --- |
| ASCII art quality reads as "placeholder" | Art bible rules, contact-sheet reviews, owner sign-off per batch; IDs allow swapping in PNGs later |
| HUD regressions on small screens | Render tests at 360×800 after each consumer swap |
| Startup gate depends on reference layout logic | Rebuild the gate's visuals only; keep its offline/LAN logic untouched |
| Font licences still unverified | Out of scope; tracked in ASSET_REPLACEMENT_PLAN §4 |

## Approval requested
1. The art bible (palette, scale, UI rules).
2. This plan, including the code-drawn UI + ASCII sprite approach.
