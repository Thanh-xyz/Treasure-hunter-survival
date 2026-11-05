# Art-to-Logic Contract

Date: 2026-11-04
Status: startup/auth presentation integrated; broader asset registry remains proposed.

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

Agent B's shop-transaction feature is integrated through PR #14 into `develop`
and PR #15 into `main`. Its changed gameplay files are disjoint from this
startup/auth feature, which changes only Agent A-owned art/docs plus `StartupGate`
and its render test.

## Future Coordination

Before runtime asset integration, agree on registry location and ownership,
missing-key behavior, direction/state aliases, animation event payloads, hit-frame
ownership, integration branch, and feature merge order.

## Current Feature Validation

- Manifest JSON parsed successfully.
- 100 asset IDs and target paths are unique; all recorded paths exist.
- 44 supplied Treasure Hunter entries are marked `local_only`.
- All 37 UI reference targets match their manifest source files bit-for-bit and
  have the recorded dimensions.
- Ten startup/authentication assets are marked `integrated`.
- All ten shared workflow Skills passed `quick_validate.py`.
- Inventory, legacy, and survival Godot suites passed after the stat-icon update
  and after incorporating Agent B's sale-transaction integration commit.
- Startup and mobile-HUD render scenes passed with Godot 4.6 under Xvfb/OpenGL.

## Reference UI Kit Update

Agent A captured 14 runtime states and selected 26 exact source images for startup,
login, HUD, settings tabs, and custom-layout controls. Stable files live under
`assets/treasure_hunter/ui/reference/`; all are `local_only`. Ten startup and
authentication entries are integrated; the remaining HUD/settings entries stay
selected references.

The selected login set now includes the exact `1024x1024` castle/village source
background as `login_background_server.png`; the runtime portrait presentation is
a scale/crop of this square source.

The exact `683x1024` Halloween startup illustration is selected as
`loading_background_halloween.png`; the runtime presents it with a center crop
behind the logo, progress bar, phase text, spinner, and tip panel.

The runtime consumer is now `sense/ui/mobile/startup_gate.gd`. No gameplay ID,
save model, backend-authentication behavior, or LAN protocol changed. See
`docs/reports/reference-screen-inventory.md` for the observed screen graph and
recommended order.

## Startup And Authentication Runtime Contract

`StartupGate` now renders the observed loading, register, and login presentation
with selected source assets. Existing public behavior is preserved:

- `_choose_local()` still stops LAN, unpauses the tree, emits `local_selected`, and
  emits mode `local`.
- `_choose_host()` and `_choose_join()` still delegate to `LanSession`.
- `_on_lan_ready()` still unpauses and emits the LAN role.
- `configure()` and `open()` remain the entry points used by `sense/main.gd`.

Agent B's integrated save-validation and shop-transaction work does not overlap
this feature. Future logic should not bind authentication semantics to the visual
username/password fields; they are reference presentation for the authorized
local build, not a recreated backend.

## Fixed HUD And Hotbar Runtime Contract

The HUD visual pass preserves all existing `MobileHUD`, `ActionButton`, and
`VirtualJoystick` input behavior. The eight `hotbar_1` through `hotbar_8` actions,
menu callbacks, player binding, death state, and gameplay data remain unchanged.

`panel_stats.png` now supplies the sliced outer hotbar and slot borders, while
`joystick_ring.png` supplies the movement ring. These are presentation-only local
assets; Agent B should continue treating action IDs and inventory/skill ownership
as gameplay contracts independent of the visual frame.

## Fixed HUD Chrome Contract

`MobileHUD` now uses the verified `Button_Menu` and dot-and-chevron minimize icon
for its existing top-right controls. `_on_menu_button("system")` and
`_toggle_hud_chrome()` are unchanged; this is presentation-only and introduces no
new gameplay events or settings keys.

## Fixed HUD Rail Contract

The existing navigation buttons now render through the same verified
`Panel_Stats` sliced frame as the other fixed HUD controls. The existing
`character_attack` action uses `ui.reference.hud.icon.weapon`, sourced from the
single-sword `IconSlot_Weapon__1.png` export. No action ID, callback, menu route,
position, input behavior, death state, or compact-HUD setting changed.

The crossed-sword `ui.reference.hud.icon.attack` candidate is explicitly rejected
for this control. Other rail icons remain current fallbacks until direct runtime
evidence proves an exact source mapping; Agent B does not need to change gameplay
data or tests for this presentation-only feature.

## Fixed HUD Stat Icon Contract

`MobileHUD` now displays verified `ui.reference.hud.icon.power`, `.health`,
`.damage`, `.speed`, and `.gold` assets in the existing stat/currency rows. The
underlying defense, health, attack, movement-speed, and inventory-gold values,
signals, formatting, and update cadence are unchanged. The coordinate globe
remains the existing fallback pending an exact mapping. Agent B does not need to
change gameplay data, state, or tests for this presentation-only feature.

## Fixed HUD Right Rail Icon Contract

`MobileHUD` now displays verified `ui.reference.hud.icon.back`, `.pet`, and
`.skill` sources on the existing inventory, pet-menu, and auto-farm controls.
The visual mapping is verified; the original Treasure Hunter semantics of the
cape/back control remain unknown. Emberfield callbacks, positions, compact-HUD
behavior, and auto-farm state color are unchanged. No Agent B gameplay change or
shared contract migration is required.

## Fixed HUD Map Icon Contract

`MobileHUD` now displays `ui.reference.hud.icon.map`, the scene-pointer-verified
`F200_389` globe, beside the existing coordinate label. The player-position
calculation, integer formatting, half-second refresh cadence, and world/resource
panel layout are unchanged. This is presentation-only; Agent B does not need to
change gameplay data, state, saves, LAN snapshots, or tests.

## Fixed HUD Portrait Frame Contract

`MobileHUD` now uses `ui.reference.hud.portrait.frame` (`F200_1_41`) with its
verified 15-pixel nine-slice borders, reuses `ui.reference.login.panel` as the
nested portrait background with its verified 20-pixel borders, and renders the
active `ui.reference.hud.portrait.border` (`BorderAvatar`) overlay above the
dynamic portrait. The hero portrait texture, tint refresh, button position/size,
and existing bag callback are unchanged. Agent B does not need to change hero
data, inventory behavior, saves, LAN snapshots, or tests.
