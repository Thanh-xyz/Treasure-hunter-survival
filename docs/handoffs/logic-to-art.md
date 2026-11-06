# Logic-to-Art Contract Proposal

## 2026-11-06 — Quest 308 / Upgrade One Equipment To Level 2

- Gameplay exposes q308 through the unchanged generic quest contract with Vietnamese `Nâng cấp
  trang bị`, progress `0/1` through `1/1`, and reward preview `200 Vàng`.
- Progress is current equipped state: any equipped item at displayed Level 2 or above counts.
  Presentation must continue invoking `InventoryData.upgrade_equipment(slot_type)` and reading final
  quest/equipment/Gold state; it must not increment quest progress or compute a separate reward.
- No icon, asset ID, animation, equipment slot, layout, effect, modal callback or upgrade formula
  changed. Agent A requires no implementation work.
- Import, gameplay/save suites, Equipment Detail functional render and all four generic quest-menu
  render states pass. Manual inspection found no presentation regression.
- Q310/Snailu and any exact reference-equipment upgrade presentation remain separately staged.

## 2026-11-06 — Quest 307 / Equip Three Items

- Gameplay now exposes q307 through the unchanged generic quest contract with Vietnamese
  `Mặc trang bị`, objective progress `0/3` through `3/3`, and reward preview `1 Kim cương`.
- Progress is authoritative current equipment state. Presentation must read `QuestService` and
  must not count equip button presses or infer slot state independently.
- No icon, equipment art, asset ID, animation, direction, layout, equipment-slot identifier, or
  UI callback changed. Agent A requires no implementation work.
- Import, focused transactions, Legacy/Survival/save and all four generic quest-menu render states
  pass. Manual render inspection found no presentation regression.
- q308 and any new equipment-upgrade presentation remain separately staged.

## 2026-11-06 — Quest 306 / Turtle

- Gameplay now consumes stable art ID `actor.monster.turtle.default` for monster ID `turtle`.
  Canonical animation names are exactly `idle`, `move`, `attack`, and `death`; no directional
  suffix is required.
- The runtime adapter uses the existing `64x64` top-to-bottom atlas rows and the approved frame
  order/durations. It does not modify the atlas, import metadata, manifest, PPU, pivot, or icon.
- Turtle is stationary and knockback-immune. Gameplay starts `attack` when the verified logical
  `1.0s` gate opens and starts `death` on zero HP. There is no new hit-frame event or art callback.
- Quest/UI may display `Đánh bại Turtle`, `Đánh bại Rùa`, and `1 Kim cương`. Reward selection and
  granting remain gameplay authority; presentation must not synthesize another Turtle identity or
  reroll Box `98`.
- The Greenwood spawn is provisional because source coordinates are unavailable. No art-side
  change is requested; later collision/pivot or spawn parity evidence must be proposed as a new
  shared contract rather than silently changing this slice.

## 2026-11-06 — Quest 305 Box 149 activation

- Main quest `q305` now appears after `q01` with progress `0/10` and an explicit preview string
  `1 trang bị Common`. Its claim is resolved and journaled entirely by gameplay authority.
- Game Menu only reads `reward_preview`; it does not choose a card, generate stats or inspect Box
  149 internals. Presentation must continue showing the committed instance after claim rather than
  rerolling or substituting a fixed card.
- The only presentation edit is the small reward-text fallback in `game_menu.gd`. No layout,
  texture, asset ID, rarity field, equipment-detail panel or Agent A-owned file changed.
- Quest 306, a dedicated reward popup and exact reference reward-icon composition remain deferred.

## 2026-11-06 — Box 149 Common stat generator

- Gameplay now owns deterministic initial Common stat generation for source cards 28/29/30 and
  emits the existing exact-equipment reward payload. Suppressed stats remain present as `0.0`.
- Reward presentation must read the committed materialized instance and must not independently
  choose the card, reroll stats, remove zero entries or derive display values from source ranges.
- No asset ID, item ID, rarity enum, equipment slot, animation, direction, texture, scene or UI
  callback changed. Agent A requires no implementation change for this feature.
- Quest 305 activation and reference-stat UI formatting remain deferred and require their own
  evidence-backed plans.

Status: proposed by Agent B during SCOUT. Agent A agreement is required before implementation.

## 2026-11-04 Agent B update

