# Emberfield — Game Design Document

- Stage: BRAINSTORM draft for owner approval · 2026-11-07
- Engine: Godot 4.6 / GDScript, portrait mobile first, desktop for development
- Status of every system: see [FEATURE_MATRIX.md](FEATURE_MATRIX.md)

## Document map

| # | Deliverable | File |
| --- | --- | --- |
| 1 | Gameplay feature matrix | [FEATURE_MATRIX.md](FEATURE_MATRIX.md) |
| 2 | Reference gameplay research | [REFERENCE_RESEARCH.md](REFERENCE_RESEARCH.md) |
| 3 | Existing capability assessment | [CAPABILITY_ASSESSMENT.md](CAPABILITY_ASSESSMENT.md) |
| 4 | Game design document | this file |
| 5 | World and content direction | [WORLD_DESIGN.md](WORLD_DESIGN.md) |
| 6 | Equipment and progression | [PROGRESSION_DESIGN.md](PROGRESSION_DESIGN.md) |
| 7 | Economy and crafting | [ECONOMY_CRAFTING.md](ECONOMY_CRAFTING.md) |
| 8 | Combat and monsters | [COMBAT_MONSTERS.md](COMBAT_MONSTERS.md) |
| 9 | Village and building | [VILLAGE_BUILDING.md](VILLAGE_BUILDING.md) |
| 10 | Treasure hunting | [TREASURE_HUNTING.md](TREASURE_HUNTING.md) |
| 11 | Pets and mounts | [PETS_MOUNTS.md](PETS_MOUNTS.md) |
| 12 | Multiplayer architecture | [MULTIPLAYER_ARCHITECTURE.md](MULTIPLAYER_ARCHITECTURE.md) |
| 13 | Asset replacement plan | [ASSET_REPLACEMENT_PLAN.md](ASSET_REPLACEMENT_PLAN.md) |
| 14 | Save migration plan | [SAVE_MIGRATION_PLAN.md](SAVE_MIGRATION_PLAN.md) |
| 15 | Prioritised roadmap | [ROADMAP.md](ROADMAP.md) |

Numbers in these documents (HP, costs, rates) are **starting balance values**. They will live in
data tables and be tuned during TEST. They are not commitments.

---

## 1. Vision

> **Emberfield** is a portrait pixel-art survival RPG. You rekindle a dying frontier by breaking
> open the land for materials, forging gear from what you find, raising a homestead against the
> encroaching Ash, and carrying dangerous treasure keys through hunted country. It plays fully
> offline and with up to four friends on LAN.

### Pillars

1. **Everything feeds something.** Every activity produces an input for another system. No
   dead-end loot.
2. **Carry risk to earn reward.** The best rewards have to be *carried* somewhere while the
   world pushes back: keys, unbanked materials, Ashfall raids.
3. **Build a place worth defending.** The homestead is your bank, factory and fortress, and it
   is attacked.
4. **Fair and earned.** No loot boxes, no premium shortcuts. Time and skill are the only currency
   multipliers.
5. **Better together, complete alone.** All content can be finished solo. LAN adds shared bosses,
   shared homesteads and opt-in PvP.

### Non-goals (first release)

- Online accounts or dedicated servers (architecture only, P10).
- Monetisation of any kind.
- Forced season wipes.
- Narrative cutscenes beyond short NPC dialogue.

---

## 2. Setting and lore (original)

**The Hearthfire** was the great flame that kept the frontier alive. A generation ago it guttered
out in the event the settlers call **the Snuffing**. Since then **the Ash**, a creeping grey blight,
has spread out from the old heartlands. It raises the dead, hardens beasts and buries the
old roads.

Scattered through the land are **Embers**, living fragments of the Hearthfire. Embers fuel forges,
hatch companion eggs, and open the sealed **Ember Vaults** the old wardens left behind.

The player is a **Kindler**, a frontier settler sworn to carry embers home and rekindle the
**Hearthmoor** settlement. Each region pushed back from the Ash makes the next one reachable.

Factions:

| Faction | Role |
| --- | --- |
| Hearthmoor settlers | Hub NPCs: smith, alchemist, quartermaster, stablekeeper, warden captain |
| Hollowfolk | Ash-touched raiders who build fortified outposts in mid and late regions |
| The Grey Choir | Late-game Ash cult that animates the dead (ruins, crypts) |
| Wildkin | Beasts and spirits of each biome; neutral until the Ash corrupts them |

Tone: hopeful frontier survival, warm palettes against grey Ash, light humour in NPC lines.

---

## 3. Player fantasy and archetypes

Three hero archetypes are already implemented. They are kept and deepened.

| Hero (id) | Fantasy | Attack | Signature |
| --- | --- | --- | --- |
| Warden (`warden`) | Shield-bearing frontliner | melee arc | Taunts and protection |
| Ranger (`ranger`) | Skirmisher | bolt | Mobility and kiting |
| Mystic (`mystic`) | Ember-caster | nova | Area damage and support |

Heroes are collected and starred up (existing). Each gains a **skill tree** with three branches
(see PROGRESSION_DESIGN.md). Gear is shared across heroes, with **weapon-class affinities**
instead of hard locks.

---

## 4. Core loop

```text
          ┌──────────── EXPLORE a region (fog of war, landmarks) ───────────┐
          │                                                                  │
   GATHER / BREAK / MINE / FARM  ─►  FIGHT (mobs, elites, outposts, bosses)  │
          │                                │                                 │
          ▼                                ▼                                 │
   materials (pouch)                 loot, embers, keys                      │
          │                                │                                 │
          └──────► CARRY HOME (risk: death drops unbanked pouch, hunters) ◄──┘
                                   │
                                   ▼
   HOMESTEAD: bank ▸ process (smelt/tan/brew) ▸ craft ▸ enhance ▸ socket runes
                                   │
                                   ▼
            STRONGER (gear score, pets, mounts, hero stars, skills)
                                   │
                                   ▼
          UNLOCK harder region / dungeon / world boss / Ember Vault ──► repeat
```

