# SCOUT Report — Original 2D Pixel Survival RPG

- Stage: **SCOUT (read-only)** — complete; waiting for owner approval before BRAINSTORM
- Date: 2026-11-07
- Branch: `feat/survival-rpg` @ `5a54668` (clean working tree at start)
- Scope of changes: this report plus four companion reports in `docs/reports/`. No gameplay
  source, scene, asset, configuration, Git history, or coordination file was modified.

Companion reports:

| Report | Content |
| --- | --- |
| [EXISTING_SYSTEMS.md](EXISTING_SYSTEMS.md) | System-by-system implementation status |
| [ASSET_INVENTORY.md](ASSET_INVENTORY.md) | What art/audio/fonts exist, where, and in what form |
| [ASSET_LICENSE_AUDIT.md](ASSET_LICENSE_AUDIT.md) | Provenance and licensing status for every asset group |
| [TECHNICAL_RISKS.md](TECHNICAL_RISKS.md) | Risk register with mitigations |

---

## 0. The headline finding — the project's current direction conflicts with the new brief

The new master brief asks for an **original** game that is only *inspired by* Treasure Hunter –
Survival, and forbids reusing assets extracted from the reference game's APK/XAPK.

The repository as it stands today is explicitly run the other way:

| Evidence | What it says |
| --- | --- |
| `AGENTS.md` (title, "Visual Fidelity") | "Treasure Hunter **Recreation** Agent Rules"; "runtime captures are the visual source of truth"; "do not redesign" |
| `../treasure-hunter/shared/coordination/decisions.md` | "The project targets the **closest evidence-backed recreation**, not a redesign." |
| `docs/architecture/asset-manifest.json` | Project name "Treasure Hunter – Survival local recreation in Emberfield" |
| `assets-ths/` | 100% derived from decompiling `com.megacombat.treasurehunter_4.3.6.xapk` (see §5) |
| `assets/treasure_hunter/` (82 PNG) | Sprites/UI pulled from that extraction, marked `local_only` |
| `sense/globals/game_content.gd`, `sense/items/reference_*.gd`, `reward_box_catalog.gd` | Quest IDs/text (q305–q311), Box/Card IDs and stat ranges copied from the extracted `Quest.json`, `Box.json`, `Card.json` |
| `docs/original-captures/` (114 files, 34 MB) | Screenshots and video of the reference game |
| `tools/treasure_hunter_device.sh` | ADB tooling to drive the reference app on a phone |

Roughly 230 of the 329 commits (Nov 3–6, 2026) were spent on this pixel-parity recreation by two
agents (A = art, B = logic), both currently paused.

**These two directions cannot both be followed.** Continuing the recreation would violate §2, §5
and §6 of the new brief. Switching to the original-game direction requires the owner to supersede
`AGENTS.md` and the shared "Visual Fidelity" decision. Under the current rules `AGENTS.md` is
Agent A–owned, so I have **not** changed it. This is decision **D1** in §11 and blocks everything
after SCOUT.

The good news: the original Emberfield foundation (Feb–Mar 2026) and most of the November gameplay
*architecture* are independent of the reference game and can be kept. The reference-derived layer
is thin and well isolated (see §4 and EXISTING_SYSTEMS.md §3).

---

## 1. What engine and technology does Emberfield use?

| Item | Value |
| --- | --- |
| Engine | **Godot 4.6** (`config/features = "4.6", "GL Compatibility"`) |
| Language | GDScript only (~23.5k lines across `sense/`); no C#, no GDExtension, no addons |
| Renderer | GL Compatibility; nearest-neighbour pixel art |
| Display | Portrait mobile: 720×1600 logical viewport, 360×800 desktop test window, `canvas_items` stretch |
| Input | Keyboard actions + touch (virtual joystick, multi-touch action buttons, mouse→touch emulation) |
| Persistence | JSON save in `user://saves`, `SAVE_VERSION = 5`, atomic write + `.bak`, migration hook |
| Networking | Godot ENet, UDP 24567, host-authoritative LAN, `PROTOCOL_VERSION = 5`, max 3 clients |
| Tests | Custom headless GDScript suites in `tests/` (no GUT/GdUnit dependency) |
| CI | `.github/workflows/pr-build-windows.yml`: headless import + Windows export on PRs to `main` |
| Remotes | `origin` = `Thanh-xyz/Treasure-hunter-survival` (**private**), `upstream` = `HauTranCong/emberfield` (public, no license file) |
| Autoloads (14) | CollisionLayers, InteractionManager, GameEvent, ItemDatabase, SceneTransitionService, CameraService, RecipeDatabase, SkillDatabase, NotificationManager, ConfirmDialog, GameState, QuestService, SaveService, LanSession |