The first gameplay feature (`feature/th-logic-inventory-transactions`) changes only inventory,
crafting, quest/building reward logic and tests. It does not change any asset key, gameplay ID,
animation state, direction, sprite path, scene or Agent A-owned file.

After a complete Godot import, the tracked player sprites and item atlas resolve correctly.
The focused, legacy, and survival suites now pass. Agent B still will not modify player visuals
or provide substitute art independently.

## 2026-11-04 Building upgrade integrity update

The follow-up gameplay feature changes only `GameState.build_or_upgrade()` and gameplay tests.
It requires pending producer output to fit before an upgrade can spend resources or change
level. It introduces no art dependency or shared runtime contract and does not overlap Agent
A's `feature/th-art-reference-ui-kit` asset files.

## 2026-11-04 Atomic economy update

The economy follow-up extends the existing inventory transaction boundary to include gold and
migrates `GameState.spend()`/`grant()`. It changes no presentation, asset, scene, gameplay ID,
animation, save, or networking contract and remains disjoint from Agent A's UI kit work.

## 2026-11-04 Inventory removal update

Inventory removal now enforces positive, fully available quantities before mutation. The
feature changes only gameplay code/tests and has no overlap with Agent A PR #8 or its UI asset
manifest changes.

## 2026-11-04 Save validation update

Save/load now validates versioned profile, quest, inventory, equipment and augment payloads
before mutating runtime state or rotating the last known-good backup. The feature changes
`sense/globals/save_service.gd`, gameplay tests, and Agent B-owned reports only. It introduces
no asset key, gameplay ID, scene, animation, direction, UI or networking contract. Agent A PR
#8 is already integrated into `develop`; its additive reference UI files remain disjoint from
this feature.

## 2026-11-04 Shop transaction update

Shop purchases now use authoritative item prices and one atomic inventory/gold transaction.
The feature is limited to `sense/components/shop_component.gd`, gameplay tests and Agent B
reports. It does not modify shop visuals, UI scenes, assets, item IDs, animation metadata or
network contracts, and it does not overlap Agent A's active startup/auth visual files.

## 2026-11-05 Equipment transaction update

Unequip and augment apply/remove now commit inventory plus equipment state atomically and emit
signals only after final state is visible. The feature changes the gameplay data model, focused
tests and Agent B reports only. It preserves all equipment slot IDs, item IDs, UI call signatures,
assets and animation/network contracts, and does not overlap Agent A's integrated HUD files.

## Ownership boundary

Agent A owns final art, sprites, animation metadata, maps/tilesets, UI visuals, the asset
manifest and shared workflow Skill. Agent B owns gameplay state, rules, data models,
integration contracts and automated tests.

The following files are currently mixed-responsibility and should not be edited concurrently:

- `sense/globals/game_content.gd`
- `sense/entities/player/player.gd`
- `sense/entities/enemies/monster/monster.gd`
- `sense/globals/pixel_art.gd`
- `sense/maps/field/field_map.gd`
- `sense/maps/field/world_props.gd`
- `project.godot`

For these files, prefer a contract/resource file owned by one agent and consumed by the other,
or explicitly sequence the branches.

## Stable IDs

Current gameplay IDs must not be silently renamed because they appear in saves, quests, loot,
LAN snapshots and tests.

### Current monster mapping requiring agreement

| Current gameplay ID | Display/reference name | Current asset |
| --- | --- | --- |
| `slime` | Mosqui | `assets/treasure_hunter/monsters/mosqui.png` |
| `shroom` | Snailu | `assets/treasure_hunter/monsters/snailu.png` |
| `boar` | Astromophy | `assets/treasure_hunter/monsters/astromophy.png` |

Recommendation: introduce canonical reference IDs such as `mosqui`, `snailu` and
`astromophy`, while retaining the old IDs as explicit save/content aliases for migration.
Do not rename these records directly in `GameContent` until save, quest, LAN and test migration
is designed and approved.

Other current gameplay IDs to keep stable for now include hero IDs (`warden`, `ranger`,
`mystic`), zone IDs (`town`, `homestead`, `greenwood`, `frostvale`, `dungeon`), item IDs from
`ItemDatabase`, and the seven equipment slot strings.

## Equipment slots

Current canonical slot identifiers:

```text
helmet
armor
weapon
shield
boots
accessory_1
accessory_2
```

