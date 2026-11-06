# Logic Progress

Date: 2026-11-04
Current stage: REVIEW complete for the first approved gameplay feature.

## Completed workflow

- SCOUT and BRAINSTORM established the Godot 4.6 architecture, current migration coverage,
  reference evidence, shared-file risks and offline-first direction.
- PLAN selected inventory/reward integrity as the first independent vertical slice because it
  does not require the missing Agent A asset contract.
- COOK added one atomic item transaction boundary and migrated crafting, quest claim and
  homestead collection to it.
- TEST added focused headless coverage plus regression assertions in the existing runners.
- REVIEW inspected the complete diff, call sites, Agent A branch and remote state.

## Gameplay changes

- `InventoryData.transact_items()` simulates all removals/additions and commits only when every
  output fits.
- Crafting now returns failure without consuming ingredients and emits no crafted event when
  the output cannot fit.
- Quest claims now advance only after the complete reward is accepted; XP and gold are not
  partially granted on item-capacity failure.
- Building collection now preserves `last_collect` and pending production when inventory is
  full.
- No asset, scene, content-ID, save-schema, networking or Agent A-owned file changed.

## Test evidence

Executed with Godot `4.6.stable.official.89cea1439` downloaded to a temporary directory:

```text
/tmp/th-godot-ISNBhK/Godot_v4.6-stable_linux.x86_64 --headless --path . \
  res://tests/InventoryTransactionTests.tscn
```

Result: exit code 0, `[INVENTORY TRANSACTION TEST] ALL PASSED`.

The focused suite verifies rollback and success paths for raw inventory transactions,
crafting, quest rewards and building production. The complete `LegacySystemTests.tscn` run
reached all legacy phases, but the survival runner could not compile because
`sense/entities/player/player.tscn` references missing soldier PNGs. Missing item-icon imports
also produce existing warnings; neither issue was introduced by this feature.

## Integration status

- Feature branch: `feature/th-logic-inventory-transactions`, based on `origin/main` at
  `e8fc3c7`.
- No dedicated origin integration/development branch was found.
- Agent A remains clean at `e8fc3c7` with no unique commit, so no current file overlap exists.
- `gh auth status` is valid for `Thanh-xyz`; no open PR or issue was returned.
- No commit, push, PR or merge has been performed yet.

## Outstanding risks

1. Root `AGENTS.md`, `.agents/skills`, shared coordination directory and Agent A handoff are
   still absent.
2. The full gameplay test suite remains blocked by missing tracked player sprite resources.
3. Upgrading a building with pending production still ignores a failed auto-collection; the
   stored timestamp is preserved, but the later rate calculation can over-credit production.
4. The UI currently treats failed quest/building collection as a generic false/zero result and
   needs an approved UX message contract.
5. No Android device/emulator is connected for reference runtime comparison.

## Recommended next feature

Restore the executable baseline by resolving or formally stubbing the missing player sprite
resources in coordination with Agent A. After that, build the first reference-parity slice:
Mosqui/Snailu/Astromophy field combat, loot and inventory, using approved canonical IDs and
asset metadata.

## 2026-11-04 — Building upgrade integrity

- Branch: `feature/th-logic-building-upgrade-integrity`, based on `origin/develop` at
  `efc07ce`.
- Producer upgrades now require pending output to be collected successfully before cost is
  spent or level is changed.
- A full inventory preserves building level, production timestamp, gold, and material cost.
- After capacity is available, pending output is collected at the old building rate and the
  upgrade charges exactly once.
- Godot 4.6 focused transaction tests, legacy phases 1–7, and survival tests passed with exit
  code 0. The corrupt-save warning remains an intentional recovery test.
- No asset, ID, scene, save schema, networking contract, or Agent A-owned file changed.

## 2026-11-04 — Atomic economy transactions

- Branch: `feature/th-logic-atomic-economy`, based on `origin/develop` at `b7e907b`.
- `InventoryData.transact()` now commits item slots and gold as one validated mutation while
  preserving `transact_items()` as a compatible wrapper.
- `GameState.spend()` rejects unknown item IDs and rolls back the entire mixed gold/item cost
  when any requirement is invalid or insufficient.
- `GameState.grant()` now commits gold and item rewards together before applying XP.
- Focused tests verify rollback emits no signals and a successful mixed transaction emits one
  final-state signal for gold and inventory.
- Focused, legacy phases 1–7, and survival suites passed with Godot 4.6 and exit code 0.

## 2026-11-04 — Inventory removal integrity

- `remove_item()` now rejects non-positive or insufficient quantities without partial removal
  and reuses the atomic inventory transaction path.
- `remove_item_at()` rejects non-positive or oversized quantities before changing the slot.
- Regression tests verify invalid removals preserve stack counts, emit no signals, and cannot
  increase a stack through a negative quantity.
- Valid removal paths still consume exactly the requested amount and emit one inventory signal.
- Focused, legacy phases 1–7, and survival suites passed with Godot 4.6 and exit code 0.

## 2026-11-04 — Save validation and recovery integrity

