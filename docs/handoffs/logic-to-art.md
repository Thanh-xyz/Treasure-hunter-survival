# Logic-to-Art Contract Proposal

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