Art/UI may use localized labels, but scene metadata and events should use these identifiers
until a jointly approved contract replaces them.

## Direction identifiers

Proposed canonical eight-direction identifiers:

```text
up
top_right
right
bottom_right
down
bottom_left
left
top_left
```

If a sprite only supports four directions, its manifest should declare aliases rather than
forcing gameplay to infer them, for example `top_right -> right` and `bottom_right -> right`.

## Animation state identifiers

Proposed required core states:

```text
idle
move
attack
hurt
death
```

Optional states:

```text
skill
dig
gather
cast
charge
mounted_idle
mounted_move
```

The asset manifest should identify available states, direction coverage, frame count, FPS,
looping, sprite size, pivot/foot point, hit frame and optional effect socket. Gameplay must
provide a fallback when an optional animation is absent.

## Asset reference contract

Agent B proposes that gameplay definitions reference a stable `asset_key`, not a repository
path or palette name. Agent A's manifest resolves the key to:

```text
asset_key
resource_path
animation states and directions
frame size/count/FPS
pivot and collision-foot offset
display scale
license/provenance status
```

This would remove asset paths and palette implementation details from `GameContent` and reduce
conflicts in monster/player gameplay definitions.

## Gameplay event names relevant to art

Art/animation consumers should be able to react to these proposed events without owning the
underlying rules:

```text
actor_state_changed(actor_id, state, direction)
attack_started(actor_id, attack_id, direction)
attack_hit_frame(actor_id, attack_id)
actor_damaged(actor_id, amount, critical)
status_visual_changed(actor_id, status_id, active)
actor_died(actor_id)
actor_respawned(actor_id)
equipment_visual_changed(actor_id, slot_id, item_id)
```

Names and payloads are not final until Agent A agrees. Existing `GameEvent` signals remain
unchanged during SCOUT.

## Questions for Agent A

1. Will the shared workflow Skill and root `AGENTS.md` be added, and on which branch?
2. Does the asset manifest already have a proposed schema and stable `asset_key` format?
3. Should Mosqui/Snailu/Astromophy become canonical gameplay IDs, or should current IDs remain
   permanent aliases?
4. Which direction and animation names are already used by the prepared sprite sheets?
5. Which mixed-responsibility files does Agent A expect to edit first?
6. Are the source-derived assets restricted to local/private builds, or is replacement art
   planned before distribution?

No shared contract change should be implemented until these questions are resolved.

## 2026-11-05 — Recipe evidence and validation

- Agent B confirmed the reference contains forge crafting, ingredient inputs, output tiers,
  equipment/potion crafting and crafting quests, but the current Emberfield recipe values are
  not yet proven exact.
- `CraftingRecipe` now carries an evidence status/source, and all ten current recipes are
  honestly classified as `PROVISIONAL`.
- `RecipeDatabase` rejects malformed definitions, missing catalog items and duplicate recipe
  IDs before registration. Existing recipe IDs and behavior remain unchanged.
- This feature has no visual, asset, animation, direction, item-ID, equipment-slot, save or
  LAN impact. Agent A requires no adaptation.
- A later equipment-enhancement proposal would expose an item level for equipment-detail UI,
  but it remains unimplemented pending approval of the save/item-instance contract.

## 2026-11-05 — Resolved basic combat hits

- Basic player melee and LAN client attacks now produce one authoritative result containing
  applied damage and critical state. Critical augments affect the roll; lifesteal consumes the
  confirmed applied amount.
- Existing item IDs, equipment slots, animation names, art asset IDs and visual layouts are
  unchanged. Agent A requires no source or scene adaptation.
- Future critical/lifesteal visuals should react to resolved combat events and must not roll
  gameplay outcomes independently. The current damage-number presentation remains unchanged.
- Reference evidence confirms Critical, Critical Bonus and LifeSteal are distinct. Critical
  Bonus visual/gameplay behavior is not implemented because its exact formula is unknown.

## 2026-11-05 — Equipment enhancement runtime contract

- Equipped item instances expose `enhancement_level` (displayed 1-10),
  `max_upgrade_level`, `can_upgrade_further()` and `get_upgrade_cost()`.
- UI invokes `InventoryData.upgrade_equipment(slot_type)` with one of the existing stable slot
  IDs. It must not submit a client-computed cost or stat value.