## 2. What has already been implemented?

Far more than an empty project. Summary (details and file references in EXISTING_SYSTEMS.md):

- **Player**: 8-direction movement, state machine, basic attack, equipment skills (Q/E/R/F), hero
  skills (3 heroes × 3 skills), potions, mount toggle, death/respawn, i-frames, knockback.
- **Combat**: component-based Hitbox/Hurtbox with line-of-sight, crits, life steal, passive
  on-hit effects (burn/freeze/poison/thorns), projectiles, AoE telegraphs, damage numbers.
- **Enemies**: data-driven `Monster` (melee / flyer / ranged / charger / stationary, elites),
  skeleton AI (patrol/chase/attack), 2-phase `Boss` (slam, leap, nova, summon), world-boss altar.
- **Items & inventory**: 11 item types, 5 rarities, ~40+ items, 32 slots, 7 equipment slots,
  stacking, sort, swap, equip/unequip, atomic multi-item transactions, sell, augments.
- **Equipment progression**: upgrade levels with cost curve, augment sockets (stat / passive /
  active skill / timed buff).
- **Crafting**: recipe resources with 1–3 tiers, category tabs, crafting station UI.
- **World**: Town hub, procedural dungeon (Isaac-style rooms), two seeded field maps (Greenwood
  Meadow, Frostvale Ruins), Homestead, portals with fade transitions, minimap.
- **Gathering**: tree/rock `ResourceNode` with respawn, `DigSpot` stand-to-dig treasure plots,
  loot magnet.
- **Village**: Homestead with 6 build plots; Lumber Mill / Quarry / Herb Garden produce over real
  time (including offline); Training Hall / Watchtower / Stable give permanent bonuses.
- **Pets & mounts**: 4 pets (follow, attack, heal, evolve at Lv5/Lv10), 4 mounts with
  speed/attack/defense categories and skins.
- **Quests**: main chain + 3 dailies driven by domain events, durable claim journal.
- **Save/Load**: versioned JSON, atomic write, backup, autosave every 60 s / on zone change / on
  pause, validation and migration.
- **LAN co-op foundation**: handshake, transforms, host-owned monster spawn/HP/death, host-validated
  hit requests, loot reservation with capacity ACK, host-confirmed potions, disconnect replay.
- **Original art pipeline**: `PixelArt` turns ASCII sprites + palettes into textures at runtime
  (25 original sprites: slimes, bat, boar, pets, mounts, HUD glyphs).

## 3. What features are incomplete?

| Area | Gap |
| --- | --- |
| Biomes | Only 2 field zones + dungeon; no forest/cave/mountain/ruins-as-biome data model; resource and spawn tables are per-zone code, not reusable biome definitions |
| Gathering | No tool requirements, gather-speed modifiers, rarity tiers, or farming/crops |
| Items | No Mythic rarity, no gloves slot, no weight, no item comparison UI, no stack *split* |
| Stats | No accuracy, dodge, attack-speed, crit-damage as first-class stats |
| Crafting | No crafting duration, success chance, station requirement per recipe, or unlock gating |
| Combat | No dodge roll; status effects are processor-level hacks (`passive_effect_processor.gd:117` TODO) |
| Building | Fixed 6-plot layout, not free grid placement; no walls/towers/traps |
| Treasure | Dig spots and chests exist; no treasure maps, keys, or the "key reveals carrier" risk mechanic |
| Day/night | Not present |
| Audio | **No audio assets and no audio system at all** |
| Hero visuals | Heroes are the recoloured legacy soldier sheet |
| LAN | Equipment/crafting/chests/gathering/dig/buffs/per-peer quests/pets/mounts/world save not synchronised |
| Online | Not started (correct for now) |

