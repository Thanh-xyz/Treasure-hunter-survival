# Gameplay Architecture Proposal

Status: approved as the incremental direction on 2026-11-04. The first implementation slice
adds atomic inventory transactions behind the existing APIs; broader service extraction is
still deferred until reference parity and Agent A contracts are available.

## Goals

- Preserve the current Godot 4.6 project, scenes and public gameplay behavior.
- Make local single-player the authoritative reference implementation.
- Allow the same commands and rules to run under a host-authoritative LAN session later.
- Keep presentation, transport and persistence outside deterministic gameplay rules.
- Introduce changes incrementally behind the existing APIs instead of replacing the vertical
  slice.

## Proposed boundaries

```text
Presentation / Godot scenes
  player.gd, Monster, HUD, menus, field scenes
                 |
                 v
Application services and commands
  attack, use skill, equip, craft, gather, claim quest, respawn
                 |
                 v
Pure domain rules and typed snapshots
  attributes, damage, cooldowns, inventory, recipes, progression, AI decisions
          |                         |
          v                         v
Persistence adapter           Authority adapter
local versioned save          offline / LAN host
                                    |
                                    v
                              ENet transport adapter
```

Offline mode should execute commands locally through the authority interface. LAN clients
should submit the same command DTOs to the host; the host validates and executes them, then
replicates events/snapshots. No rule should depend on ENet RPC annotations.

## Deterministic reward boxes

`RewardBoxResolver` is a pure selection boundary for guaranteed reward containers. Callers pass
an owned `RandomNumberGenerator`; the resolver validates every positive-weight entry and returns
one normalized `xp`/`gold`/`diamonds`/`items` dictionary without mutating quest, inventory or
player state. Application services then commit that result through `GameState.grant()`.

This remains separate from `LootTable`, whose no-drop, repeated-roll and enemy-drop semantics are
different. Offline callers may seed locally; a future LAN host must own the seed/roll and replicate
only the committed outcome. Box/card registries remain content adapters layered above this rule.

`RewardBoxCatalog` is that content adapter for verified source Box IDs. It exposes deep-copied
entries so consumers cannot mutate canonical data. Randomized quest boxes must be materialized and
persisted before `GameState.grant()` retries; otherwise a full inventory could be used to reroll a
reward. Until that boundary exists, the active quest definitions keep their direct rewards.

Treasure Hunter's source enum separates `Option = 0` from `CheckBox = 1`. Option boxes resolve one
relative-weight entry through `resolve()`/`resolve_roll()`. CheckBox boxes evaluate every entry
independently through `resolve_checkbox()`/`resolve_checkbox_rolls()` and merge successful
currency/item quantities into one normalized payload. Both modes validate the complete definition
before consuming caller-owned RNG; neither mode grants or persists the outcome. This preserves the
same offline/host-authoritative boundary and keeps retry-safe materialization as an application/save
responsibility.

## Domain model proposal

Use typed Resources/RefCounted value objects where Godot supports them, with dictionaries only
at serialization and imported-reference boundaries.

| Domain | Proposed responsibility |
| --- | --- |
| `CharacterDefinition` | Stable character ID, base attributes, growth, skills and asset key. |
| `CharacterState` | Current HP/mana-or-stamina, level, XP, state and cooldowns. |
| `AttributeSet` | Base, equipment, buff and derived values with one aggregation path. |
| `CombatResolver` | Validated attack request -> deterministic damage/status events using injected RNG. |
| `MonsterDefinition` | Stable monster ID, stats, AI profile, drops and asset key. |
| `MonsterBrain` | Pure/isolated state transitions and target/attack decisions. |
| `ItemDefinition` | Immutable item identity, category, stack/equipment rules and static modifiers. |
| `ItemInstance` | Unique equipment state: enhancement, augments and durability if confirmed. |
| `InventoryState` | Slots, stacks, equipment slots and atomic transactions. |
| `RecipeDefinition` | Ingredients, requirements and outputs. |
| `CraftingService` | Validate and commit one inventory transaction. |
| `ProgressionService` | XP curve, unlocks, quest progress and rewards. |
| `WorldState` | Resource nodes, bosses, chests, plots and respawn timestamps. |
| `GameSnapshot` | Versioned aggregate for one player plus local world state. |