- Branch: `feature/th-logic-save-validation`, updated to `origin/develop` after Agent A PR #8.
- Save snapshots and temporary files are validated before any live-state mutation or backup
  rotation. Future versions, malformed nested profile/quest state, invalid inventory stacks,
  incompatible equipment and invalid augments are rejected.
- Version `0` snapshots using the current shape migrate to version `1`; versions newer than the
  runtime are rejected so unsupported data is never silently downgraded.
- Direct inventory hydration validates the complete payload before mutating gold, slots or
  equipment. Invalid payloads preserve the existing inventory and emit no change signals.
- A corrupt primary save is replaced without rotating over the last known-good backup. If the
  final temporary-file rename fails after a valid primary was preserved, the backup is restored.
- `git diff --check`, `InventoryTransactionTests.tscn`, and `LegacySystemTests.tscn` all passed
  with Godot `4.6.stable.official.89cea1439`; legacy phases 1–7 and the survival runner passed.
- Expected warnings cover intentionally corrupt/future/invalid saves and backup fallback. No
  asset ID, scene, presentation, networking or Agent A-owned file changed.

## 2026-11-04 — Authoritative shop transactions

- Branch: `feature/th-logic-shop-transactions`, based on `origin/develop` at `860d910`.
- Shop purchases now resolve price and display name from the authoritative `ItemDatabase`
  record instead of trusting the UI payload. Unknown items and records without a positive
  catalog price are rejected.
- Item capacity and gold payment commit through one `InventoryData.transact()` call. A full
  inventory or insufficient gold leaves both domains unchanged, and signals observe only the
  final combined state.
- Focused tests cover a negative spoofed price, full inventory, insufficient gold, unknown
  item, non-sale item, exact charge and final-state signal visibility.
- `git diff --check`, focused inventory tests, legacy phases 1–7 and survival tests passed with
  Godot 4.6 and exit code 0. No asset, UI scene, gameplay ID or networking contract changed.

## 2026-11-05 — Equipment and augment transaction integrity

- Branch: `feature/th-logic-equipment-transactions`, based on `origin/develop` at `d6e9d9b`.
- Unequip now simulates inventory placement or a compatible target-slot swap before committing
  equipment and inventory together. Full inventory failure preserves equipment and emits no
  state-change signal.
- Augment apply/remove now operate on simulated inventory slots and duplicated equipment
  instances, then publish the final state once. Failed removal on a full inventory keeps the
  augment attached; successful operations emit one inventory, equipment and augment signal.
- Focused tests cover rollback, final-state signal visibility, duplicate-signal prevention,
  target-slot equipment swap and full-inventory augment removal.
- `git diff --check`, focused inventory tests, legacy phases 1–7 and survival tests passed with
  Godot `4.6.stable.official.89cea1439`, exit code 0. No asset, UI, ID, save schema or network
  contract changed.

## 2026-11-05 — Reference-evidenced recipe catalog validation

- Runtime/config research confirmed that Treasure Hunter has forge crafting, ingredient
  inputs, equipment/potion outputs, tiered results and craft-specific quests. The exact ten
  Emberfield recipe IDs, quantities and balance values are not yet mapped from the reference.
- Every current recipe is now explicitly marked `PROVISIONAL` with a source note instead of
  being presented as a confirmed Treasure Hunter formula.
- Recipe registration validates non-empty IDs/names/evidence, unique positive tiers, valid
  ingredient/output item IDs, unique ingredients and positive quantities before catalog
  mutation. Duplicate recipe IDs cannot overwrite an existing definition.
- Godot `4.6.stable.official.89cea1439` import, focused inventory transactions, legacy phases
  1–7 and survival suites passed with exit code 0.
- No recipe/item ID, recipe formula, save schema, LAN contract, scene, UI or asset changed.
  Equipment enhancement remains a separately proposed feature because it requires an approved
  persisted item-instance/save contract.

## 2026-11-05 — Authoritative resolved basic combat hits

- Reference configs confirm separate Critical (`statType=5`), Critical Bonus (`statType=14`)
  and LifeSteal (`statType=18`) concepts. Native identifiers expose distinct
  `RpcCriticalDamage`, `RpcCriticalBonusDamage` and `RpcLifeSteal` paths. Exact server formulas
  are unavailable, so Emberfield's existing 8% base chance, 1.6 multiplier and variance remain
  explicitly provisional.
- Player melee now resolves variance and critical chance once before target delivery. Monsters
  and skeletons confirm the amount actually removed; rejected iframe hits and LAN replicas do
  not publish false on-hit events.
- Critical augments now add their existing percentage-point values to the melee roll.
  Lifesteal aggregates equipped effects and heals from confirmed damage rather than raw attack.
- LAN protocol version 5 includes bounded critical and lifesteal modifiers. The host still
  validates peer/zone/range/cooldown/death, resolves the hit, applies overkill-safe damage, then
  commits authoritative lifesteal HP.
