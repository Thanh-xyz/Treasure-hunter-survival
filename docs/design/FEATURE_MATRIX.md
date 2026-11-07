# Gameplay Feature Matrix

- Stage: BRAINSTORM · 2026-11-07 · base `feat/survival-rpg @ 5a54668`
- Statuses: **COMPLETE** · **PARTIAL** · **MISSING** · **BLOCKED** · **NEEDS REPLACEMENT** ·
  **NEEDS LEGAL REVIEW**
- A feature is COMPLETE only when it meets the design here and has a test. Nothing is marked
  COMPLETE just because code exists. Because no test was executed in this session, even working
  systems are at most PARTIAL until the P0 baseline run.
- "Ref" = general mechanic from [REFERENCE_RESEARCH.md](REFERENCE_RESEARCH.md). "Spec" = the
  design document holding the detail.
- Columns: **Assets/Data** = required assets and data tables. **Test → Accept** = test
  requirement and acceptance criterion.

## 0. Foundation

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F0.1 | — → Project rules for an original game | BLOCKED (owner approval) | `AGENTS.md`, shared `decisions.md` | Rewrite | — | D1 | Review → rules contain no parity mandate |
| F0.2 | — → Godot 4.6 test environment | MISSING | CI workflow | Local binary | — | D6 | All suites run headless locally → baseline recorded |
| F0.3 | — → Asset provenance registry + gate | PARTIAL | `asset-manifest.json` | Licence fields, gate test, CREDITS | manifest schema | F0.1 | Gate test → fails on any excluded/unrecorded runtime asset |
| F0.4 | — → Reference content replacement | NEEDS REPLACEMENT | see CAPABILITY §3 | Originals | ASSET_REPLACEMENT §3 | F0.3, F0.5 | grep + gate → zero `assets/treasure_hunter` refs |
| F0.5 | — → Save v6 migration | MISSING | `save_service.gd` | Mapping, Lost & Found | fixtures | F0.2 | Fixture suite → all v1–v5 fixtures load, no loss |
| F0.6 | — → Third-party asset licences | NEEDS LEGAL REVIEW | `assets/{tilesets,soldiers,enemies,items,Shop,blacksmith,Font}` | Licence text | CREDITS.md | D5 | Manual → every pack verified or scheduled for replacement |
| F0.7 | — → Upstream code rights | NEEDS LEGAL REVIEW | whole repo (upstream has no licence) | Written permission | — | D5 | Owner confirmation recorded |
| F0.8 | — → Branding (title, logo, icon) | PARTIAL | `icon.svg` (Godot default) | Logo, icon | 3 assets | D7 | Visual review |

## A. Character

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | Movement → 8-dir move, joystick | PARTIAL | `player.gd`, `virtual_joystick.gd` | Original joystick art | UI kit | F0.4 | Input test → move/collide on all biomes |
| A2 | Levels/XP → Lv 1–45 curve | PARTIAL | `game_state.gd`, `game_content.gd` | Extend to 45, skill points | XP table | — | Unit → curve monotonic, level-ups emit events |
| A3 | Classes → 3 heroes + stars | PARTIAL | `GameContent.HEROES`, `hero_skill_runner.gd` | Distinct hero sprites | 3 hero sheets | F0.4 | Unit → star bonuses apply |
| A4 | — → Skill trees (3×5 per hero) | MISSING | — | All | tree data, icons | A2 | Unit → node effects modify skills; respec refunds |
| A5 | Combat stats → 15-stat `StatBlock` | PARTIAL | `character_stats.gd`, `inventory_data.gd` sums | crit_dmg, aspd, acc, dodge, counter, res, gather, luck; aggregator | stat table | — | Unit → aggregate equals sum of sources; caps enforced |
| A6 | Power → Gear score | MISSING | — | Formula, HUD | weights | A5, B3 | Unit → GS monotonic in item power |
| A7 | Death/respawn → beacon/homestead respawn + Ash-zone remnant | PARTIAL | `player.gd`, respawn flow | Remnant, beacons | remnant rules | C2, D4 | Integration → pouch drops only in Ash zones; recoverable 10 min |
| A8 | — → Codex/account bonuses | MISSING | — | All | codex data | H, I | Unit → bonuses capped |
| A9 | Seasons → Ember Cycles (opt-in prestige) | MISSING | — | All | — | endgame | Deferred (owner question) |

