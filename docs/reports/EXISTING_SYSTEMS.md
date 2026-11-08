# Existing Systems — Emberfield (SCOUT, 2026-11-07)

Status legend: **Implemented** · **Partial** · **Planned** (documented, not built) · **Missing** ·
**Reference-derived** (built from the reference game's extracted data/assets — must be replaced
under the original-game direction).

All statuses come from static inspection of `feat/survival-rpg @ 5a54668`. No test was executed
during SCOUT (Godot not installed); "tested" below means a suite exists, not that I ran it.

## 1. Project history in two eras

| Era | Dates | Commits | Authors | Character |
| --- | --- | --- | --- | --- |
| Original Emberfield | 2026-02-08 → 03-18 | ~95 | upstream team (`HauTranCong/emberfield`) | 1280×720 top-down action RPG: town, dungeon, skeleton, shop, blacksmith, inventory, augments, crafting |
| Survival slice + TH recreation | 2026-11-03 → 11-06 | ~230 | owner + Agent A (art) + Agent B (logic) | Portrait mobile survival RPG; from Nov 4, pixel-parity recreation of Treasure Hunter quests q305–q311 |

## 2. Systems

| System | Status | Key files | Notes |
| --- | --- | --- | --- |
| Game bootstrap / main scene | Implemented | `sense/Main.tscn`, `sense/main.gd`, `sense/ui/mobile/startup_gate.gd` | Startup gate (offline / Host / Join); gate visuals are reference-matched |
| Signal bus | Implemented | `sense/globals/game_event.gd` | Domain events: `enemy_killed`, `resource_gathered`, `zone_entered`, `building_built`, `player_died/respawned`, `boss_*`, `toast`, `open_menu` |
| Collision standard | Implemented | `sense/globals/collision_layers.gd`, `docs/LAYER_AND_MASK_STANDARDS.md` | 10 named layers |
| Scene transitions / camera | Implemented | `scene_transition_service.gd`, `camera_service.gd` | Fade transitions; FOLLOW/STATIC/ROOM camera |
| Player controller | Implemented | `sense/entities/player/player.gd` (1,510 lines), `character_stats.gd` | 8-dir move, attack, states, skills, potions, mount, respawn. Large file — many responsibilities |
| Mobile input | Implemented | `sense/ui/mobile/virtual_joystick.gd`, `action_button.gd` | Multi-touch; visuals reference-matched |
| Combat core | Implemented | `sense/components/hitbox_component.gd`, `hurtbox_component.gd`, `health_component.gd`, `sense/combat/combat.gd` | LOS check, i-frames, knockback, crit, life steal |
| Passive effects | Partial | `passive_effect_processor.gd` | Burn/freeze/poison/thorns; TODO at line 117 asks for a real status-effect component |
| Buffs | Implemented | `buff_component.gd` | Timed ATK/DEF/HP/SPD |
| Equipment skills | Implemented | `skill_component.gd`, `skill_executor.gd`, `sense/skills/skill_database.gd` | Q/E/R/F bound to equipment |
| Hero skills | Implemented | `sense/combat/hero_skill_runner.gd`, `GameContent` heroes/skills | 3 heroes (Warden, Ranger, Mystic) × 3 skills; Z/X/C — a second, parallel skill model |
| VFX helpers | Implemented | `sense/combat/` (projectile, telegraph, damage number, ring FX) | |
| Dodge roll | Missing | — | |
| Enemy: skeleton | Implemented | `sense/entities/enemies/skeleton/skeleton.gd` (639) | Patrol/chase/attack, 8-dir sheets |
| Enemy: data-driven monster | Implemented | `sense/entities/enemies/monster/monster.gd` (684) | melee / flyer / ranged / charger / stationary_melee / reference_melee, elites |
| Monster visuals | Reference-derived (partial) | `monster_visual_catalog.gd` | Maps asset IDs → SpriteFrames; current atlases are extracted (Mosqui, Snailu, Turtle) |
| Boss | Implemented | `boss.gd` | 2 phases: slam, leap, nova, summon. World-boss altar timer in field |
| Enemy retreat state | Missing | — | |
| Loot tables | Implemented | `sense/items/loot_table.gd`, `item_spawner.gd`, `game_item.gd` | Weighted; pickup modes AUTO/MAGNET/INTERACT/PROXIMITY |
| Reward boxes | Reference-derived | `reward_box_catalog.gd`, `reward_box_resolver.gd` | Keys are source `Box.json` IDs (98, 149–152); resolver logic itself is reusable |
| Item model | Implemented | `sense/items/item_data.gd`, `item_database.gd` (~40+ items) | 11 types, 5 rarities (no Mythic), augment types, upgrade multiplier |
| Reference equipment | Reference-derived | `reference_equipment_catalog.gd`, `reference_equipment_stat_generator.gd`, `reference_equipment_reward_resolver.gd`, `ItemData.set_reference_instance_data` | Source Card IDs 28–30, stat ranges and upgrade rates copied from extracted `Card.json` |
| Inventory | Implemented | `sense/ui/inventory/inventory_data.gd` (767) | 32 slots, add/remove, atomic `transact`, sort, swap, sell, use, equip/unequip/swap equipment |
| Stack split / filter / weight | Missing | — | Sort exists; tabs act as category filters in UI |
| Equipment slots | Implemented | `InventoryData.EQUIPMENT_SLOTS` | helmet, armor, weapon, shield, boots, accessory_1, accessory_2 (no gloves) |
| Equipment upgrade | Implemented | `InventoryData.upgrade_equipment`, `ItemData.get_upgrade_cost` | Cost curve, level cap; no failure chance |
| Augments | Implemented | `sense/ui/augment/augment_panel.gd`, `InventoryData.apply_augment/remove_augment` | Socketing stat/passive/active augments |
| Item comparison / power score | Missing | — | Equipment detail panel exists (`equipment_detail_panel.gd`), no side-by-side compare |
| Crafting | Partial | `sense/ui/crafting/crafting_recipe.gd`, `recipe_database.gd`, `crafting_panel.gd` | Tiered recipes, categories; no duration, success %, station requirement or unlock gating |
| Shops / NPCs | Implemented | `sense/entities/npcs/blacksmith/*`, `merchant/*`, `shop_component.gd` | Blacksmith shop, merchant |
| Field maps | Implemented | `sense/maps/field/field_map.gd` (373), `world_props.gd` | Seeded generation: ground, bounds, border trees, camps, altar, gate, dig spots, scatter |
| Biome data model | Missing | `GameContent` zones | Zones carry name/level/scene only; resource/spawn tables live in map code |
| Resource gathering | Partial | `resource_node.gd` | Hit-to-gather trees/rocks, fixed 35 s respawn; no tools, speeds, rarity, biome tables |
| Digging / treasure plots | Implemented | `dig_spot.gd` | Stand-to-dig with staged cracks and reward roll; current tutorial framing is reference-derived (q305) |
| Farming | Missing | — | Herb Garden produces passively; no crop planting |
| Dungeon | Implemented | `sense/maps/dungeon/dungeon_generator.gd`, `dungeon_level.gd`, `dungeon_minimap.gd` | Procedural rooms, 4 room types, Crypt Warden boss |
| Town hub | Implemented | `sense/maps/town/` | Portals, shops |
| Homestead / village | Partial | `sense/maps/homestead/homestead_map.gd`, `GameContent` buildings | 6 fixed plots, 6 building types with levels; real-time & offline production. No free grid placement, walls, towers, traps |
| Pets | Implemented | `sense/entities/pets/pet_follower.gd`, `GameContent` pets | 4 pets; follow, attack/defense/support/utility roles, feed to level, evolve at Lv5/Lv10 |
| Mounts | Implemented | `GameContent` mounts, player mount toggle | 4 mounts; speed/attack/defense categories, skins |
| Character progression | Implemented | `GameState`, `character_stats.gd` | Level/XP curve, hero stars via shards, stat aggregation |
| Extended stats | Missing | — | No accuracy, dodge, attack-speed, crit-damage stats |
| Quests | Partial / Reference-derived | `sense/globals/quest_service.gd`, `GameContent` quests | Generic engine is reusable. Content: q01–q15 + 3 dailies are original; **q305–q311 copy reference quest IDs, Vietnamese text and Box rewards** |
| Treasure maps / keys / carrier-reveal | Missing | — | |
| Day/night | Missing | — | |
| Save / load | Implemented | `sense/globals/save_service.gd` (646) | Version 5, atomic + `.bak`, autosave, `_migrate`, strict validation, stable quest IDs |
| LAN multiplayer | Partial | `sense/network/lan_session.gd` (1,123), `lan_remote_avatar.gd` | Host-authoritative transforms, monsters, combat, loot ACK, potions, respawn. Not synced: equipment, crafting, selling, chests, gathering, digging, buffs, per-peer quests, pets, mounts, world save |
| Online | Missing (correctly) | — | |
| HUD / menus | Implemented / Reference-derived visuals | `sense/ui/mobile/mobile_hud.gd` (984), `game_menu.gd` (740), `ui_theme.gd`, `sense/ui/hud/*` | Logic reusable; chrome uses 57 extracted UI images and reference layouts |
| Original pixel generator | Implemented | `sense/globals/pixel_art.gd` (691) | 25 ASCII sprites + palettes → textures |
| Audio | Missing | — | No audio bus layout, no assets |
| Notifications / dialogs | Implemented | `notification_manager.gd`, `confirm_dialog.gd` | |

