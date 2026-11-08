# PLAN — P0-8 🔒 Reference Content Retirement and Save v6

- Stage: PLAN · 2026-11-08 · needs explicit owner approval (save format change)
- Inputs: [SAVE_MIGRATION_PLAN.md](../design/SAVE_MIGRATION_PLAN.md) §4,
  P0-4 fixtures (`tests/fixtures/saves/`), [CAPABILITY_ASSESSMENT.md](../design/CAPABILITY_ASSESSMENT.md) §3
- Branch: `feature/p0-8-save-v6` after P0-6 (monster art) is merged
- Goal: no gameplay data copied from the reference game remains in content tables; every existing
  save keeps its progress.

## 1. Reference-derived content to replace (measured)

| Location | Content | Replacement |
| --- | --- | --- |
| `game_content.gd` `MAIN_QUESTS` | `q01` text + `source_quest_id: 335`; `q305–q311` (IDs, copied Vietnamese text, source IDs, Box rewards) | `q01` keeps its ID with new text; `t01–t07` original tutorial |
| `game_content.gd` `MONSTERS` | `snailu`, `turtle` rows (source card IDs, recovered timings/stats) | `mossback` (original stats); `snailu` removed (Bramble Snail = `shroom`) |
| `game_content.gd` zone `greenwood` spawns | `["turtle", 1], ["snailu", 1]` | `["mossback", 1]` |
| `reward_box_catalog.gd` | Box IDs 98, 149–152 from `Box.json` | Original reward tables keyed by string ID |
| `reference_equipment_catalog.gd`, `…_stat_generator.gd`, `…_reward_resolver.gd`, `ItemDatabase._create_reference_weapons` | Cards 28–30 (`th_weapon_*`), stat ranges, upgrade rates | 3 original starter weapons |
| `monster.gd` | `reference_melee` profile name | `timed_melee` (same behaviour) |

The reference files themselves are deleted in P0-9 🔒, not here. P0-8 stops using them; the v6
migration carries its own small mapping table, so it doesn't depend on the old catalogs.

## 2. New original content

### Tutorial chain (Hearthmoor, Warden Captain)

| ID | Name (vi) | Objective | Reward |
| --- | --- | --- | --- |
| `q01` | Nhóm lửa đầu tiên | dig ×1 | 100 gold (unchanged) |
| `t01` | Đất còn hơi ấm | dig ×10 | 1 random starter weapon (table `starter_weapon`) |
| `t02` | Lớp vỏ rêu | kill `mossback` ×1 | 30 gold + 1 diamond |
| `t03` | Khoác giáp lên đường | equipped_count ≥ 3 | 1 diamond |
| `t04` | Rèn cho bén | equipment_level ≥ 2 | 200 gold |
| `t05` | Ốc gai trong bụi | kill `shroom` ×3 | 1 diamond |
| `t06` | Màu của độ hiếm | equipped_rarity ≥ Uncommon | 1 diamond |
| `t07` | Bàn tay thợ rèn | craft ×1 (any recipe) | 2 health potions + 50 gold |

All text is newly written. The chain then continues with the existing original `q02…q15`.

### Starter weapons (`ItemDatabase`)

| ID | Type | Rarity | Stats |
| --- | --- | --- | --- |
| `ashwood_blade` | sword | Common | from the equipment formula |
| `ironbark_cleaver` | axe | Common | from the equipment formula |
| `ember_dirk` | dagger | Common | from the equipment formula |

Owner decision 2026-11-08: weapon stats will be supplied by the owner later. Implementation keeps
them as a single data row per weapon in `ItemDatabase` and blocks P0-8 merge until the values
are filled in. The migration's gold compensation depends on these values. All weapons are
upgradable (default cost curve). Icons: ASCII (P0-5 icon set).

### `mossback` monster
Stationary guard (existing `stationary_melee` profile), original numbers: HP 90, damage 14,
attack interval 1.2 s, windup 0.5 s, death 0.6 s, gold 3–6, XP 12. Art from P0-6.

