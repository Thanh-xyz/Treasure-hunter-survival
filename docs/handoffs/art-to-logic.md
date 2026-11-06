# Art-to-Logic Contract

Date: 2026-11-04
Status: startup/auth presentation integrated; broader asset registry remains proposed.

## Stone_1 Health Ingredient Asset Contract

- Stable art ID `item.ingredient.card_64.icon` maps to card `64` / `Stone_1`,
  the verified Health ingredient used by Quest 317 and Box 444-447.
- Target texture is
  `assets/treasure_hunter/items/ingredients/card_64_stone_1.png`, an exact
  `28x31` local-only source copy with SHA-256
  `1aae2b48e70a9591d0977e4c56e0f83049f1e7d4fcb9ddb4fae8d5422ad32a88`.
- It has no runtime consumer or gameplay item ID. Quest 317, drops, rarity/stat
  generation, upgrading, persistence, and UI require separate gameplay plans.
- Executed validation covers exact bytes/hash/dimensions/alpha, manifest
  uniqueness/paths, Godot import, Inventory Transaction, Legacy, and Survival/save.

## Stone_3 Damage Ingredient Asset Contract

- Stable art ID `item.ingredient.card_66.icon` maps to source card `66` /
  `Stone_3`, the verified Damage ingredient used by Quest 316 and Box 452-455.
- Target texture is
  `assets/treasure_hunter/items/ingredients/card_66_stone_3.png`, an exact
  `29x32` local-only source copy with SHA-256
  `49e02811b700b5a5c42771d73683852273bbf4d7a458535ea87c31b05ede4a2d`.
- The asset has no runtime consumer or approved gameplay item ID. Agent B may
  use the stable art ID as metadata after integration, but Quest 316, digging
  drops, rarity/stat generation, upgrading, persistence, and Box 153 require
  separate gameplay plans. Stone_6 remains a separate Box 153 dependency.
- Source/target byte identity, SHA-256, dimensions, alpha, manifest uniqueness
  and target paths, Godot import, Inventory Transaction, Legacy, and
  Survival/save are covered by executed validation.

## Equipment Detail Presentation Contract

- Equipped-slot taps open a dedicated Treasure Hunter-style item-detail modal.
  Presentation passes only the existing stable equipment slot ID to gameplay.
- The Upgrade action calls `InventoryData.upgrade_equipment(slot_type)` and then
  reads final level, stats, Gold, cost, and availability from the equipped item.
  It never calculates or submits an upgrade payload.
- Items without `can_upgrade_further()` remain disabled, including reference
  cards 28-30 under the current Agent B contract. The live reference cost `100`
  is not a shared constant and does not change gameplay authority.
- Remove uses the existing atomic `unequip_item(slot_type)` path. Sell is shown
  disabled to preserve the verified three-action layout without inventing an
  equipped-sale transaction.
- No quest 315 registration, reward, item ID, rarity mapping, save field,
  currency, Box 149 generator, stat formula, or gameplay signal changed. Agent B
  requires no adaptation for this presentation slice.
- The focused render test verifies the real inventory-slot tap path, final-state
  upgrade refresh, insufficient-Gold rejection, locked reference equipment,
  authoritative removal, disabled sale, and exactly one modal-close signal.
  Import, rarity render, Inventory Transaction, Legacy, and Survival/save gates
  pass on Godot `4.6.stable.official.89cea1439`.

## Quest Menu Runtime Contract

- `GameMenu.open("quest")` remains the stable entry point. The feature changes
  only quest presentation inside the existing menu and adds no new gameplay API.
- Main and daily cards continue to read `QuestService`; the existing
  `QuestService.claim(quest_id)` call remains the sole claim action.
- The main page derives read-only next/completed rows from
  `GameContent.MAIN_QUESTS` plus `QuestService.main_index`; it does not mutate
  progression or expose a new save field.
- Login-reward and achievement tabs use exact reference icons but are disabled.
  Agent B should not enable them until their gameplay domains, rewards, save
  behavior, and tests are separately approved.
