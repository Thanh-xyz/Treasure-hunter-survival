# Logic Progress

## 2026-11-06 — Quest 307 / Equip Three Items

- Inserted stable `q307` after `q306` using source ID 307, exact Vietnamese copy, the existing
  `equipped_count` state objective with count three, and Box 98's one-Diamond reward.
- q307 evaluates existing equipment immediately when q306 is claimed and refreshes through the
  current equipment mutation adapter. No click counter or new gameplay event was added.
- Stable-ID saves still restore by ID. Legacy index-only saves predating all three inserted source
  quests now shift old post-q01 indices by three; save schema remains unchanged.
- Focused chain tests cover two pre-equipped items remaining incomplete, the third completing the
  quest, exact one-Diamond claim, no double grant, q307 -> q02 progression, and legacy migration.
- q308, post-readiness unequip rollback, UI changes, art/assets, equipment rules, LAN schema, and
  new dependencies remain outside this feature.

### Test evidence

- Godot `4.6.stable.official.89cea1439` headless editor import: exit `0`.
- `InventoryTransactionTests.tscn`: exit `0`, all transaction and retry-safety tests passed.
- `SurvivalTests.tscn`: exit `0`, including q306 -> q307 -> q02 ordering, two-versus-three
  equipped-state evaluation, one-Diamond claim, duplicate prevention and legacy index migration.
- `LegacySystemTests.tscn`: exit `0`, phases 1-7 and its Survival/save runner passed. Corrupt-save
  and invalid-snapshot warnings are deliberate negative fixtures.
- `RenderGameMenu.tscn` under Xvfb: exit `0` and saved all four main/claim/daily/complete captures
  under `/tmp/emberfield-quest-menu-*.png`; manual inspection found no clipping, blank reward or
  layout regression. This is a generic presentation regression, not a pixel-parity claim.
- `git diff --check`: exit `0`.
- REVIEW found no high/medium issue, ownership overlap, shared-contract drift or unrelated change.
  The only residual unknown is post-readiness unequip behavior; the existing latch remains explicit.

## 2026-11-06 — Quest 306 / Turtle

- Added stable gameplay monster ID `turtle` for source Card `33`: 100 HP, 20 damage, zero speed,
  `70px` attack range, `200px` target radius, `1.0s` attack gate, no XP/Gold/loot, and knockback
  immunity. One provisional Greenwood spawn makes the approved quest playable offline.
- Added a cached atlas adapter for stable art ID `actor.monster.turtle.default`, preserving all
  21 ordered frame references, repeated attack frame, loop flags, and total clip durations.
- Extended `Monster` with generic atlas rendering and `stationary_melee` behavior while preserving
  existing skeleton/pixel actors and other AI profiles. Death duration and zero-XP handling are
  data-driven.
- Inserted `q306` between `q305` and `q02`, targeting only `turtle` and granting exactly one
  Diamond through the existing retry-safe Box `98` authority. Index-only legacy saves now shift
  across both inserted source quests.
- Added focused catalog/runtime/quest regression coverage and a deterministic Turtle render scene.
  Formal TEST results will be recorded after COOK closes; Godot 4.6 editor import and
  `git diff --check` already pass as implementation preflight.
- No Agent A-owned file, save schema, public quest API, LAN transport schema, loot definition, or
  unverified source lifetime behavior changed.

### Test evidence

- Godot `4.6.stable.official.89cea1439` headless editor import: exit `0`.
- `InventoryTransactionTests.tscn`: exit `0`, all focused transaction tests passed.
- `SurvivalTests.tscn`: exit `0`, including Turtle atlas regions, clip totals, source stats,
  stationary range/cadence, knockback immunity, stable death ID, zero XP, quest targeting,
  one-Diamond claim, no double grant, and save migration.
- `LegacySystemTests.tscn`: exit `0`, phases 1-7 and the Survival/save runner passed.
- Two-process `LanCombatPeerRunner.tscn`: host exit `0`, client exit `0`; authoritative enemy HP,
  removal, range rejection, loot, critical hit, and life steal regression remained intact.
- `RenderTurtle.tscn` under Xvfb: exit `0`; `/tmp/emberfield-turtle.png` is a `360x800` RGBA PNG
  and manual inspection confirms the expected idle Turtle atlas frame is rendered. No pixel-parity
  claim is made because a direct reference runtime capture is unavailable.
- `git diff --check`: exit `0`. Expected negative-save fixture warnings, headless HUD warnings,
  and existing exit-time resource leak warnings remain visible but do not fail the suites.
