# Existing Emberfield Capability Assessment

- Stage: BRAINSTORM · 2026-11-07 · base `feat/survival-rpg @ 5a54668`
- Source: SCOUT ([EXISTING_SYSTEMS.md](../reports/EXISTING_SYSTEMS.md)) plus targeted re-reads of
  `save_service.gd`, `game_state.gd`, `quest_service.gd`, `game_content.gd`, `item_database.gd`.
- Caveat: static assessment. **No test has been executed** in this session (Godot not installed).
  "Works" means the code is complete and covered by an existing suite that earlier agents report
  passing. It is not independently verified.

The directive asks to separate four kinds of system:

## 1. Exists and works — preserve and extend

| System | Why it's sound | Extension needed |
| --- | --- | --- |
| Autoload service layer (`GameEvent`, `GameState`, `SaveService`, `QuestService`, databases) | Clear responsibilities, signal-driven | Add `WorldClock`, `AudioService`, `CommandBus` |
| Component combat (Health/Hitbox/Hurtbox, LOS, i-frames, knockback) | Generic, layered collisions | Dodge, statuses, pure damage function |
| `Monster` data-driven AI profiles | Content in data, behaviour by profile | Leash/retreat/windup states, elites, biome tables |
| `Boss` 2-phase framework | Phase switch, telegraphs, summons | 3 phases, arena mechanics, reward split |
| `InventoryData.transact` (atomic) | Right primitive for crafting, LAN, trading | Pouch/storage containers, split, filter, lock |
| Equipment equip/unequip/swap | Stable slot IDs | 2 new slots |
| Augments (stat/passive/active/timed) | Already a socket system | Generalise to pets/mounts → Runes |
| `SaveService` (versioned, atomic, `.bak`, migrations, strict validation, claim journal) | Production-grade foundation | v6–v10 per SAVE_MIGRATION_PLAN |
| `QuestService` (event-driven, stable IDs, durable claims) | Reusable engine | New objective types, side/weekly/bounty pools |
| `LanSession` host authority (monsters, hits, loot ACK, potions, respawn, replay) | Correct authority model, clamps | Generalise to CommandBus/HostAuthority; sync remaining systems |
| Homestead offline production | Real-time timers incl. offline | Grid placement, more buildings, raids |
| Pets (follow/attack/heal/evolve), mounts (categories, skins) | Working loops | Instances, rarity, eggs, skills, runes |
| Hero collection + stars, hero skills | Working | Skill trees, level cap 45 |
| Dungeon generator + minimap | Working procedural rooms | Themes, new dungeons, secret rooms |
| Seeded `FieldMap` | Deterministic, camps, altar, gate, dig spots | Biome data model, terrain layer, landmarks |
| `DigSpot` | Complete stand-to-dig loop | Map targets, guardians |
| `PixelArt` ASCII generator | Original-art pipeline, cached | Animation frames helper, palette master |
| Mobile input (joystick, multi-touch buttons) | Logic is generic | Re-skin with the original UI kit |
| Test harnesses (headless suites, 2-process LAN, render captures) | Real coverage | Fixtures, provenance gate, 4-process LAN |

## 2. Exists but incomplete

| System | What's missing |
| --- | --- |
| Resource gathering (`ResourceNode`) | Tools, tiers, gather speed, rarity, biome tables, persistence |
| Crafting (`CraftingRecipe`, panel) | Stations as buildings, durations/queues, success chance, unlocks, processing chains |
| Item model | Mythic, per-instance affixes/uid, sets, requirements, comparison |
| Enhancement | Success/failure, pity, protection; currently a guaranteed cost curve |
| Stats | crit damage, attack speed, accuracy, dodge, counter, resistances |
| Status effects | Only a processor hack (TODO at line 117) |
| Village | Fixed 6 plots; no grid, defence, raids, storage |
| Quests | Main chain ~21 and 3 dailies; no side/weekly/bounty/achievement |
| World | 2 field zones; no biome model, day/night, fog, beacons |
| LAN | Most systems unsynchronised; no discovery, reconnection token, PvP |
| HUD/menus | Built for parity screens; legacy 1280×720 popups auto-scaled |
| Audio | Nothing |

## 3. Exists but copies reference content — replace

| Item | Location | Replacement |
| --- | --- | --- |
| 82 extracted/capture-derived images | `assets/treasure_hunter/**` | ASSET_REPLACEMENT_PLAN §3 |
| Reference equipment (Cards 28–30, stat ranges, upgrade rates) | `reference_equipment_catalog.gd`, `…_stat_generator.gd`, `…_reward_resolver.gd`, `ItemData.set_reference_instance_data` | Original templates via the instance system; save v6 map |
| Reward boxes keyed by source Box IDs | `reward_box_catalog.gd` | Original reward table IDs; resolver logic kept |
| Quests q305–q311 (IDs, Vietnamese text copied from source) | `game_content.gd`, `quest_service.gd` | Tutorial t01–t07 with original text |
| Monster rows `snailu`, `turtle` (source card IDs, recovered timings) and the `reference_melee` profile name | `game_content.gd`, `monster.gd` | Mossback/Bramble Snail; profile renamed `timed_melee` |
| Reference monster display names on original IDs (Mosqui, Snailu, Astromophy) | `game_content.gd` | Gnatling, Bramble Snail, Bristle Boar |
| HUD/menu/startup gate chrome and layouts matched to captures | `mobile_hud.gd`, `game_menu.gd`, `startup_gate.gd`, `action_button.gd`, `virtual_joystick.gd`, `equipment_detail_panel.gd` | Original UI kit and a re-reviewed layout |
| Capture/research docs, ADB tool, art bible, parity skills | `docs/original-captures/`, `docs/research/…`, `tools/treasure_hunter_device.sh`, `.agents/skills/**` | Retire (owner approval) |

## 4. Needs complete redesign

| System | Reason |
| --- | --- |
| Project rules (`AGENTS.md`, shared decisions) | Mandate pixel-parity recreation, which contradicts the directive |
| Asset manifest schema | Records "local_only extracted" provenance; needs licence fields and a gate |
| Skill input model | Three parallel models (equipment Q/E/R/F, hero Z/X/C, gear skill G) don't fit portrait. Redesign to 3 hero + 2 rune skills |
| Stat aggregation | Scattered `get_total_*` sums across inventory, buffs, pets, mounts, buildings → one `StatBlock` |
| Main quest chain | Needs a 4-act original narrative around the existing original quests |
| Two monster stacks (`skeleton.gd` vs `monster.gd`) | Merge the skeleton into a `Monster` profile with the 8-direction sheet visual |

## 5. Risks carried into PLAN

See [TECHNICAL_RISKS.md](../reports/TECHNICAL_RISKS.md). The most important are R1 (direction
rules), R3 (no local Godot), R4 (save/LAN migration) and R5 (`player.gd` at 1,510 lines).