### Reward tables
`RewardBoxCatalog` keyed by strings: `starter_weapon` (equal weights over the three weapons),
`diamond_1`, `gold_200`, etc. Quest rows use `reward_table` instead of `reward_box_id`.

## 3. Save v6 migration (`SaveService._migrate`, `SAVE_VERSION` 5 → 6)

| v5 data | v6 result | Notes |
| --- | --- | --- |
| item `th_weapon_28` / `_29` / `_30` (bag or equipped) | `ashwood_blade` / `ironbark_cleaver` / `ember_dirk` | Keep `level` and `augments`; drop the `reference` block. If the old rolled damage exceeds the new item's attack, grant `(old − new) × 10` gold, logged in `migration_log` |
| any other `reference` block | item kept if its ID still exists; otherwise moved to `lost_and_found` | never dropped |
| `quests.main_quest_id` `q305…q311` | `t01…t06` (q310→t05, q311→t06) | `main_progress` and `main_ready` kept; `q306` progress counted `turtle` kills, now `mossback` (same count) |
| `pending_claim.source_id` `q305…q311` | mapped as above, `claim_id` rewritten (`main:t0x`) | Reward payload kept; `th_weapon_*` inside it mapped like bag items |
| `profile.boss_kills["turtle"/"snailu"]` | added to `mossback` / `shroom` | |
| index-only quest saves (no `main_quest_id`) | legacy shift becomes **+7** (seven tutorial rows now precede `q02`) | same destination quest as before (verified by fixture: index 3 → `q04`) |
| everything else | unchanged | |

New optional save sections: `lost_and_found: []` (shown via a one-time notice) and
`migration_log: []`. The validator accepts both. `lost_and_found` is empty for every current
fixture.

LAN: `PROTOCOL_VERSION` 5 → 6 (monster and item IDs changed).

## 4. Files

`sense/globals/game_content.gd`, `sense/globals/save_service.gd`, `sense/globals/quest_service.gd`
(legacy shift, reward table lookup), `sense/items/item_database.gd`,
`sense/items/reward_box_catalog.gd`, `sense/items/quest_reward_resolver.gd`,
`sense/entities/enemies/monster/monster.gd`, `sense/network/lan_session.gd` (protocol),
`tests/save_fixture_tests.gd`, existing suites that reference `q305…q311`, `snailu`, `turtle`,
`th_weapon_*` (updated to the new IDs; the old-ID cases move into migration tests),
`docs/design/SAVE_MIGRATION_PLAN.md`.

## 5. Tests

| Test | Expectation |
| --- | --- |
| All 13 P0-4 fixtures | load under v6; full-profile assertions unchanged |
| `v5_reference_items` | weapon → `ashwood_blade` equipped, `ironbark_cleaver` in bag, levels kept, compensation logged |
| `v5_quest_q306_progress` | resumes `t02` with progress 0 |
| `v5_pending_claim_q311` | claim completes once as `t06`; duplicate rejected; reload doesn't re-grant |
| `v5_legacy_index_quest` | lands on `q04` |
| New `v5_unknown_reference_item` fixture | item lands in `lost_and_found` |
| Double migration | v6 save migrated again is unchanged |
| New game | full tutorial chain t01→t07→q02 completes in the survival suite |
| LAN | v5 peer rejected by a v6 host with a clear message |
| Gates | static gate: no reference-only IDs in content tables; release gate unchanged (assets handled by P0-5…P0-7) |

## 6. Risks

| Risk | Mitigation |
| --- | --- |
| Old existing test suites assert reference IDs heavily (q305–q311 were built test-first) | Update in the same PR; keep each old assertion as a migration test where meaningful |
| Hidden uses of `turtle`/`snailu` in maps/LAN | grep + gate + LAN harness run |
| Compensation formula feels arbitrary | It's small and logged; owner can change the rate |

## 7. Approval requested 🔒
- New tutorial text, rewards and `mossback` numbers above (approved 2026-11-08); starter weapon stats pending from the owner.
- Save v6 mapping and the `lost_and_found` / `migration_log` sections.
- LAN protocol bump.