## 4. What architecture should be preserved?

Keep (all independent of the reference game):

1. **Autoload service layer** — `GameEvent` signal bus, `GameState`, `SaveService`, `QuestService`,
   `ItemDatabase`, `RecipeDatabase`, `SkillDatabase`, `SceneTransitionService`, `CameraService`.
2. **Component composition** — Health/Hitbox/Hurtbox/Buff/PassiveEffect/Skill components and the
   `CollisionLayers` standard (`docs/LAYER_AND_MASK_STANDARDS.md`).
3. **Data-driven content** — `GameContent` dictionaries for heroes, skills, pets, mounts, monsters,
   zones, buildings, quests, XP curve. Extend into biome/resource/loot tables rather than replace.
4. **Atomic inventory transactions** (`InventoryData.transact`) — the right primitive for crafting,
   trading and multiplayer.
5. **Versioned atomic saves with migration** (`SaveService._migrate`).
6. **Host-authoritative LAN boundary** — clients send intents, host validates; plus the approved
   layering in `docs/reports/gameplay-architecture.md` (presentation → commands → pure rules →
   persistence/authority adapters). This is exactly what the brief's §4.4–4.5 asks for.
7. **`PixelArt` ASCII generator** — an original-art pipeline already in the codebase.
8. **Stable-ID discipline** — content keyed by stable string IDs; asset references by asset ID via
   catalogs (`MonsterVisualCatalog`) instead of hard paths.

Replace or retire (reference-derived): `assets/treasure_hunter/**`, `reference_equipment_*.gd`,
`reward_box_catalog.gd` source IDs, q305–q311 quest rows, the Treasure-Hunter-matched mobile HUD
chrome and startup gate visuals, `docs/original-captures/`, `tools/treasure_hunter_device.sh`.
These must not be deleted without approval (D3); the plan should *replace then retire*.

## 5. What assets are available?

**In `assets-ths` (1.7 GB):** two copies of the reference XAPK, apktool-decoded APK (22,648 smali
files, `libil2cpp.so`, `global-metadata.dat`), 4,687 Unity Addressables bundles, 23,505 PNGs exported
with UnityPy (5,086 textures + 18,419 atlas-cut sprites), 332 Android raster images, 24 extracted
gameplay JSON configs (Item, Card, Box, Quest, Arena…), and analysis reports including the app's
Pairip / Play Integrity protection layer. Documentation (`README_VI.md`) states plainly that it is a
decompilation of Treasure Hunter Survival 4.3.6.

**In the repository (`assets/`, 135 PNG + 2 TTF):**

| Group | Origin | Contents |
| --- | --- | --- |
| `tilesets/` (8 sheets) | Feb 2026 Emberfield, third-party pack | grass, stone ground, walls, plants, props, structures, shadows (Cainos-style "TX" naming) |
| `soldiers/` (12 strips) | Feb 2026, third-party | 4-direction idle/run/attack, 96×80 frames |
| `enemies/skeleton_hammer/` (25) | Feb 2026, third-party | 8-direction idle/walk/attack + death, 128×128 frames |
| `items/item_icons.png` | Feb 2026, third-party | 512×867 sheet of 32×32 icons |
| `Shop/`, `blacksmith/` | Feb 2026, third-party | merchant, cart, shop UI, forge objects, fire animation |
| `Font/` | third-party | `Pixellari.ttf`, `pixel.ttf` |
| `treasure_hunter/` (82) | **Extracted from reference XAPK / captures** | 4 field props, 4 monsters + atlases, 2 NPC portraits, 12 item icons, 57 UI pieces |
| Runtime ASCII sprites (25) | **Original**, in `pixel_art.gd` | slimes, bat, boar, mushroom, pets, mounts, altar, HUD glyphs |

No audio exists anywhere (repo or library).

## 6. Which assets are suitable for the game?