- Nine `ui.reference.quest.menu.*` assets plus the existing back/login sources
  are runtime consumers in `sense/ui/mobile/game_menu.gd`; all remain
  `local_only`.

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

## Turtle Asset Contract

The exact reference Turtle now has two selected local-only art identities:

| Stable asset ID | Target | Intended role |
| --- | --- | --- |
| `actor.monster.turtle.default` | `assets/treasure_hunter/monsters/turtle_atlas.png` | Animated actor source atlas |
| `actor.monster.turtle.icon` | `assets/treasure_hunter/monsters/turtle_icon.png` | Padded UI/card/quest icon |

The atlas is `384x256`, sliced into `64x64` source rectangles with center pivots
at 40 PPU. Verified source clips are `idle`, `walk`, `attack`, and `dead`; the
manifest canonical names are `idle`, `move`, `attack`, and `death`. Clip order,
loop flags and durations are recorded in the manifest. No direction set, hit
frame, collision footprint, stats, AI, drops, gameplay ID, quest registration,
save/LAN mapping or runtime consumer is included.

Agent B must not alias this identity to GreenTortoise, PurpleTortoise,
`moss_turtle`, `shell_tortoise`, `slime`, `shroom`, or `boar`. Card ID 33 and
quest 306 are provenance evidence only until a separate gameplay proposal is
approved.

## Snailu Animated Atlas Contract

`actor.monster.snailu.atlas` selects the exact local-only runtime atlas at
`assets/treasure_hunter/monsters/snailu_atlas.png`. It is `384x256`, sliced into
21 `64x64` source rectangles with center pivots at 40 PPU. The existing
`actor.monster.snailu.default` remains the integrated static icon/current
consumer contract; this additive feature does not repoint it.

Verified source clip sequences are:

| Source clip | Ordered keys | Loop | Stop time |
| --- | --- | --- | ---: |
| `idle` | `Idle_0, Idle_1, Idle_2, Idle_3, Idle_0` | yes | `0.7083333731` |
| `walk` | `Run_0, Idle_1, Run_2, Run_3, Run_4, Run_5` | yes | `0.4583333135` |
| `attack` | `Attack_0, Attack_1, Attack_2, Attack_3, Attack_4, Attack_5` | yes | `0.6666666865` |
| `dead` | `Death_0, Death_1, Death_2, Death_3, Death_4, Death_5` | no | `0.75` |

The `Idle_1` key in `walk` is verified source data and must not be silently
replaced with an inferred `Run_1`. Manifest canonical states are `idle`, `move`,
`attack`, and `death`. Directions, hit frames, collision, gameplay identity,
stats, AI, drops, quest 310, save/LAN and runtime consumption remain outside
this asset contract.

## Mosqui Animated Atlas Contract

`actor.monster.mosqui.atlas` selects the exact local-only runtime atlas at
`assets/treasure_hunter/monsters/mosqui_atlas.png`. It is `384x256`, sliced into
22 `64x64` source rectangles with center pivots at 40 PPU. The existing
`actor.monster.mosqui.default` remains the integrated static icon/current
consumer contract; this additive feature does not repoint it or the current
`slime` gameplay identity.

Verified source clip sequences are:

| Source clip | Ordered keys | Loop | Stop time |
| --- | --- | --- | ---: |
| `idle` | `Idle_0, Idle_1, Idle_2, Idle_3, Idle_0` | yes | `0.375` |
| `walk` | `Run_0, Run_1, Run_2, Run_3, Run_4, Run_5, Run_0` | yes | `0.2916666567` |
| `attack` | `Attack_0, Attack_1, Attack_2, Attack_3, Attack_4, Attack_5` | yes | `0.6666666865` |
| `dead` | `Death_0, Death_1, Death_2, Death_3, Death_4, Death_5` | no | `0.75` |

The source `dead` clip also animates `SpriteRenderer.m_Color.a`: alpha is 1 at
`0.5` seconds and 0 at `0.75` seconds. Manifest canonical states are `idle`,
`move`, `attack`, and `death`. Clip-specific timing must be preserved; the
Unity sample rate of 24 is not a single presentation FPS shared by all states.