## Contracts and events

Gameplay should publish small domain events rather than presentation-specific callbacks:

- `character_damaged`, `character_healed`, `character_died`, `character_respawned`
- `attack_started`, `attack_resolved`, `critical_hit`, `status_applied`, `status_expired`
- `monster_spawned`, `monster_state_changed`, `monster_died`
- `item_added`, `item_removed`, `equipment_changed`, `item_enhanced`
- `craft_succeeded`, `craft_failed`
- `xp_gained`, `level_changed`, `quest_progressed`, `quest_completed`
- `world_object_changed`, `zone_changed`

Existing `GameEvent` signals remain adapters during migration. Event payloads need IDs,
quantities and source/target identifiers sufficient for persistence, UI and replication.

## Determinism and authority

- Replace direct `randf`/`randf_range` use in domain calculations with an injected seeded RNG.
- Centralize defense, critical, variance, resistance and status calculations in one resolver.
- Use monotonic command IDs and idempotent inventory/reward transactions.
- Host validates actor ownership, zone, distance, cooldown, resource cost and target state.
- Client visuals may predict wind-up/movement, but HP, loot, crafting, equipment and quest
  rewards are committed by the authority.
- PvP should be a later ruleset using the same resolver with explicit friendly-fire, team,
  respawn and scoring policies.

## Content and evidence pipeline

Keep source evidence outside runtime content definitions:

```text
assets-ths extracted data
        |
        v
read-only analysis/import tool
        |
        v
normalized review artifact + evidence status
        |
        v
approved Godot content definitions
```

Every migrated record should carry an evidence classification:

- `confirmed`: observed directly in config or runtime capture.
- `inferred`: strongly supported by names, scene data or repeated behavior.
- `provisional`: clean-room value used to keep the local game playable.

No static identifier alone should be treated as a formula or cap.

## Persistence proposal

Move from save version 1 to a validated schema only after characterization tests exist.

- Save `schema_version`, `content_version`, player snapshot, inventory/equipment instances,
  quest state and local world state.
- Validate types, bounds, IDs and quantities before applying data.
- Preserve the last known-good backup and verify the newly written JSON before rotating it.
- Add explicit migrations per version and fixtures for corrupt, old and future-version saves.
- Keep LAN client simulation out of the local save; commit only host-approved earned deltas.

## Compatibility approach

1. Add characterization tests around current public methods and signals.
2. Introduce domain services behind adapters used by existing nodes.
3. Move one rule at a time, preserving scene APIs and save compatibility.
4. Remove duplicate rule paths only after equivalent tests pass.
5. Change shared IDs or visual contracts only through an agreed handoff with Agent A.

## Implemented first slice

`InventoryData.transact_items()` now simulates removals and additions before committing one
slot mutation. Crafting, quest rewards and homestead collection use this boundary so a full
inventory cannot consume ingredients, advance a claim or reset stored production. This is an
incremental adapter-compatible step toward `InventoryState`; it does not change item IDs,
equipment contracts, assets, save schema or network transport.

## Implemented resolved-hit slice

Basic player attacks now use an additive compatibility path rather than replacing legacy raw
damage delivery. `HitboxComponent` can resolve one provisional combat roll and emit the result;
`HurtboxComponent` lets the target confirm the amount actually applied. Existing raw damage
signals remain available for systems not yet migrated.

The player supplies aggregated critical chance to the hitbox and consumes confirmed damage for
on-hit passives. LAN clients send bounded combat modifiers in protocol version 5; the host
resolves enemy damage and lifesteal. This establishes the attack-result boundary needed by the
larger `CombatResolver` proposal without moving active skills, projectiles or status effects in
the same feature.

## Implemented equipment-enhancement slice

Equippable `ItemData` now separates immutable catalog configuration from per-instance state.
Catalog templates define whether the item can upgrade, base cost, cost rate and maximum level;
duplicated equipment instances carry the displayed enhancement level and applied augments.

`InventoryData.upgrade_equipment()` is the authoritative command boundary. It accepts only a
stable equipment-slot ID, resolves cost from trusted item data, duplicates the equipped item,
commits the new level and gold balance, then publishes final-state equipment and upgrade events.
Stat aggregation reads scaled base equipment values while augment values remain independent.

