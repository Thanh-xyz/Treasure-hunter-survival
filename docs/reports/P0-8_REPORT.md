# P0-8 + E3/E4 — Reference Retirement, 5-Slot Equipment, Save v6

- Stages: IMPLEMENT → TEST → REVIEW · 2026-11-08
- Plans: [P0-8_SAVE_V6_PLAN.md](../plans/P0-8_SAVE_V6_PLAN.md) (🔒 approved),
  [EQUIPMENT_SYSTEM_PROPOSAL.md](../plans/EQUIPMENT_SYSTEM_PROPOSAL.md) (approved with owner decisions)
- Branch: `feature/p0-8-save-v6` (from `feature/equipment-system`)

## What changed

### Equipment (E3)
- `InventoryData`: 5 slots `helmet, armor, boots, weapon, back`; shield/accessory slots removed.
  Equipment speed is capped by `max_equipment_move_speed`; augment/stone speed is not.
- `ItemData`: new `BACK` type (appended, enum values unchanged), `equipment_line`, `icon_asset_id`.
  Items with a line take HP/ATK/speed from `EquipmentBalance` at their level; base equipment has
  no DEF (stones provide it). Reference-card instance data removed.
- `ItemDatabase`: the 29 legacy equipment items and the 3 reference weapons are gone; equipment
  comes from `data/equipment/templates.json` (15 base + `emberforged_blade` Rare).
- Loot tables, starter items, skeleton drop, quest q08 reward, smith shop categories, skill slot
  map (back → Q interim), inventory/detail/augment/crafting stat displays updated.

### Content (P0-8)
- Tutorial `q305–q311` (copied IDs and text) → original `t01–t07`; `q01` text rewritten.
- Monsters: display names Gnatling / Bramble Snail / Bristle Boar; excluded textures dropped (the
  original PixelArt sprites are used); `snailu`/`turtle` rows retired; new `mossback` guard.
- Rewards: numeric Box IDs → string tables (`starter_weapon`, `diamond_1`, `mossback_bounty`,
  `gold_200`, `smith_kit`); the `equipment` reward kind is removed (equipment is an item reward).
- Deleted code: `reference_equipment_catalog.gd`, `…_stat_generator.gd`, `…_reward_resolver.gd`;
  `MonsterVisualCatalog` atlas definitions emptied; `reference_melee` → `timed_melee`.
- LAN `PROTOCOL_VERSION` 5 → 6.

### Save v6 (E4)
| v5 data | v6 result |
| --- | --- |
| Retired equipment (bag or equipped, any slot) | removed; sell value refunded as gold; socketed augments returned to the bag |
| `th_weapon_28/29/30` | `ashwood_blade` / `ironbark_cleaver` / `ember_dirk`, level kept; damage above the new weapon's attack refunded at 10 gold/point |
| Unknown item IDs | moved to `lost_and_found` |
| `main_quest_id` `q305…q311` | `t01…t06`, progress kept |
| Pending claim from q305–q311 | `source_id`/`claim_id` remapped; reward cards → starter weapons; retired items in rewards → gold |
| `boss_kills` `turtle`/`snailu` | added to `mossback`/`shroom` |
| Index-only quest saves | shift +7 (same destination quest) |
| Every change | recorded in `migration_log` |

Bag overflow during migration goes to `lost_and_found`. Both new sections are saved, validated
and reloaded.

## Test evidence

`tools/run_tests.sh`: **18/18 PASS** (Godot 4.6.stable.official.89cea1439, `user://` isolated).

| Suite | Notes |
| --- | --- |
| SaveFixtureTests | v0–v5 fixtures migrate: gold 1234 → 1874 (refunds), augment returned, no equipment left, quest q03 kept; reference weapons mapped with compensation; q306 → t02; q311 claim completes once as t06; index save → q04; unknown item → Lost & Found; migration idempotent; backup fallback; mount regression |
| SurvivalTests | full chain q01 → t01…t07 → q02 with exact rewards and no double claims; Mossback runtime; save round trip with an enhanced new weapon |
| InventoryTransactionTests | reference-only tests removed; t01 journalled claim (full bag, reload, retry, no duplicate); reward tables |
| LegacySystemTests | phases 1–7 pass with 0 script errors (one assertion that silently failed was fixed) |
| EquipmentSystemTests, ArtCatalogTests, ProvenanceTests, LAN ×3 | pass |

Renders reviewed: equipment detail (Emberforged Blade: HP +101, ATK +20, SPD +3) and the field
(Gnatling, Bramble Snail, Bristle Boar labels).

## Review findings fixed during this stage
- Item stat displays read raw template fields (0 for formula items) → all four UIs use computed
  stats.
- Legacy suite's `assert` doesn't stop the run in headless mode, so a failing check printed "ALL
  PASSED"; the failing check was fixed. Recommend converting that suite to `_check()` style later.

## Remaining / follow-ups
- 4 excluded field-prop images (`world_props.gd`) — to be replaced with free licensed assets
  (owner instruction 2026-11-08: use free online assets, no more self-made art).
- Drops roll only template rarity; rarity rolls on drops need an instance-rarity save field.
- One-time in-game notice for `migration_log` / `lost_and_found` is not built yet.
- E5 inventory screen (5 slots around the hero, comparison card).
- The legacy inventory scene reuses its shield placeholder for Back; accessory placeholders hidden.