| Asset group | Suitable? |
| --- | --- |
| `assets-ths/**` | **No.** Every file is derived from the reference game's XAPK. The brief forbids reusing these. Not even suitable as a gameplay *design* source beyond what is publicly documented. |
| `assets/treasure_hunter/**` | **No** for the original game — replace and retire. |
| `docs/original-captures/**` | **No** as assets. Keep private at most, never ship. |
| Feb-era third-party packs | **Yes for local development, UNVERIFIED for release** — need license files before any public build. |
| Pixellari / pixel fonts | Likely usable; **UNVERIFIED** until license text is added. |
| `PixelArt` ASCII sprites | **Yes** — original, owned by the project. Best foundation for monsters/pets/mounts/UI glyphs. |

The owner's statement that `assets-ths` is "authorized" cannot cover redistribution: the files are
a third party's proprietary content obtained by unpacking their app, and the brief itself (§2) says
never to reuse assets extracted from the reference APK/XAPK. I've treated that rule as overriding the
general "authorized library" statement. See ASSET_LICENSE_AUDIT.md.

## 7. What licensing information is available?

- `assets-ths`: no license; only extraction READMEs. Status: **PROPRIETARY — EXCLUDED**.
- Repository: no `LICENSE`, `CREDITS`, or attribution file for any pack. The asset manifest records
  every Feb-era asset as provenance `unknown` and every extracted asset as `local_only`.
- Upstream `HauTranCong/emberfield` is public with **no license**, so the original code's reuse
  terms are also undocumented (the owner should confirm they have rights to the upstream code).
- Some third-party packs are recognisable by naming (e.g. "TX Tileset …" matches the Cainos
  *Pixel Art Top Down – Basic* naming), but naming is not proof. All are **UNVERIFIED** until the
  owner supplies the purchase/download source and license text.

## 8. What original assets still need to be created?

Everything currently coming from the reference game, plus the gaps:

- **Player/heroes**: distinct sprite sets per hero (idle, walk, run, attack, hurt, death, gather,
  interact, skill) — 4 or 8 directions to match the chosen camera.
- **Monsters**: replacements for Mosqui, Snailu, Astromophy, Turtle; new biome sets (forest, cave,
  mountain, ruins, danger zone); boss sprites with phase variants.
- **NPCs**: replacement for the Donx portrait/icon; village NPC roster.
- **Environment**: per-biome tilesets (forest, cave, mountain, ruins, danger zone), resource nodes
  (ore tiers, herbs, crops, rare plants), chests, keys, treasure-map props, village buildings.
- **Items**: icons for all categories and the new Mythic tier; replacements for the 12 extracted
  icons.
- **UI**: an original HUD/menu kit replacing the 57 extracted UI pieces (buttons, frames, hotbar,
  joystick, panels, rarity frames).
- **VFX**: hit sparks, skill effects, gathering particles, level-up, loot glow.
- **Audio**: all music and SFX (none exist).
- **Branding**: an original title (is "Emberfield" the final name?), logo, icon.

Short-term route: extend the `PixelArt` ASCII pipeline (fast, original, already integrated) and
evaluate licensed third-party packs with clear commercial terms for tiles and character bases.

## 9. What are the biggest technical risks?

Top five (full register in TECHNICAL_RISKS.md):

1. **Direction conflict / IP contamination** (critical): reference-derived data, quest text, IDs,
   assets and captures are woven into content and saves; the private repo history contains them.
2. **Cannot validate locally** (high): Godot 4.6 isn't installed on this machine, so I couldn't run
   any test. Prior agents report CI passing on `5a54668`, but I have not verified that.
3. **God-files** (medium): `player.gd` (1,510 lines), `lan_session.gd` (1,123), `mobile_hud.gd` (984)
   carry many responsibilities; risky to extend for new systems.
4. **Two parallel content models** (medium): legacy `ItemDatabase`/skeleton/augment systems and the
   November `GameContent`/`Monster`/reference catalogs overlap (e.g. items vs "cards", two monster
   paths, Q/E/R/F equipment skills vs Z/X/C hero skills).