Card ID 37 and unavailable quest 313 are provenance evidence only. Directions,
presented scale, hit frames, collision, gameplay identity, stats, AI, drops,
quest activation, save/LAN and runtime consumption remain outside this asset
contract.

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

## Fixed HUD Stat Row Contract

The four existing `MobileHUD` stat rows now render through the scene-verified
`ui.reference.hud.panel.stats` background and
`ui.reference.hud.stat.line` icon/value separator. Defense, current/max HP,
attack, and movement-speed calculations, labels, signals, formatting, and update
cadence remain unchanged. Agent B does not need to change character stats,
combat, saves, LAN snapshots, or tests.

## Fixed HUD World/Resource Row Contract

The three existing `MobileHUD` time, coordinate, and gold rows now render as
scene-verified `ui.reference.hud.panel.stats` panels. Coordinate and gold rows
also use the verified `ui.reference.hud.stat.line` separator; the time row has
no separator because the decoded reference hierarchy has no such child.

`LanSession.short_role_text()`, system-time display, player-position conversion,
integer coordinate formatting, inventory gold updates, and the 0.5-second
refresh cadence are unchanged. No Agent B gameplay, save, LAN, currency, map,
or test adaptation is required.

## Fixed Hotbar Outer Frame Contract

The outer fixed hotbar frame now uses `ui.reference.hud.hotbar.frame`, traced
from `InventoryView/InventorySlotUI Slot1/BG` to `Button1_0`
(`sharedassets1.assets:6918`). The eight individual slots continue using the
verified `ui.reference.hud.panel.stats` source.

All `hotbar_1` through `hotbar_8` action IDs, slot positions and sizes, locked
state, input behavior, and gameplay ownership remain unchanged. Agent B does not
need to change inventory, input, skill, save, or LAN code.

## Fixed HUD XP Bar Removal Contract

The unsupported blue XP bar below the fixed portrait has been removed because
it is absent from both the decoded Treasure Hunter HUD hierarchy and authorized
runtime captures. This is presentation-only.

`GameState.xp`, `xp_needed()`, `xp_changed`, level progression, saves, rewards,
and `_refresh_card()` signal routing remain intact. Agent B does not need to
change XP, quest, combat, save, or LAN code.

## Beginner Quest Suggestion Contract

`MobileHUD` now mirrors the decoded Treasure Hunter beginner suggestion using
the exact `F200_50` frame, `Grass5` icon for verified quest `q01`, and Winbee
guide sprite. The small HUD panel intentionally renders only the active main
quest; daily quests continue to render in the full Quest menu.

The presentation reads the existing `QuestService.get_main_quest()`,
`main_progress`, and `main_ready` values. A ready panel still calls
`QuestService.claim(quest_id)`; a non-ready panel still opens the Quest menu.
No quest ID, objective, reward, save field, signal, gameplay event, or Agent B
file changed. Icon mappings for quests after `q01` remain an art-evidence gap and
must not become a gameplay dependency.

## Fixed Joystick Visual Contract

`VirtualJoystick` now draws the active-scene-verified `F200_Circle_10`
background and `F200_Circle_11` handle instead of the help-screen
`Icon_Joystick` source and procedural handle.

Touch acquisition, moving center, `radius`, `dead_zone`, `_knob` input vector,
`ui_left/right/up/down` strengths, release behavior, and the user opacity setting
are unchanged. The new scaling affects presentation only; Agent B does not need
to adapt player movement, input maps, saves, LAN, or gameplay tests.

## Revive Button Visual Contract

The death-state button now renders through the scene-verified `Button1_0`
20-pixel nine-slice and its decoded Unity color transitions. The implementation
reuses `ui.reference.button.orange`; it adds no asset or manifest entry.

Button position, size, Vietnamese label/countdown, `_death_timer`, disabled
behavior, `_respawn_town` callback, respawn state, save data, and LAN behavior
are unchanged. Agent B does not need to adapt gameplay code or tests.

