# Art-to-Logic Contract

Date: 2026-11-04
Status: Agent A proposal; runtime contract changes still require coordinated implementation.

## Ownership

Agent A owns the Art Bible, asset manifest, final art selection, animation
metadata, UI visuals, art reports, and shared workflow Skills. Agent B owns
gameplay state, rules, data models, gameplay integration, and gameplay tests.

## Local Asset Decision

The user authorizes supplied Treasure Hunter assets for the local/private build.
Manifest provenance uses `distribution_scope: local_only`. No public distribution
right is implied.

## Stable Gameplay IDs

| Gameplay ID | Display/reference identity | Proposed asset ID |
| --- | --- | --- |
| `slime` | Mosqui | `actor.monster.mosqui.default` |
| `shroom` | Snailu | `actor.monster.snailu.default` |
| `boar` | Astromophy | `actor.monster.astromophy.default` |

Hero, zone, item, equipment-slot, quest, save, and LAN identifiers remain stable
until an approved migration covers all consumers.

## Asset Contract

Gameplay should eventually reference a stable `asset_id`, resolved by an
art-owned registry or generated resource. The manifest records resource path,
dimensions, transparency, animation states, directions, aliases, frame metadata,
pivot, scale, provenance, evidence, and integration status.

The runtime registry is not part of this documentation-only feature.

## Direction Contract

Canonical directions:

```text
up, up_right, right, down_right, down, down_left, left, up_left
```

Known aliases include `right_up`/`top_right`, `right_down`/`bottom_right`,
`left_down`/`bottom_left`, and `left_up`/`top_left`.

## Animation Contract

Core states: `idle`, `move`, `attack`, `hurt`, `death`.

Optional states: `skill`, `dig`, `gather`, `cast`, `charge`, `mounted_idle`,
`mounted_move`.

Missing directions or states require explicit manifest aliases/fallbacks. Logic
must not infer a fallback from a filename alone.

## Shared Files

Do not concurrently edit:

- `project.godot`
- `sense/globals/game_content.gd`
- `sense/globals/pixel_art.gd`
- `sense/entities/player/player.gd`
- `sense/entities/enemies/monster/monster.gd`
- `sense/maps/field/field_map.gd`
- `sense/maps/field/world_props.gd`

Agent A does not modify these files in the workflow/art-governance feature.

## Agent B Active Work

Agent B completed and pushed commit `e225178` on
`feature/th-logic-inventory-transactions`, changing gameplay state, quests,
crafting, inventory, and gameplay tests. Agent A continues avoiding those files.

Agent B's scout handoff reported missing soldier PNGs in its worktree. Agent A
verified that the referenced files now exist in both worktrees and are tracked by
Git, so no art restoration change is currently required. This does not certify the
Godot suite because no Godot CLI is available on Agent A's command path.

## Future Coordination

Before runtime asset integration, agree on registry location and ownership,
missing-key behavior, direction/state aliases, animation event payloads, hit-frame
ownership, integration branch, and feature merge order.

## Current Feature Validation

- Manifest JSON parsed successfully.
- 63 asset IDs are unique; all recorded source and target paths exist.
- Seven supplied Treasure Hunter entries are marked `local_only`.
- All ten shared workflow Skills passed `quick_validate.py`.
- No gameplay or shared runtime file is part of Agent A's feature.

## Reference UI Kit Update

Agent A captured 14 runtime states and selected 25 exact source sprites for login,
HUD, settings tabs, and custom-layout controls. Stable files live under
`assets/treasure_hunter/ui/reference/`; all are `local_only` and currently marked
`selected`, not `integrated`.

The selected login set now includes the exact `1024x1024` castle/village source
background as `login_background_server.png`; the runtime portrait presentation is
a scale/crop of this square source.

No runtime consumer or gameplay contract changed. Before Agent A reconstructs the
HUD or authentication scene, both agents must sequence ownership for the affected
shared UI files. See `docs/reports/reference-screen-inventory.md` for the observed
screen graph and recommended order.