- Successful upgrades emit both `InventoryData.equipment_upgraded` and forwarded
  `GameEvent.equipment_upgraded(slot_type, item_id, level, cost)` after the upgraded item and
  final gold balance are visible. Failed commands emit no upgrade/equipment/gold change.
- Existing tooltip text now reports level and scaled stats. No asset, scene layout, animation,
  direction or item/equipment-slot ID changed.
- Agent A may bind the verified Treasure Hunter equipment-detail Upgrade action to this command
  and event. Exact reference visuals and any upgrade effect remain Agent A-owned; gameplay must
  continue to use stable IDs rather than hard-coded asset paths.
- Current default cost/rate/stat growth is explicitly provisional pending exact card-ID mapping.
  Presentation should display values returned by gameplay and must not imply confirmed numeric
  parity with the original server.

## 2026-11-06 — Beginner equipment quest objective contract

- Gameplay now supports state-derived `equipped_count`, `equipped_rarity` and
  `equipment_level` objective values. These count occupied equipment slots, items at or above an
  Emberfield rarity target, and items at or above a displayed enhancement level.
- The active quest remains exposed through the existing `QuestService.get_main_quest()`,
  `main_progress`, `main_ready` and `quests_changed` contract. Agent A's suggestion HUD requires
  no new callback, asset ID or layout change.
- Upgrade quests must display current state rather than the number of upgrade button presses.
  Verified reference examples are one item at levels 2/5 and three items at level 3.
- This feature does not insert those quests into `GameContent.MAIN_QUESTS`. Agent A should keep
  the current active-quest presentation generic until Agent B proposes a separate chain/save
  migration and the Turtle monster mapping is approved.
- No art-owned file, asset manifest, animation state, direction, gameplay ID or equipment-slot
  ID changed. Agent A's Beginner Quest HUD was integrated independently through PR #53 and
  consumes the unchanged QuestService presentation contract.

## 2026-11-06 — Stable quest save identity

- Gameplay saves now carry `main_quest_id` as an additive stable identity while retaining
  `main_index` for legacy/removed-content fallback.
- The active HUD contract is unchanged: continue reading `get_main_quest()`, `main_progress`,
  `main_ready` and `quests_changed`. Presentation must not read raw save fields.
- No quest/art/asset ID changed in this slice. The change only prevents a future chain reorder
  from silently displaying a different active quest for an existing profile.

## 2026-11-06 — Diamond wallet runtime contract

- Gameplay now exposes `InventoryData.diamonds`, `diamonds_changed(amount)`, and
  `GameState.get_diamonds()`. Reward/cost dictionaries use the normalized key `diamonds`.
- This implements reference currency semantics and persistence only. The current fixed HUD
  remains Gold-only; no Agent A scene, asset, manifest or layout file changed.
- A future Diamond display should subscribe to `diamonds_changed` and read the wallet value. It
  must not represent Diamond as an item or calculate a separate presentation-side balance.
- LAN Diamond rewards are not implemented in this slice. Presentation must not imply that
  clients receive Diamond over the current `item`/`gold`/`xp` protocol.
- Godot import, gameplay/save suites and live/dead MobileHUD render passed.

## 2026-11-06 — Active q01 evidence correction

- Q01 remains one dig, matching the captured `0/1` state and active reference quest ID 335.
- Its authoritative reward is box 150: exactly 100 Gold. No XP or item is included.
- The existing HUD continues to consume `QuestService` dynamically; no visual callback, asset,
  layout or quest icon change is required.
- Inactive ID 305 is the separate ten-dig/box-149 quest and remains unmigrated until its Common
  weapon card IDs have an approved gameplay mapping.

## 2026-11-06 — Reward box resolver prerequisite

- Gameplay now has a deterministic, mutation-free weighted resolver for future reward boxes.
- Its output uses the existing `xp`, `gold`, `diamonds` and `items` reward contract; no UI or art
  consumer changes are required.
- Box 149 is not registered and no existing weapon is aliased to cards 28/29/30. Agent B still
  needs three approved stable art IDs before proposing the matching additive gameplay items.

## 2026-11-06 — CheckBox reward resolver contract

- Source metadata confirms `RandomType.Option = 0` and `RandomType.CheckBox = 1`. Gameplay now
  exposes mutation-free independent resolution through `RewardBoxResolver.resolve_checkbox()` and
  deterministic replay through `resolve_checkbox_rolls()`.