### Session shapes

| Length | Typical session |
| --- | --- |
| 5 min | Collect homestead production, start crafts, run one gather route, claim dailies |
| 20 min | Clear a region's elite camp, run a dungeon, enhance gear |
| 45+ min | World boss window, Hollowfolk outpost raid, Kindled Key run, LAN co-op night |

### Progression arc (first release target ≈ 40–60 h)

| Act | Regions | Player level | Unlocks |
| --- | --- | --- | --- |
| I — Rekindle | Hearthmoor, Greenwood Meadow | 1–10 | Homestead, workbench, first pet, Crypt Depths |
| II — Push back | Thornwood, Gloamdeep Caverns | 10–22 | Forge, smelter, mounts, Ashfall raids, Kindled Keys |
| III — Into the Ash | Cinder Ruins, Frostvale Peaks | 22–36 | Rune altar, Mythic crafting, outposts, world bosses |
| IV — Heartlands | Ashen Wastes | 36–45 | Ember Vault endgame, Ember Cycles (prestige) |

---

## 5. Systems overview

| System | Summary | Spec |
| --- | --- | --- |
| Character | Level 1–45, hero stars 1–5, skill trees, 12 combat stats, gear score | PROGRESSION |
| Equipment | 9 slots, 6 rarities, affixes, +0…+15 enhancement, sets, ascension, runes | PROGRESSION |
| Inventory | Bag (gear/consumables) + material pouch + homestead storage, split/sort/filter/compare | ECONOMY |
| Gathering | Breakable terrain tiles, resource nodes, ore veins, herbs, fishing (later), farming | ECONOMY / WORLD |
| Crafting | Stations, processing chains, timed queues, success rates for runes, recipe unlocks | ECONOMY |
| Combat | Basic + weapon-class attacks, dodge roll, 3 hero skills + 2 gear skills, status effects | COMBAT |
| Monsters | 6 biomes × 4–5 mobs, elites, champions, field/world/dungeon bosses, outposts | COMBAT |
| World | 7 regions + hub, 4 dungeons, day/night, weather, fog of war, fast-travel beacons | WORLD |
| Village | Grid homestead, 18 buildings, production, storage, defences, Ashfall raids | VILLAGE |
| Treasure | Treasure maps, buried caches, Kindled Keys, Ember Vaults, secret rooms | TREASURE |
| Pets & mounts | 12 pets, 10 mounts, eggs, rarity, levels, stars, skills, collection bonuses | PETS_MOUNTS |
| Quests | Main chain (original), side quests per NPC, dailies, weeklies, bounties, achievements | WORLD §7 |
| Events | Local-clock calendar: world boss windows, Blood Moon nights, bonus days | WORLD §8 |
| Multiplayer | 4-player LAN, host-authoritative, co-op + opt-in PvP duel/arena | MULTIPLAYER |

---

## 6. UI/UX direction

- **Portrait, one-thumb movement**: virtual joystick bottom-left, attack + skills bottom-right
  (existing input model, which is generic).
- **Original HUD kit**: warm ember-orange accents on dark slate panels, 1-px pixel borders,
  9-slice frames. Replaces every reference-derived UI image. The current layout is reviewed so it
  doesn't mirror the reference screen arrangement.
- Top bar: portrait, HP/stamina bars, level. Top-right: minimap with region danger tint.
- Menus: a single tabbed **Satchel** screen (Bag · Pouch · Gear · Runes · Pets · Mounts),
  plus a **Journal** (Quests · Map · Codex · Achievements) and **Homestead** management.
- Comparison tooltip on long-press: stat delta arrows, set progress, gear score delta.
- Accessibility: colour-blind-safe rarity frames (shape and colour), adjustable text scale,
  screen-shake toggle, an auto-attack assist toggle.
- No auto-play bot. An **auto-gather/auto-attack assist** exists for repetitive targets in cleared
  areas.

## 7. Art direction

- 16 px tile grid. Characters about 24–32 px tall at base scale, camera zoom 2 on a 720×1600
  viewport (existing).
- Restricted master palette (about 48 colours) shared by all biomes. Each biome gets an 8–12
  colour accent ramp.
- Nearest-neighbour filtering, integer scaling. No sub-pixel rotation on sprites.
- Animations per actor: idle, walk, run, attack (per weapon class), hurt, death, gather,
  interact, cast. Four directions minimum; eight for player and bosses where the budget allows.
- Pipeline: `PixelArt` ASCII generator for small sprites, icons and prototypes; PNG sheets for
  heroes, bosses and tilesets (original or verified-licence). See ASSET_REPLACEMENT_PLAN.md.

## 8. Audio direction

- Music: one calm and one tense theme per region, a hub theme, a boss theme and a homestead theme.
- SFX: event-driven through a new `AudioService` that listens to `GameEvent` (hit, crit, gather,
  break, loot by rarity, level-up, craft success/fail, UI).
- Sources: original compositions or CC0/verified-licence packs, recorded in the provenance
  registry.

## 9. Monetisation

None. If the owner later wants a commercial release, cosmetic-only purchases can be layered on top
without touching balance. This is outside the current plan.

## 10. Open design questions for the owner

1. Keep **Emberfield** as the final title? (Assumed yes.)
2. Is the death penalty "drop unbanked material pouch in Ash regions" acceptable, or should it be
   softer (lose 25%)?
3. Should Ember Cycles (prestige) be in the first release or deferred?
4. Should LAN PvP include homestead sieges, or only duels and the arena?