Save schema version 2 serializes enhancement levels only when above level 1, migrates versions
0 and 1 to level 1 when the field is absent, and rejects invalid types, bounds and upgrades on
items without a valid enhancement configuration. This keeps local saves ready for a future
host-authoritative command adapter without coupling the rule to transport or presentation.

Treasure Hunter evidence confirms displayed levels 1-10, per-card base cost/rate fields and
state-based upgrade quests. The current Emberfield item IDs have no approved one-to-one card
mapping, so default cost/rate values and the isolated 1.1 stat multiplier remain explicitly
provisional until stronger runtime/server evidence is available.

## Equipment quest objective boundary

Equipment objectives are evaluated from current authoritative inventory state, never from UI
click counts. `InventoryData` exposes read-only aggregate queries for equipped count, minimum
rarity and displayed enhancement level. `QuestService` converts an objective definition into a
current value, and the live `Player` adapter requests a refresh after `equipment_changed`.

The objective vocabulary is:

- `equipped_count`: number of occupied equipment slots.
- `equipped_rarity`: number of equipped items at or above an Emberfield `ItemRarity` target.
- `equipment_level`: number of equipped items at or above a displayed level target.

Reference raw enums must be normalized before entering this vocabulary: `rareRequire` does not
directly equal Emberfield's rarity enum, and `levelRequire` is one lower than the displayed
level in the verified beginner quests. This boundary is transport-independent and can later be
reused by a host-authoritative quest snapshot without coupling quest rules to LAN RPCs.

## Stable quest save identity

Quest snapshots persist both the current `main_quest_id` and the legacy `main_index`. Load
prefers a recognized stable ID so content insertion or reordering does not silently redirect a
profile to another quest. Old snapshots and snapshots whose quest was deliberately removed use
the bounded index as a compatibility fallback. The optional field does not require a save
version bump and keeps current version-0/1/2 migration behavior intact.

## Diamond wallet boundary

Treasure Hunter's authorized `Currency.json` identifies Gold as currency ID 1 and Diamond as
currency ID 2; reward box 98 grants exactly one Diamond. Emberfield therefore models Diamond
as currency rather than an inventory item.

`InventoryData` owns Gold, Diamond and item slots behind one transaction boundary. A mixed
item/Gold/Diamond operation validates capacity and balances first, commits every domain, then
publishes signals so observers cannot see partial state. `GameState` accepts the normalized
reward/cost key `diamonds`, while persistence stores an optional non-negative `diamonds` value.
Older saves default to zero, so save version 2 remains compatible.

This slice is deliberately offline-first. Fixed-HUD presentation and LAN reward replication do
not yet consume Diamond; those require separate UI and protocol plans rather than coupling the
domain wallet to transport or art.

## Key risks

- `player.gd` and `LanSession` are large cross-layer files, so broad refactors would create
  high regression and merge-conflict risk.
- Current content IDs mix legacy placeholders and reference-facing names.
- Validation currently relies on a temporary Godot 4.6 binary path; import, complete gameplay
  suites, HUD rendering and LAN harnesses pass, but CI remains the cross-platform release gate.
- Reference server rules are absent; online parity cannot be claimed from XAPK evidence.
- Source-derived art needs a distribution-rights decision before any public release.

## Reference equipment instance payload

`ItemData` now provides an optional per-instance evidence carrier separate from immutable
catalog configuration. A materialized reference equipment instance can retain its positive
source card ID, stable asset ID and exact `health`/`damage`/`speed` decimal values. Setters copy
and normalize the payload so callers cannot mutate it through a retained dictionary reference.

Save schema version 3 serializes this carrier only when it is complete and valid. Hydration
duplicates the catalog resource even when enhancement level and augments are at their defaults,
which prevents one rolled instance from mutating every item sharing the catalog template.
Versions 0, 1 and 2 migrate additively because the new field is optional.

The payload deliberately does not alter existing attack, health or movement calculations.
Materialization ranges, RNG ownership, rarity effects, display rounding, reward commitment and
LAN replication remain separate features requiring their own evidence and approval.

## Reference equipment catalog boundary