## Fixed Hotbar Geometry Contract

The existing `ui.reference.hud.hotbar.frame` and eight `Panel_Stats` slots now
use geometry measured from an authorized `720x1600` gameplay capture and decoded
Unity RectTransform evidence.

All `hotbar_1` through `hotbar_8` action IDs, ordering, locked state, touch/input
behavior, inventory data, save data, and gameplay ownership remain unchanged.
Agent B does not need to adapt gameplay code or tests.

## Fixed Joystick Placement Contract

The existing `VirtualJoystick` control now rests at the decoded Treasure Hunter
default center `(360,1123)` for the verified `720x1516` game surface. The
connected-device runtime coordinate was not copied because the reference game
exposes a persistent custom HUD editor and that coordinate is user-specific.

The touch area remains `238x300`; exact background/handle assets, visual sizes,
radius, dead zone, floating-center behavior, `ui_left/right/up/down` strengths,
opacity, release handling, player movement, saves, and LAN contracts are
unchanged. Agent B requires no adaptation.

## Box 149 Beginner Weapon Asset Contract

The three exact local-only icon identities requested for Box 149 are now:

| Reference card | Reference icon | Stable asset ID | Target |
| ---: | --- | --- | --- |
| `28` | `Weapons_0` | `item.weapon.card_28.icon` | `assets/treasure_hunter/items/weapons/card_28_weapons_0.png` |
| `29` | `Weapons_1` | `item.weapon.card_29.icon` | `assets/treasure_hunter/items/weapons/card_29_weapons_1.png` |
| `30` | `Weapons_2` | `item.weapon.card_30.icon` | `assets/treasure_hunter/items/weapons/card_30_weapons_2.png` |

These IDs identify art only. Agent B may propose additive gameplay item IDs that
retain source card IDs as metadata, but must not alias the cards to existing
`wooden_sword`, `iron_sword`, or `battle_axe` identities without separate
evidence. Box 149 registration, item names, stats, reward materialization, saves,
LAN, quests, and runtime consumers remain outside this feature.

## Quest 314 Rarity Field Presentation Contract

`InventorySlotUI` now presents equippable items in inventory/equipment fields
using exact dominant colors sampled from authorized Treasure Hunter captures: Common
`#FFEDC3`, Rare `#27A1CB`, Epic `#A964DF`, and Legendary `#E1C321`.

This is presentation-only. It consumes Emberfield's existing `ItemData.rarity`
and does not reinterpret Treasure Hunter `rareRequire` integers, reorder the
`ItemRarity` enum, activate quest 314, grant box 98, or change inventory/save/LAN
state. Emberfield Uncommon remains a green fallback with no claimed reference
equivalent. Non-equipment items retain their prior dark field because the
reference `useRareColor` boundary is not mapped into Emberfield. Agent B requires
no gameplay adaptation.

Godot 4.6 import, focused rarity-field pixel assertions, Inventory Transaction,
Legacy, and Survival/save regressions pass. The deterministic render is
`/tmp/emberfield-inventory-rarity.png`; it validates the presentation without
creating a new gameplay or persistence dependency.

# Post-Tutorial Quest Menu Visual Kit

- Authorized runtime captures now cover main, daily, login-reward and
  achievement quest tabs on an already-onboarded account. Captured progress,
  unlocks and currencies are account-specific and must not seed default content.
- Nine exact local-only quest-menu assets are selected under stable
  `ui.reference.quest.menu.*` IDs. They have no runtime consumer yet.
- Existing assets cover the back button and login tab icon; do not introduce
  duplicate copies for those roles.
- A future presentation feature may consume the kit through the existing
  `QuestService` interface, but this feature does not add or change quest IDs,
  objective math, daily reset, login rewards, achievements, claim semantics,
  saves or LAN replication.
- `BG_1` was intentionally excluded because its exported white `8x8` region is
  insufficient to prove the final tinted/material appearance.