## B. Equipment

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| B1 | Slots → 9 slots (+gloves, cloak) | PARTIAL | `InventoryData.EQUIPMENT_SLOTS` | 2 slots, UI | icons | save v8 | Unit → equip rules per slot |
| B2 | Weapon types → 7 weapon classes | MISSING | heroes have attack styles | Per-weapon patterns | anim per class | A5, E1 | Integration → each class attack pattern hits correctly |
| B3 | Rarity (4) → 6 tiers incl. Mythic | PARTIAL | `ItemData.ItemRarity` (5) | Mythic, frames | 6 frames | — | Unit → enum append-only |
| B4 | Random stats → instance affixes + uid | PARTIAL | reference instance data (to retire) | Generic instances | affix pools | save v8 | Unit → rolls within bands; serialisation round-trip |
| B5 | Upgrade → +0…+15 with success/fail, pity, ward | PARTIAL | `upgrade_equipment` | Probabilities, protection | cost table | B4 | Seeded unit → rates match table ±1% over 100k rolls |
| B6 | Tier upgrade → Ascension | MISSING | — | All | — | B4 | Unit → stats never decrease |
| B7 | Sets → 6 region sets (2/4 piece) | MISSING | — | All | 30 icons, set table | B1, E | Unit → bonuses toggle at thresholds |
| B8 | Stones → Runes on gear/pets/mounts, fusion | PARTIAL | augment system | Tiers, families, hosts, fusion | rune icons | B4, J | Unit → socket rules; fusion odds |
| B9 | Artifacts → Relics with auras | MISSING | — | All | relic data | B8 | Unit → aura radius on LAN |
| B10 | Requirements → level gate | MISSING | — | — | — | A2 | Unit |
| B11 | Comparison tooltip | MISSING | `equipment_detail_panel.gd` | Delta view | UI | A5 | UI render test |
| B12 | Dismantle → Salvage to Ember Dust | MISSING | `sell_item_at` | Salvage | — | D | Unit → no dupes |
| B13 | Reference equipment Cards 28–30 | NEEDS REPLACEMENT | `reference_equipment_*.gd` | Original templates | 3 icons | F0.5 | Migration fixture |

## C. Inventory and economy

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C1 | Bag → 32→64 bag | PARTIAL | `inventory_data.gd` | Expansion | satchel items | — | Unit |
| C2 | Ingredient pouch → material pouch | MISSING | — | Container, routing | — | save v8 | Unit → materials auto-route |
| C3 | Storage → homestead storage | MISSING | — | Container, UI | — | G | Unit → transfer is atomic |
| C4 | Stacking, sort | PARTIAL | `sort_inventory`, stacking | — | — | — | Existing tests |
| C5 | Split stack, filter, lock | MISSING | — | All | — | C1 | Unit |
| C6 | Currencies → gold, embers, shards, valor, renown | PARTIAL | gold, diamonds | embers rename, valor, renown | — | save v8 | Unit |
| C7 | Shops | PARTIAL | `smith_shop_popup.gd`, merchant | Data-driven stock, rotation, new NPCs | NPC art | — | Unit → prices from data |
| C8 | Drop-rate buffs → meals/elixirs | PARTIAL | timed buffs | luck/gather buffs | — | A5 | Unit |
| C9 | Trading → LAN trade (escrow) | MISSING | — | All | — | L | LAN test → no dupes under disconnect |
| C10 | Economy balance | MISSING | — | Simulation script | — | D | Sim → income/cost within targets |

## D. Gathering, crafting, farming

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| D1 | Breakable tiles → terrain layer | MISSING | — | TileMap damage layer, persistence | crack sprites | E1 | Integration → tiles break, drop, regrow, persist |
| D2 | Nodes → tool-tiered gathering | PARTIAL | `resource_node.gd` | Tools, tiers, speed, tables | node sprites | A5 | Unit → hits formula |
| D3 | Tools → tool belt T1–T5 | MISSING | — | All | 25 icons | D2 | Unit → auto-select |
| D4 | Digging → dig plots | PARTIAL | `dig_spot.gd` | Map targets, guardians | — | I | Existing + new |
| D5 | Processing chains | MISSING | — | Stations, recipes | station sprites | D6 | Unit → chains |
| D6 | Crafting stations + queues + durations | PARTIAL | `crafting_panel.gd`, `recipe_database.gd` | Stations, timers, unlocks, success | recipe tables | G | Unit → offline timer, success odds |
| D7 | Campfire crafting | MISSING | — | World campfires | sprite | D6 | — |
| D8 | Farming → crops on plots | MISSING | Herb Garden (passive) | Crops, growth, water | 12 crops × stages | G | Unit → growth timers incl. offline |
| D9 | Resource miners → production buildings | PARTIAL | Lumber Mill, Quarry, Herb Garden | Ore Drill, caps | — | G | Existing tests + caps |