`ReferenceEquipmentCatalog` isolates exact Treasure Hunter card metadata from Emberfield's
existing clean-room items. Cards 28/29/30 map to additive runtime IDs `th_weapon_28`,
`th_weapon_29` and `th_weapon_30`; no existing sword or axe identity is reused.

The templates live in a private `ItemDatabase` registry. `get_item()` and `get_item_copy()` can
resolve them for save validation and hydration, but current shop enumeration over public `items`
does not expose incomplete reference content for purchase. Materialization validates all three
exact stats against inclusive source ranges, copies the matching template and attaches source
card/asset metadata through the existing instance carrier.

The catalog deliberately accepts resolved values instead of owning RNG. A later offline/host
authority can commit exact payloads and replay them without coupling transport, quest claims or
presentation to an unverified random distribution.

Although the source definitions are upgradeable with cost 10 Gold and rate 1.4, the runtime
templates keep upgrade commands disabled in this slice. Enabling the existing provisional upgrade
path before reference stats participate would spend currency without changing the authoritative
payload, so source upgrade metadata remains catalog evidence until a complete rule is approved.

## Durable pending-claim journal

Save schema version 4 owns one optional `pending_claim` record containing a stable claim ID,
source kind, source quest ID and canonical resolved reward. `QuestService` prepares this record
before grant, checkpoints the latest pre-grant state, applies the reward and quest transition,
then clears the journal in the final atomic snapshot.

Loading a valid pending record retries the exact persisted payload. A capacity failure leaves the
journal intact; a final-save failure restores the last pre-grant snapshot in memory. Completion
signals publish only after the final snapshot succeeds, preventing presentation from observing a
claim that persistence rejected.

The journal belongs to persistence while claim orchestration belongs to the quest application
service. It is independent of transport and can later carry an authority-resolved equipment
instance without coupling gameplay rules to ENet. Only one claim may be pending, deliberately
serializing offline mutations until a broader command ledger is justified.

## Exact equipment reward carrier

Canonical rewards may carry `equipment: [{card_id, stats}]`. This representation stores only the
source identity and exact authoritative decimal values; runtime item ID and stable asset ID are
derived from `ReferenceEquipmentCatalog`. Callers cannot provide levels, augments, rarity or asset
aliases through this boundary.

Reward normalization validates every instance and caps the list to inventory capacity. Grant
materializes every equipment object before mutation, then commits equipment, ordinary items and
currencies through the existing single inventory transaction before applying XP. A pending claim
therefore persists and retries the same exact instances without coupling reward logic to save-item
serialization or to a network transport.

## Reference equipment reward authority

Equipment box selection is a separate phase from exact instance creation.
`ReferenceEquipmentRewardResolver` validates immutable weighted card options and supports either a
caller-owned RNG or a recorded 1-based roll. It returns a selection record containing the roll and
source card ID; it never derives stats from the card's min/max ranges.

An offline authority or future LAN host must then provide exact stats for that card. Finalization
validates the payload through `ReferenceEquipmentCatalog` and emits the existing canonical
`equipment: [{card_id, stats}]` reward. Only the finalized payload is eligible for pending-claim
journaling and grant, so retries never reroll either the card or its stats.

`RewardBoxCatalog` keeps these equipment options outside its direct canonical reward registry.
This prevents callers from resolving Box 149 through the ordinary reward API before an exact stat
authority exists, while preserving the source `34/33/33` selection evidence for offline and later
host-authoritative consumers.

## Box 149 Common stat authority

`ReferenceEquipmentStatGenerator` implements only the verified initial Common path for cards
28/29/30. It accepts a caller-owned `RandomNumberGenerator`, preserving deterministic offline
replay and future host authority while retaining the reference draw order and exact integer
domains. A separate replay API validates a recorded draw sequence before creating any payload.

The adaptation intentionally does not recreate the reference client's multiple time-seeded
`System.Random` instances because their timing correlations are neither stable nor suitable for
save recovery or LAN authority. The gameplay contract is the verified draw domain/order and the
committed result, not wall-clock seeding behavior.

Suppressed stats remain present as `0.0`. Catalog validation requires all three keys, at least one
non-zero stat, and source-range validity for each non-zero value. The canonical reward and pending
claim therefore retain the exact generated dictionary, so capacity failures and restarts retry the
same equipment instead of consuming RNG again.
