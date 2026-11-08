# Save Migration Plan

- Stage: BRAINSTORM · 2026-11-07
- Current format: `user://saves/…` JSON, `SAVE_VERSION = 5`, atomic write with `.bak`,
  `SaveService._migrate()` chain (v0→v5), strict `_validate_snapshot()` requiring
  `version == SAVE_VERSION`.

## 1. Audit of the v5 format

```text
{
  version: 5, saved_at,
  profile:  GameState.to_dict() → level, xp, hero_id, heroes{id:stars}, pets{id:level},
            active_pet, mounts{id:{skin, skins[]}}, active_mount, plots[], boss_kills,
            kills_total, current_zone, settings, (+ gold/diamonds via inventory)
  quests:   main_index, main_quest_id, main_progress, main_ready, dailies, daily_date
  inventory: slots[32] {id, qty, level?, augments[]?, reference{card_id, asset_id, stats}?},
             equipment{helmet, armor, weapon, shield, boots, accessory_1, accessory_2}, gold, diamonds
  hp, pending_claim {version:1, claim_id, source_kind: main|daily, source_id: quest id,
                     reward: resolved reward — may contain reference equipment}
}
```

Reference-derived identifiers that can exist in real saves:

| Location | Identifier | Origin |
| --- | --- | --- |
| inventory/equipment `id` | `th_weapon_28`, `th_weapon_29`, `th_weapon_30` | reference cards |
| item `reference` block | `card_id`, `asset_id`, exact stats | reference |
| `quests.main_quest_id` | `q305`, `q306`, `q307`, `q308`, `q310`, `q311` | reference quest IDs |
| `pending_claim` | `source_id` q305–q311; reward payload may hold `th_weapon_*` | reference quests/boxes (box IDs themselves are resolved before saving) |
| kill/quest counters | monster IDs `snailu`, `turtle` | reference monsters |
| `profile.current_zone` | unaffected | — |

Original IDs (kept): all `ItemDatabase` items, `slime`/`shroom`/`boar`/skeleton monsters, q01–q15,
dailies, heroes, pets, mounts, buildings.

## 2. Principles

1. **Never silently discard.** Anything that can't be mapped goes into a **Lost & Found** stash
   (new save section, delivered through a mail-style UI with an explanation).
2. **Forward-only, chained, one version per feature** so every step is small and testable.
3. **Keep the backup.** Before the first migration to a new version, write
   `save.v<old>.bak` and keep it until a later successful load.
4. **IDs are stable.** Display names may change; IDs change only through this plan.
5. **Validation after every step**, using the step's own schema.

## 3. Version plan

| Version | Feature (roadmap) | Migration |
| --- | --- | --- |
| **v6** | P0 content retirement | See §4 |
| v7 | P1-3b / P1-6 overworld + world state (later extended by P5) | Add `world{seed, clock, chunks{"x,y":{breaks, nodes, chests}}, fog, keys, maps}` with fresh defaults; `profile.current_zone` `greenwood` → `overworld` at a Normal-ring spawn beacon, `frostvale` → `overworld` at a Snow-ring beacon (or the Normal centre if the player is under-levelled); add `profile.position` |
| v8 | P2-1 item instances + material pouch + storage + new slots | Move material-category stacks from bag to pouch; add `uid` to every equipment instance; convert `level` → `enhance` (level 1 → +0, level n → +(n−1)); add empty `gloves`, `cloak`; `diamonds` → `embers` 1:1 |
| v9 | P2-8 runes generalised | `augments[]` on items → rune instances socketed in the same item |
| v10 | P6-1 / P7-1 homestead grid + pet/mount instances | `plots[i]` → building at fixed grid cell with the same type/level; `pets{id:level}` → instances with that level, Common rarity, 1★; `mounts` → instances keeping skin lists |
| later | as needed | — |

Version numbers follow merge order in [ROADMAP.md](ROADMAP.md). If the order changes, numbers are
reassigned before implementation (never after a version ships). Each version bump comes with the
feature's PLAN approval (directive §10).

## 4. v6 — content retirement mapping

| Old | New | Rule |
| --- | --- | --- |
| `th_weapon_28` | `ashwood_blade` (Common sword, original) | Keep the enhancement level. Drop the `reference` block. Compensation: if the old rolled damage exceeds the new template's max, grant the difference as gold at 10 gold/point (logged) |
| `th_weapon_29` | `ironbark_cleaver` (Uncommon axe) | same rule |
| `th_weapon_30` | `cinder_edge` (Rare sword) | same rule |
| any other id with a `reference` block | Lost & Found + gold compensation by rarity | never dropped |
| `main_quest_id: q305` | `t01` | progress carries over (same objective type: dig) |
| `q306` | `t02` | kill objective: `turtle` → `mossback`; progress carries over |
| `q307` | `t03` | equipped count |
| `q308` | `t04` | equipment enhance level ≥ +1 (old display level 2) |
| `q310` | `t05` | kill objective: `snailu` → `shroom` (Bramble Snail) |
| `q311` | `t06` | equip Uncommon or better (rule relaxed from Rare to match the new Uncommon tier) |
| `pending_claim` (v1 record: `claim_id`, `source_kind`, `source_id`, already-resolved `reward`) | `source_id` q305–q311 → t01–t06; reward kept as is, except `th_weapon_*` equipment inside the reward, which maps like the inventory rows above | the journalled claim still completes exactly once |
| monster counters `snailu`, `turtle` | added to `shroom`, `mossback` | — |
| legacy index-only quest saves | existing "+6 shift" logic kept, then the ID map applies | — |

Fallback: unknown quest ID → main chain restarts at the first unclaimed quest the player's
counters don't already satisfy; a toast explains it.

## 5. Tests (each version)

Golden fixtures in `tests/fixtures/saves/`:

| Fixture | Checks |
| --- | --- |
| `v1_minimal.json` … `v5_full.json` (hand-built, original content) | chain migrates to latest; validates |
| `v5_reference_items.json` | `th_weapon_*` mapped, enhancement kept, compensation logged, no loss |
| `v5_reference_quest_q306_progress.json` | lands on `t02` with progress |
| `v5_pending_claim_q311.json` | claim with `source_id: q311` completes exactly once as `t06` after migration |
| `v5_unknown_items.json` | items appear in Lost & Found |
| `latest_new_game.json` | a new game saves and reloads byte-stable (except timestamps) |
| corrupted / truncated / future-version files | fall back to `.bak`; never overwrite a good backup |
| double-migration | migrating an already-migrated save is a no-op |

Plus a round-trip property test: random valid v-latest snapshot → save → load → equal.

## 6. LAN protocol

Each content-ID change bumps `LanSession.PROTOCOL_VERSION` and adds the content hash to the
handshake, so peers with different builds can't join each other.