- Godot 4.6 import, inventory transactions, legacy phases 1-7, survival tests, MobileHUD render,
  and all three two-process LAN harnesses passed with exit code 0.
- Active skills, hero projectiles, pets and Critical Bonus damage remain separate follow-up
  slices; this feature does not claim their formulas or complete reference parity.

## 2026-11-05 — Persisted equipment enhancement

- Branch: `feature/th-logic-equipment-enhancement`, based on `origin/develop` at `dbc26c9`.
- Verified reference evidence includes displayed level 1 with maximum 10, an Upgrade action,
  664 upgradeable card records with `upgradeCost`/`upgradeLevelRate`, and quest type 39 goals
  for equipment at levels 2, 3 and 5.
- `ItemData` now stores enhancement configuration separately from instance level. Upgrade and
  augment operations duplicate the equipment, preserve both augments and level, and never
  mutate the `ItemDatabase` template.
- `InventoryData.upgrade_equipment()` validates slot, configuration, level, cost and gold,
  commits final item/gold state, refreshes character stats through `equipment_changed`, and
  emits `equipment_upgraded(slot_type, item_id, level, cost)` for quest/UI adapters.
- Save schema version 2 round-trips enhanced equipment, migrates v0/v1 equipment to level 1,
  and rejects zero, over-cap, fractional, string and non-upgradeable enhancement payloads.
- Tooltip text reads the displayed level and scaled base stats without adding assets or changing
  layout. A full Treasure Hunter equipment-detail upgrade panel remains Agent A presentation work.
- Godot `4.6.stable.official.89cea1439` import, focused inventory tests, legacy phases 1-7,
  survival/save tests, Xvfb live/dead MobileHUD render and all three two-process LAN harnesses
  passed with exit code 0.
- The default base cost 10, rate 1.4 and isolated 1.1 stat growth are provisional because the
  current Emberfield IDs are not yet mapped to exact reference card IDs. No exact numeric parity
  claim is made.

## 2026-11-06 — State-based equipment quest objectives

- Branch: `feature/th-logic-equipment-quest-objectives`, based on `origin/develop` at
  `acb97f3`.
- Authorized reference quests 307, 308, 311, 312, 314 and 315 confirm that beginner equipment
  goals are current-state checks for equipped count, rarity and displayed enhancement level.
- `InventoryData` now exposes aggregate equipped-count, minimum-rarity and minimum-level
  queries over the existing seven stable slots.
- `QuestService` evaluates `equipped_count`, `equipped_rarity` and `equipment_level` without
  accumulating clicks. `Player` refreshes the active state objective after successful equipment
  mutation, including equip, unequip, augment replacement, upgrade and save hydration signals.
- The current quest chain, quest IDs, rewards, save schema, monster IDs, LAN protocol and Agent
  A's now-integrated `mobile_hud.gd` feature are unchanged by this logic slice. Full reference-chain migration remains
  blocked on a canonical Turtle mapping and a quest save migration away from index-only meaning.
- Godot 4.6 headless import, focused inventory transactions, legacy phases 1-7 and survival/save
  tests passed with exit code 0. Expected negative-path warnings remain visible in the existing
  shop/save tests.

## 2026-11-06 — Stable main-quest save identity

- Branch: `feature/th-logic-stable-quest-save`, based on `origin/develop` at `e947ec0`.
- Quest snapshots now include optional `main_quest_id` alongside the legacy `main_index`.
  Recognized IDs take precedence on load; legacy or removed-ID snapshots fall back to the
  bounded index.
- Save validation rejects non-string IDs before live-state mutation. The field is additive, so
  save version 2 and existing version 0/1 migrations remain compatible.
- Focused tests cover roundtrip ID persistence, stale-index precedence, legacy fallback,
  removed-ID fallback and malformed-ID recovery through the known-good backup.
- No quest definition, objective, reward, HUD, monster ID, asset, LAN protocol or art-owned file
  changed. This prepares an index-safe future migration to the verified reference chain.

## 2026-11-06 — Treasure Hunter Diamond wallet

- Branch: `feature/th-logic-diamond-wallet`, based on `origin/develop` at `d5c1a57`.
- Direct reference data confirms Gold (`Currency.json` ID 1), Diamond (ID 2), and reward box 98
  as exactly one Diamond. Diamond is implemented as currency, not an inventory item.
- `InventoryData.transact()` now atomically commits item slots, Gold and Diamond before emitting
  `gold_changed`, `diamonds_changed` or `inventory_changed`. Existing three-argument callers
  remain source-compatible.
- `GameState` supports `diamonds` in affordability, spending, grants and cost formatting.
  Failed mixed rewards/costs preserve every domain.
- Save version 2 persists optional non-negative `diamonds`; old saves default to zero and
  malformed Diamond balances are rejected before live-state mutation.
- Godot 4.6 import, focused transaction tests, legacy phases 1-7, survival/save tests and Xvfb
  live/dead MobileHUD render passed with exit code 0.
- UI display, quest-content insertion and LAN Diamond reward replication are intentionally
  excluded and require separate presentation/content/protocol features.