## E. World and exploration

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E1 | Zones → biome data model | MISSING | `field_map.gd`, `GameContent.ZONES` | Biome table consumed by FieldMap | biome data | — | Unit → map built from data only |
| E2 | Zones → 6 regions + hub + homestead | PARTIAL | town, greenwood, frostvale, homestead | thornwood, gloamdeep, cinder_ruins, ashen_wastes | 4 tilesets | E1 | Scene load test per region |
| E3 | Dungeons → 5 dungeons | PARTIAL | Crypt Depths | 4 new themes | room sets | E1 | Generation test → all rooms reachable |
| E4 | Safe vs danger areas → Ash zones | MISSING | `safe` flag on zones | Rules | — | A7 | Integration |
| E5 | — → Landmarks, beacons, fast travel | MISSING | gate/portal | All | sprites | E1 | Integration |
| E6 | — → Fog of war, exploration rewards | MISSING | minimap | Fog | — | E1 | Unit → reveal % persisted |
| E7 | — → Day/night (`WorldClock`) | MISSING | — | All | light textures | save v7 | Unit → clock persistence, night tables |
| E8 | — → Weather | MISSING | — | Visuals | particles | E7 | Visual |
| E9 | World persistence → region state | MISSING | — | Save section | — | save v7 | Round-trip |

## F. Combat and monsters

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F1 | Basic attack | PARTIAL | `player.gd`, hitbox | Per-weapon patterns | anims | B2 | Integration |
| F2 | — → Dodge roll | MISSING | — | All | anim | A5 | Unit → i-frame window |
| F3 | Skills → 3 hero + 2 rune skills | PARTIAL | `hero_skill_runner.gd`, `skill_component.gd` | Input model consolidation | icons | A4, B8 | Integration |
| F4 | Crit/defence/accuracy/dodge → pure damage function | PARTIAL | `combat.gd`, components | Unify, seeded RNG | — | A5 | Seeded unit → known outputs |
| F5 | Status effects → `StatusEffectComponent` | PARTIAL | `passive_effect_processor.gd` | Component, 8 effects | FX | F4 | Unit → stacking/durations |
| F6 | Mob AI → leash/retreat/windup states | PARTIAL | `monster.gd`, `skeleton.gd` | New states, skeleton merge | — | — | Unit/integration → no stuck states |
| F7 | Mob tiers → elites/champions | MISSING | elite flag | Affixes | aura FX | F6 | Unit |
| F8 | Biome rosters (~25 mobs) | PARTIAL | ~13 monster rows | ~15 new | sprites | E | Spawn test per table |
| F9 | Bosses (field/world/dungeon/vault) | PARTIAL | `boss.gd`, Mire King, Crypt Warden, Bone Colossus | 7 new, P3 phases | boss sprites | F6 | Integration per boss |
| F10 | Last-hit + participation rewards | MISSING | — | Reward split | — | L | Unit (offline + LAN) |
| F11 | Loot tables → nested + pity + conditions | PARTIAL | `loot_table.gd` | Nesting, pity, conditions | tables | — | Seeded unit → distribution ±2% |
| F12 | Reference monsters (snailu, turtle, display names) | NEEDS REPLACEMENT | `game_content.gd`, `monster.gd` | Mossback, Bramble Snail | sprites | F0.5 | Migration fixture |
| F13 | Difficulty/party scaling | MISSING | — | Formulas | — | L | Unit |

## G. Village and building

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| G1 | Building system → grid placement + validation | PARTIAL | `homestead_map.gd` (6 plots) | Grid, ghost, move | — | save v10 | Unit → validation rules |
| G2 | Buildings → 25-type roster with levels | PARTIAL | 6 types | 19 types | sprites | G1 | Unit → costs from data |
| G3 | Production | PARTIAL | offline production | Caps, ore drill | — | G1 | Existing + caps |
| G4 | Storage building | MISSING | — | — | — | C3 | — |
| G5 | Defence → walls, towers, traps | MISSING | — | All | sprites | G1 | Integration |
| G6 | Village attacks → Ashfall raids | MISSING | — | Raid director, pathing | Hollowfolk sprites | G5, F6 | Integration → raid resolves, simulated outcome matches rules |
| G7 | NPC villages → Hollowfolk Outposts | MISSING | — | All | sprites | G2, F6 | Integration |
| G8 | Village progression → Renown tiers | MISSING | — | All | — | G1 | Unit |
| G9 | Clan village / capture | MISSING (deferred) | — | LAN siege mode | — | L | Deferred P9+ |