- TEST initially exposed two fixture issues (an inferred integer type and a physics frame consumed
  before measuring initial cooldown); both were corrected, then the affected suites were rerun to
  successful completion.

### Review closeout

- No high/medium correctness, regression, ownership, fidelity, performance, or validation finding
  remains. The final diff matches the approved Quest 306/Turtle plan.
- Code inspection confirms LAN enemy registration/replication carries `enemy.def_id`, validates it
  against `GameContent.MONSTERS`, and reconstructs replicas with `Monster.create(def_id)`, so the
  stable `turtle` identity needs no transport-schema change.
- Existing pixel/skeleton visuals and melee/flyer/ranged/charger AI keep their prior fallbacks.
  Per-monster atlas construction is cached and occurs only at actor creation, not in gameplay loops.
- Ownership review finds only Agent B gameplay/tests/reports plus the previously approved shared
  runtime files. Agent A's branch is clean and its Quest 320 SCOUT is read-only with no overlap.
- Residual risks are accepted/documented rather than hidden: provisional spawn, inferred local
  collision, equal per-key timing from verified total durations, missing direct Turtle capture,
  and excluded XP/loot/lifetime behavior. The branch is PR-ready.

## 2026-11-06 — Quest 305 Box 149 activation

- Inserted stable runtime quest `q305` after `q01`, matching source quest 305's ten-dig objective,
  Vietnamese copy and Box 149 reward. `q01` is explicitly tagged as source quest 335.
- Added pure quest reward materialization with an injected RNG. Box 149 resolves before pending
  claim preparation; retries and reloads use only the exact journaled card/stat payload.
- Added reward-authority RNG injection for deterministic tests and future host authority while
  preserving randomized offline operation. Failed journal preparation restores RNG state, closing
  an I/O-failure reroll path found during review. Save schema is unchanged.
- Stable-ID saves continue restoring by ID. Legacy index-only saves shift once after q01 so the
  inserted quest does not move existing progress backward.
- Game Menu reads a data-provided reward preview and now shows q305 between q01 and q02 without
  changing quest-card layout or art.
- Godot 4.6 import, Inventory Transaction, Legacy phases 1-7, Survival/save and the Xvfb Game Menu
  render pass. Tests cover exact ten-dig progress, direct/no-RNG rewards, invalid reward specs,
  deterministic Box 149 resolution, full-inventory journal/reload/retry, no reroll and migration.

## 2026-11-06 — Box 149 Common stat generator

- Added a caller-owned deterministic generator and strict recorded-draw replay for the verified
  initial Common path of cards 28/29/30. Draw order is card selection, outer suppression roll,
  suppression indices, then Health/Speed/Damage values.
- Preserved exact thresholds `0..499`, `500..899`, `900..999`, duplicate suppression and the
  card-specific exclusive integer bounds at 0.001 precision. The card-2233 multiplier path is
  intentionally absent.
- Reference payload validation now accepts exact zero-valued suppressed entries while rejecting
  all-zero payloads and continuing to range-check every non-zero stat.
- Box 149 can resolve card plus stats on one caller-owned RNG stream and emits the existing
  canonical exact-equipment reward. The current pending-claim journal persists that result, so
  save recovery retries without rerolling.
- Quest 305, other rarities, runtime combat-stat application, UI, save schema and LAN transport
  remain unchanged. Agent A requires no adaptation.
- Godot 4.6 import, Inventory Transaction, Legacy phases 1-7 and Survival/save pass with exit code
  0. Focused tests cover threshold boundaries, duplicate suppression, all card domains, exclusive
  maxima, 0.001 quantization, invalid input, seeded determinism, materialization and journal retry.

## 2026-11-06 — Box 149 authority boundary

- Added a two-phase equipment reward resolver for verified Box 149 card selection. Recorded rolls
  map exactly as `1-34 -> 28`, `35-67 -> 29`, and `68-100 -> 30`; seeded callers own RNG state.
- Invalid, duplicate, unknown or overflowing option tables are rejected before RNG use. Catalog
  reads return deep copies and Box 149 remains excluded from the direct canonical reward registry.
- Finalization accepts only the selected box card plus exact catalog-valid Health/Damage/Speed and
  verifies that the box ID, recorded roll and card still agree before returning the existing
  canonical equipment reward shape. It does not generate, round or transform stats.
- Quest 305, stat-generation policy, rarity transforms, save schema, UI, combat application, LAN
  transport and Agent A-owned files remain unchanged. Agent A's Mosqui atlas is preserved as the
  integrated base.