## 3. Reference-derived footprint (to replace)

Files that read `assets/treasure_hunter/**`:
`monster_visual_catalog.gd`, `game_content.gd`, `world_props.gd`, `equipment_detail_panel.gd`,
`action_button.gd`, `game_menu.gd`, `mobile_hud.gd`, `startup_gate.gd`, `virtual_joystick.gd`.

Files carrying reference IDs/data: `game_content.gd` (q305–q311, `source_card_id`, Snailu/Turtle/
Mosqui/Astromophy names), `reference_equipment_*.gd`, `reward_box_catalog.gd`, `item_data.gd`
(reference instance data), `item_database.gd`, `inventory_slot_ui.gd`, `save_service.gd`,
`quest_service.gd`, `monster.gd` (`reference_melee` profile).

Non-runtime: `docs/original-captures/` (114 files), `docs/research/treasure-hunter-survival/`,
`docs/treasure_hunter_xapk_analysis.md`, `docs/architecture/asset-manifest.json`,
`docs/architecture/game-art-bible.md`, `tools/treasure_hunter_device.sh`, `.agents/skills/**`.

The footprint is concentrated in content tables, the visual catalog, and HUD chrome. Core
engines (combat, inventory, save, quest service, LAN) are generic and can stay.

## 4. Test assets

| Suite | File | Kind |
| --- | --- | --- |
| Legacy systems (phases 1–7 + survival/save) | `tests/legacy_system_tests.gd`, `LegacySystemTests.tscn` | headless |
| Survival | `tests/survival_tests.gd`, `survival_runner.gd`, `SurvivalTests.tscn` | headless |
| Inventory transactions | `tests/inventory_transaction_tests.gd` | headless |
| LAN (3 two-process harnesses) | `tests/Lan*PeerRunner.tscn` | two processes |
| Render captures (9) | `tests/render_*.gd` | screenshot for visual review |

Prior agents report all of these passing on `main @ 5a54668` with Windows CI run `42199543115`.
**I have not reproduced this.**