## H. Pets and mounts

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H1 | Pet companion behaviour | PARTIAL | `pet_follower.gd` | FETCH/GATHER/STAY/downed | — | — | Integration |
| H2 | Pet acquisition → eggs + Hatchery | MISSING | gold unlock | Eggs, hatching | egg sprites | G2 | Unit → rarity roll |
| H3 | Pet rarity/levels/stars/evolution | PARTIAL | levels, evolve 5/10 | Rarity, stars, 30 levels | evo sprites | save v10 | Unit |
| H4 | Pet roster 12 | PARTIAL | 4 pets | 8 | sprites ×3 evo | H2 | — |
| H5 | Mount movement + categories | PARTIAL | mount toggle, `GameContent.MOUNTS` | Signature moves, stamina | anims | — | Integration |
| H6 | Mount roster 10, levels, gear, skins | PARTIAL | 4 mounts, skins | 6 mounts, levels, gear | sprites | save v10 | Unit |
| H7 | Collection bonuses | MISSING | — | Codex | — | A8 | Unit |
| H8 | Runes on pets/mounts | MISSING | — | Hosts | — | B8 | Unit |

## I. Treasure

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| I1 | Chests → biome/dungeon chests | PARTIAL | chests, `game_item.gd` | Tables per tier | chest sprites | F11 | Unit |
| I2 | — → Treasure maps + fragments + guardians | MISSING | `dig_spot.gd` | All | map icons | D4, E | Integration |
| I3 | Keys → Kindled Keys (marked carrier, hunters, channel) | MISSING | — | All | key/vault sprites | E4, F6 | Integration → full run offline; LAN carrier sync |
| I4 | Dungeon treasure → Ember Vault | MISSING | dungeon generator | All | vault set | E3, I3 | Integration |
| I5 | Secret locations + dowsing | MISSING | — | All | — | D1 | Integration |
| I6 | Reward boxes (reference IDs) | NEEDS REPLACEMENT | `reward_box_catalog.gd` | Original tables | — | F0.5 | Fixture |

## J. Quests, progression, events

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| J1 | Quest engine | PARTIAL | `quest_service.gd` | New objective types | — | — | Existing suites |
| J2 | Tutorial q305–q311 | NEEDS REPLACEMENT | `game_content.gd` | t01–t07 original | text | F0.5 | Migration fixture |
| J3 | Main chain (4 acts, ~45) | PARTIAL | q01–q15 original | ~30 quests, narrative | text, NPC portraits | E | Content test → every quest reachable |
| J4 | Side/weekly/bounty quests | MISSING | 3 dailies | Pools | — | J1 | Unit |
| J5 | Achievements | MISSING | — | ~80 | icons | A8 | Unit |
| J6 | Events calendar | PARTIAL | world boss timer | Calendar, Blood Ember, bonus days | — | E7 | Unit → clock-skew guard |

## K. Presentation

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| K1 | HUD/menus | NEEDS REPLACEMENT | `mobile_hud.gd`, `game_menu.gd`, `startup_gate.gd` | Original kit + layout | UI kit | F0.4 | Render tests updated |
| K2 | Legacy 1280×720 popups | PARTIAL | `_fit_legacy_popup` | Native portrait panels | — | K1 | Render tests |
| K3 | Audio | MISSING | — | `AudioService`, assets | ~12 tracks, ~120 SFX | F0.3 | Events trigger SFX |
| K4 | Accessibility | MISSING | — | Text scale, colour-blind frames, shake toggle | — | K1 | Manual |
| K5 | Auto-gather/attack assist | MISSING | — | Assist toggle | — | D2 | Integration |

## L. Multiplayer

| ID | Ref concept → Emberfield | Status | Existing files | Missing | Assets/Data | Deps | Test → Accept |
| --- | --- | --- | --- | --- | --- | --- | --- |
| L1 | Co-op sessions (4 players) | PARTIAL | `lan_session.gd` | Discovery, content hash | — | — | 4-process harness |
| L2 | CommandBus/Authority layer | MISSING | — | All | — | — | Same command offline and host give equal results |
| L3 | Sync: equipment/crafting/gathering/chests/buffs/quests/pets/mounts/building/keys/clock | MISSING | — | Per MULTIPLAYER §4 | — | L2 + each system | Per-system LAN tests |
| L4 | Reconnection | PARTIAL | disconnect replay | Session tokens, ledger | — | L2 | Kill/rejoin test → no loss/dupe |
| L5 | PvP duel/arena/region flag | MISSING | — | All | arena scene | L2, F4 | LAN test |
| L6 | Clans, guild village, sieges, faction war | MISSING (deferred to online) | — | — | — | P10 | — |
| L7 | Online server | MISSING (design only) | — | — | — | P10 | — |

## Summary counts

| Status | Count |
| --- | --- |
| COMPLETE | 0 (none verified yet; P0 baseline needed) |
| PARTIAL | 46 |
| MISSING | 57 (includes 3 explicitly deferred: G9, L6, L7) |
| BLOCKED | 1 |
| NEEDS REPLACEMENT | 6 |
| NEEDS LEGAL REVIEW | 2 |
| **Total** | **112** |