- This adds no asset, UI, animation, direction, quest, save or LAN contract; Agent A requires no
  adaptation.
- Reference Box 153 is confirmed as both Stone_3 x2 and Stone_6 x2 because both CheckBox entries
  have chance 100. It remains unregistered until those cards receive canonical gameplay and asset
  identities; no existing Emberfield material is treated as an alias.

## 2026-11-06 — Verified currency reward-box catalog

- Gameplay contains exact source definitions for boxes 98/150/151/152 only: Diamond 1 and Gold
  100/200/300. No presentation change is required.
- Box 149 is intentionally absent. Agent A's proposed three weapon asset IDs remain the dependency
  for its future registration and the ten-dig follow-up quest.

## 2026-11-06 — Reference equipment instance persistence

- Gameplay accepts the integrated stable art IDs `item.weapon.card_28.icon`,
  `item.weapon.card_29.icon` and `item.weapon.card_30.icon` as source identity metadata.
- Duplicated equipment instances can now persist a source card ID, asset ID and exact decimal
  Health/Damage/Speed payload through save schema version 3. The existing catalog templates remain
  immutable and do not receive reference instance data.
- These fields are not yet a presentation contract: gameplay does not resolve the asset ID to a
  texture, register cards 28-30 as runtime item IDs, display reference stats or apply them to
  character attributes. Agent A requires no adaptation in this slice.
- A later materialization/UI feature must display values supplied by the instance and must not
  independently roll, round or derive rarity modifiers. Those rules are still unknown.

## 2026-11-06 — Reference weapon catalog runtime IDs

- Additive gameplay identities are `th_weapon_28`, `th_weapon_29` and `th_weapon_30`; they map to
  source card IDs 28/29/30 and the already-integrated stable icon metadata IDs.
- These templates are intentionally hidden from the current blacksmith enumeration and have no
  runtime icon resolver. Agent A requires no adaptation and should not add presentation-side aliases.
- Materialized instances preserve exact validated Health/Damage/Speed payloads. Future UI must read
  the instance values and source asset ID; it must not independently roll or infer stat values.
- Box 149 and quest 305 remain unavailable until a separately approved pending-reward/claim flow
  can commit the exact materialized instance atomically and retry safely.
- Runtime upgrade is intentionally disabled until reference stats participate in the authoritative
  upgrade rule. Presentation must not expose an Upgrade action for these IDs yet.
- Godot import, gameplay/save suites and live/dead HUD rendering pass; the blacksmith remains at
  its pre-feature 29 public items. Agent A's presentation requires no change.

## 2026-11-06 — Pending quest-claim journal contract

- Quest completion signals now publish only after reward, quest transition and journal clearing
  have been persisted successfully. Existing `QuestService.claim()` and presentation signals keep
  their public shape.
- A failed claim may remain retryable through an internal persisted journal. UI should continue
  reading authoritative quest/inventory state and must not grant, reroll or clear rewards itself.
- No asset ID, animation state, direction, layout, quest definition or Turtle contract changed.
  Agent A requires no adaptation for this feature.
- Box 149 and quest 305 remain excluded. Their later UI may display only the exact materialized
  instance supplied by gameplay; presentation must never reroll card/stat values.

## 2026-11-06 — Exact equipment reward carrier

- Gameplay reward payloads may now preserve card 28/29/30 exact stat instances through save/retry.
  Their stable icon IDs are derived from the existing reference catalog and are not caller fields.
- No asset ID, icon resolver, UI callback, animation, direction or manifest entry changed. Agent A
  requires no adaptation in this feature.
- Future reward presentation must read the materialized instance's source asset ID and exact stats;
  it must not roll, round, recolor or substitute presentation-side values.

## 2026-11-06 — Box 149 authority boundary

- Gameplay now records the exact source `34/33/33` card-selection contract for Box 149 without
  inventing weapon stats. Selection records the box, roll and card 28, 29 or 30; a separate
  authority must provide the complete exact stat payload before a reward can be journaled or
  granted.
- Stable icon IDs remain derived from `ReferenceEquipmentCatalog`. No new art ID, manifest entry,
  texture path, UI callback, animation or direction contract was added.
- Presentation must never select a card, generate stats or reroll a failed/retried reward. Quest
  305 and a reward popup consumer remain outside this feature, so Agent A requires no adaptation.