- Godot 4.6 import, focused InventoryTransaction, Legacy phases 1-7, Survival/save, four quest-menu
  renders and live/dead HUD renders pass. Blacksmith enumeration remains at 29 public items.
- Review corrected the initial loose card-only handoff by binding finalization to an immutable
  `box_id + roll + card_id` selection record. Modified tuples are rejected before grant.

## 2026-11-06 — Independent CheckBox reward resolution

- Decoded Unity 6 IL2CPP metadata confirms `RandomType.Option = 0` and
  `RandomType.CheckBox = 1`; reference CheckBox definitions use independent whole-number chances
  of 50 or 100.
- Added `RewardBoxResolver.resolve_checkbox(entries, rng)` and
  `resolve_checkbox_rolls(entries, rolls)`. They validate the entire table before RNG use, roll
  every entry independently, merge duplicate currency/item quantities, reject invalid definitions
  and reject integer-overflowing aggregate rewards.
- Seeded replay, exact 50/100 boundaries, no-hit results, additive merges, deep-copy isolation,
  invalid rolls/payloads and overflow are covered in the focused gameplay suite.
- Box 153 is not registered yet: its verified result is Stone_3 x2 plus Stone_6 x2, but those
  source cards still need canonical gameplay and asset identities. Quest, save, LAN, UI and Agent
  A-owned files remain unchanged.
- Godot 4.6 import, focused inventory tests, Legacy + Survival/save suites and Xvfb live/dead HUD
  rendering passed with exit code 0. Corrupt-save warnings are expected negative fixtures.

## 2026-11-06 — Verified currency reward-box catalog

- Added exact source Box IDs 98, 150, 151 and 152 as isolated gameplay content: Diamond 1 and
  Gold 100/200/300, all guaranteed single-entry rewards.
- Catalog reads return deep copies and resolution delegates to the deterministic
  `RewardBoxResolver`; unknown/unmapped boxes return no reward.
- Box 149 is explicitly absent, preventing accidental use before its three Common weapon cards
  have approved gameplay and asset identities.
- Quest definitions, save state, UI, LAN and Agent A files remain unchanged.
- Godot 4.6 import, focused transaction tests, legacy/survival/save suites and Xvfb live/dead HUD
  rendering passed with exit code 0. Tests lock all four source IDs/payloads, deep-copy isolation
  and the deliberate absence of Box 149.

## 2026-11-06 — Deterministic reward box prerequisite

- Added `RewardBoxResolver` for one guaranteed weighted selection using caller-owned seeded RNG.
- Reward entries are rejected unless weights are positive whole numbers and payloads contain only
  non-negative XP/Gold/Diamond values or positive quantities of known item IDs.
- The resolver returns a deep normalized reward compatible with `GameState.grant()` and does not
  mutate inventory, quest state or networking state.
- Godot 4.6 import, focused transaction tests, legacy/survival/save suites and Xvfb live/dead HUD
  rendering passed with exit code 0. Focused tests cover exact 34/33/33 roll boundaries, seeded
  replay, deep-copy isolation and malformed or unknown reward data.
- This feature deliberately does not add box 149 or cards 28/29/30; their three distinct weapon
  identities still depend on the proposed Agent A asset contract.

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

## 2026-11-06 — Active dig tutorial reward

- Runtime `0/1` and active quest ID 335 prove q01 remains a one-dig tutorial; inactive ID 305
  is a separate ten-dig follow-up and is not inserted in this slice.
- Box 150 grants exactly 100 Gold. Q01 now grants that payload instead of the provisional
  30 XP + 50 Gold reward.
- Regression coverage locks the count, reward dictionary, exact Gold delta, absence of XP and
  normal progression to q02.
- No quest ID, UI, asset, save field, LAN protocol or later quest definition changed.

## 2026-11-06 — Reference equipment instance persistence

- Branch: `feature/th-logic-equipment-instance-payload`, based on `origin/develop` at `d322c30`.
- `ItemData` can carry a source card ID, stable art asset ID and exact decimal Health, Damage and
  Speed payload on duplicated equipment instances without applying those values to gameplay.
- Save schema version 3 round-trips the optional payload, migrates versions 0/1/2, rejects
  malformed or non-equipment payloads and preserves catalog-template isolation.
- Godot `4.6.stable.official.89cea1439` import, focused inventory transactions, legacy phases
  1-7, survival/save tests and Xvfb live/dead MobileHUD rendering passed with exit code 0.