5. **Save/LAN migration** (medium): retiring reference IDs (`th_weapon_28`, `q311`, Box 98…) breaks
   saves and LAN snapshots unless handled by a versioned migration.

## 10. What is the best implementation sequence?

| Step | Priority | Work |
| --- | --- | --- |
| 0 | P0 | Owner decisions D1–D6; install Godot 4.6 for local validation; run the existing suites to get a baseline |
| 1 | P0 | **Originality pivot**: new AGENTS.md / decisions, asset provenance policy, quarantine plan for reference content |
| 2 | P0 | Replace reference content behind stable asset IDs: original monsters, icons, UI kit, quests; save migration (v5→v6) mapping retired IDs |
| 3 | P1 | Consolidate player/core loop: unify skill models, tidy `player.gd` responsibilities only as needed |
| 4 | P2 | Biome data model (tileset, resource table, spawn table, loot table, difficulty); gathering framework with tools and speeds |
| 5 | P3 | Inventory gaps: split stacks, filter, Mythic, gloves, comparison UI |
| 6 | P4 | Combat: dodge, status-effect component, enemy retreat state, boss patterns |
| 7 | P5 | Crafting stations, durations, success rates, unlocks; stat expansion |
| 8 | P6 | Grid-based village building, walls/towers/traps |
| 9 | P7 | Treasure maps, keys, "marked carrier" risk mechanic, original quest chain, bosses |
| 10 | P8 | Pet/mount depth, day/night, audio |
| 11 | P9 | LAN completion (equipment, crafting, gathering, chests, world save) |
| 12 | P10 | Online server architecture design only |

This matches the brief's P0–P10 order, with one change: the originality pivot is inserted at P0
because every later feature would otherwise be built on content that has to be torn out.

## 11. Decisions needed from the owner

| ID | Decision | My recommendation |
| --- | --- | --- |
| **D1** | Supersede the "closest recreation / runtime captures are source of truth" rules in `AGENTS.md` and `shared/coordination/decisions.md` with the original-game direction | **Yes** — required by the new brief |
| **D2** | Treat `assets-ths` as excluded from the game (reference only for publicly documented mechanics) | **Yes** |
| **D3** | Retire `assets/treasure_hunter/**`, reference catalogs, q305–q311 content, captures and the ADB tool — replace first, then remove in an approved PR | Replace-then-retire, not immediate delete |
| **D4** | What to do with Agents A/B and the two worktrees (`treasure-hunter/art`, `treasure-hunter/logic`) and their ~30 local feature branches | Stand them down; keep branches untouched as archive |
| **D5** | Provide license/source for the Feb-era packs and fonts, and confirm rights to the upstream `HauTranCong/emberfield` code | Needed before any public release |
| **D6** | Allow installing Godot 4.6 locally (portable binary in scratch, no system changes) for TEST | Yes |
| D7 | Final title — keep "Emberfield"? | Your call; it's original and already in use |
| D8 | Private Git history contains extracted assets; if the repo ever goes public, history must be rewritten or a fresh repo started | Decide before any public release; no action now |

## 12. Stage closeout

- **Findings**: §0–§10 above.
- **Inspected**: `project.godot`, `README.md`, `AGENTS.md`, `docs/**` (index level, plus
  `survival_rpg.md`, `gameplay-architecture.md`, `asset-manifest.json`), all `sense/**` file sizes
  and signatures, key system headers, `tests/`, `tools/`, CI workflow, Git log/branches/worktrees/
  remotes, GitHub repo visibility, all seven shared coordination/status/handoff files,
  `assets-ths` structure, READMEs, manifests and file-type counts.
- **Modified**: created the five `docs/reports/*` SCOUT files only. Nothing committed.
- **Validation evidence**: static inspection only. **No test was executed** — Godot is not
  installed (`which godot` empty; the `/tmp/th-godot-*` binary earlier agents used no longer exists).
- **Risks**: see TECHNICAL_RISKS.md.
- **Unresolved questions**: D1–D8.
- **Proposed next stage**: BRAINSTORM (game design documents), **after** D1–D3 are approved.