- No item ID, quest, reward-box registration, combat formula, UI, LAN protocol, asset manifest or
  Agent A-owned file changed. Box 149 and quest 305 remain unimplemented.

## 2026-11-06 — Reference weapon catalog and exact-payload materializer

- Branch: `feature/th-logic-reference-equipment-catalog`, based on `origin/develop` at `697b8ca`.
- Added stable runtime IDs `th_weapon_28`, `th_weapon_29` and `th_weapon_30` without aliasing any
  existing Emberfield item. Exact names, Common rarity, cost 10 Gold, upgrade rate 1.4 and source
  Health/Damage/Speed ranges come from Card.json.
- `ReferenceEquipmentCatalog.materialize(card_id, stats)` accepts only a complete finite payload
  inside inclusive source ranges and returns an isolated save-compatible equipment instance with
  source card and stable asset metadata.
- Reference templates remain outside the public shop registry, preventing incomplete zero-stat
  content from appearing at the blacksmith. They remain resolvable for save validation/hydration.
- Initial stat RNG, rounding, rarity/tier transforms, combat application, Box 149, quest 305, UI,
  LAN and runtime icon resolution remain excluded because the authoritative rules are not proven.
- Source `canUpgrade`, base cost 10 Gold and rate 1.4 remain catalog evidence; runtime upgrade is
  disabled so the current provisional command cannot charge Gold without affecting reference stats.
- Godot `4.6.stable.official.89cea1439` import, focused inventory/catalog tests, legacy phases
  1-7, survival/save tests and Xvfb live/dead MobileHUD rendering passed with exit code 0. The
  blacksmith render still reports exactly 29 public equipment items, proving no template leak.
  Focused coverage also proves rejected reference upgrades spend no Gold, change no level and emit
  no economy/equipment signal.

## 2026-11-06 — Durable pending quest claims

- Branch: `feature/th-logic-pending-claim-journal`, based on `origin/develop` at `09067fb` before
  the disjoint Turtle asset integration.
- Save schema version 4 persists one canonical resolved claim before reward mutation and migrates
  versions 0-3 with an empty journal.
- Main and daily claims checkpoint pre-grant state, finalize reward plus quest transition in one
  snapshot, and restore the checkpoint when final validation/write fails.
- Load automatically retries the exact saved reward. Stale-date daily state is retained only while
  its dated journal is pending, then resets normally after successful completion.
- Focused coverage passes for full-inventory prepare/reload, final-save rollback, exact retry,
  duplicate prevention, stale daily recovery and invalid journal validation.
- Godot `4.6.stable.official.89cea1439` import, focused inventory transactions, Legacy phases
  1-7, Survival/save validation, four quest-menu renders and live/dead HUD renders passed with
  exit code 0. Negative-path corrupt-save, invalid-snapshot and unknown-shop-item warnings are
  deliberate fixtures.
- Box 149, quest 305, equipment RNG/stat generation, UI, LAN and all Agent A-owned files remain
  excluded.
- REVIEW found no high- or medium-severity issue. `git diff --check` passes and all nine changed
  repository files are gameplay-owned tests/logic or Agent B reports/handoff.
- Residual risks: offline JSON saves are validated but not signed against deliberate local
  tampering, and the journal intentionally serializes one claim at a time.

## 2026-11-06 — Exact equipment reward payload

- Branch: `feature/th-logic-exact-equipment-rewards`, based on `origin/develop` at `8f8ef6d` with
  Agent A's integrated Snailu atlas.
- Canonical rewards now accept bounded exact equipment entries containing only card ID and validated
  reference stats. Runtime item/asset identities remain catalog-derived and templates stay immutable.
- `GameState.grant()` materializes all instances before the existing atomic inventory/currency
  transaction. Save schema v5 lets pending claim journals round-trip and retry exact decimal payloads.
- Focused tests pass for normalization, deep copies, merge behavior, invalid payloads, capacity
  rollback, reload/retry, duplicate prevention, migration and catalog immutability.
- Godot 4.6 import, focused inventory transactions, Legacy phases 1-7, Survival/save, four quest
  menu renders and live/dead HUD renders pass with exit code 0; blacksmith remains at 29 public
  items.
- Box 149, quest 305, RNG/rounding, combat stat application, UI and LAN remain excluded.
- REVIEW found no high/medium issue. `git diff --check` passes; reward identity remains catalog-
  derived, mixed grants are atomic, migrations preserve old saves and the diff has no Agent A file.
