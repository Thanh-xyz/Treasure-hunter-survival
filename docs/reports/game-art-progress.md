# Game Art Progress

Date: 2026-11-06
Current feature: recreate the Treasure Hunter equipped-item detail panel for
quest 315 presentation.

## Equipment Detail Panel Feature

- Added a dedicated portrait item-detail modal for equipped slots, following
  the live Treasure Hunter 4.3.7 composition: centered grey-purple panel,
  equipment name and level, rarity-colored item field, stat rows, description,
  and Remove/Upgrade/Sell action positions.
- The panel consumes the existing stable slot IDs and authoritative
  `InventoryData` commands. Remove calls `unequip_item(slot_type)` and Upgrade
  calls `upgrade_equipment(slot_type)` without submitting a cost, level, or stat
  value from presentation.
- Upgrade cost, enabled state, displayed level, and scaled stats are refreshed
  from final gameplay state. Reference cards 28-30 remain visibly unavailable
  because their runtime upgrade contract is intentionally disabled.
- The Sell action is present but disabled because Emberfield does not have an
  authoritative atomic equipped-sale transaction. The observed live `100` cost
  and Unity `HoldButton` component are evidence only; neither is hard-coded or
  treated as a verified economy/interaction rule.
- Reused the integrated local-only blue button, Gold/health/damage/speed icons,
  theme, and rarity field resolver. No binary asset or manifest entry was added;
  neutral and disabled-red action styling is capture-derived pending exact Unity
  sprite binding.
- Added a deterministic portrait render harness with a logical `720x1600`
  viewport. The project's 2x stretch transform captures a `360x800` PNG while
  exercising upgrade, insufficient-Gold, locked-reference, and remove states;
  it saves `/tmp/emberfield-equipment-detail.png` for visual comparison.
- Review made modal closure idempotent, removed duplicate post-transaction
  refresh/close calls, and localized presentation tooltips. Godot 4.6 import,
  focused equipment-detail and rarity renders, Inventory Transaction, Legacy,
  Survival/save, and `git diff --check` all pass. The focused capture remains
  `44d661c8c9cc0d27bf797bef161504b93347624395e032502690e3bd4c1fb032`.

## Quest Menu Runtime Feature

- Replaced only the generic quest-tab presentation inside `GameMenu` with the
  verified Treasure Hunter tab, card, list, section-label, and icon sources.
- Preserved `open("quest")`, `QuestService` signals/data, claim callbacks,
  rewards, quest IDs, save behavior, LAN behavior, and every non-quest menu tab.
- Main and daily categories consume the existing Emberfield domains. Login
  rewards and achievements remain visibly disabled because no approved gameplay
  domain exists for them; no placeholder objectives or rewards are invented.
- Main-page next/completed groups are read-only projections of the existing
  `GameContent.MAIN_QUESTS` order and `QuestService.main_index`.
- Added deterministic `720x1600` main, claim-ready, daily, and chain-complete captures through
  `tests/RenderGameMenu.tscn`. Main/daily support visual comparison; the
  claim-ready render validates the conditional consumer only because that
  runtime state was not captured from the reference account.
- The verified asset structure follows the post-tutorial reference capture, but
  the displayed quest content reflects Emberfield's current save/domain state;
  this feature does not claim content parity with the user's reference account.

## Completed Before This Feature

- Curated four Treasure Hunter field props.
- Integrated Mosqui, Snailu, and Astromophy static sprites.
- Added field visual-pass specification and device-capture workflow.
- Collected extensive `720x1600` runtime screenshots and recordings.
- Exported and validated 23,505 reference images from the supplied Unity build.

## Turtle Asset Contract Feature

- Verified that the reference Turtle actor uses Unity Texture2D `Mob_0` path ID
  `347`, not the separate GreenTortoise or PurpleTortoise sheets.
- Added the exact `384x256` local-only atlas as
  `actor.monster.turtle.default` and its exact `20x21` padded UI icon as
  `actor.monster.turtle.icon`.
- Recorded the 21 `64x64` sprites, center pivot, 40 PPU, and Unity-proven
  `idle`, `walk`, `attack`, and `dead` clip sequences. Canonical manifest states
  map `walk` to `move` and `dead` to `death`.
- Kept the feature asset-only: no gameplay ID, monster registration, stats, AI,
  drops, collision, quest 306, save/LAN contract, runtime consumer, or alias to
  an existing Emberfield actor was added.
- A connected ADB device remained on the saved-account login surface; automated
  taps did not advance it, so no runtime spawn, scale, collision, direction, or
  behavior observation is claimed.
- Godot `4.6.stable.official.89cea1439` imported both PNGs with lossless
  compression and mipmap generation disabled. Inventory Transaction, Legacy and
  Survival/save suites completed with exit code `0`; corrupt-save and resource
  leak warnings are existing test fixtures/known warnings.
- Independent UnityPy validation matched Texture2D path ID `347`, all 21 sprite
  rects/pivots/PPU values, four clip sequences, loop flags and durations.
  Source-target byte/hash checks and pixel comparison passed. The manifest now
  has 123 unique asset IDs/targets and 67 `local_only` entries.

## Snailu Animated Atlas Feature

- Verified that Snailu GameObject path ID `12019` renders through `Mob_1`,
  Texture2D path ID `410` and AnimatorController `2949`.
- Added the exact `384x256` atlas as selected local-only asset
  `actor.monster.snailu.atlas` while preserving the existing integrated static
  icon ID `actor.monster.snailu.default` and all current runtime consumers.
- Recorded 21 `64x64` sprites, center pivots, 40 PPU, sample rate 24, and the
  Unity-proven `idle`, `walk`, `attack`, and `dead` sequences.
- Preserved the source `walk` anomaly exactly: its second key is `Idle_1`, not
  an invented `Run_1`. Canonical manifest states map `walk` to `move` and
  `dead` to `death`.
- Kept the feature asset-only: no gameplay ID, monster registration, stats, AI,
  drops, collision, quest 310, save/LAN contract or runtime consumer changed.
- Godot `4.6.stable.official.89cea1439` imported the atlas with lossless
  compression and mipmap generation disabled. Inventory Transaction, Legacy and
  Survival/save suites completed with exit code `0`; existing corrupt-save and
  resource warnings remain visible.
- Independent UnityPy validation passed for the runtime pointer, all 21 sprite
  rects/pivots/PPU values, four clip sequences, sample rates, loop flags and
  durations. Source-target byte/hash checks pass. The manifest now has 124
  unique asset IDs/targets and 68 `local_only` entries.

## Mosqui Animated Atlas Feature

- Verified the exact Unity object chain from Mosqui GameObject `12016` through
  body `40226`, child `Mob_2`, SpriteRenderer `77014`, Animator `71317`,
  AnimatorController `2950`, and Texture2D path ID `699`.
- Added the exact `384x256` RGBA atlas as selected local-only asset
  `actor.monster.mosqui.atlas` while preserving the integrated static icon ID
  `actor.monster.mosqui.default` and every current runtime consumer.
- Recorded all 22 centered `64x64` sprites at 40 PPU and the source-specific
  timing for looping `idle`, `walk`, and `attack` plus non-looping `dead`.
- Recorded the source death presentation detail: its SpriteRenderer alpha stays
  at 1 through `0.5` seconds and reaches 0 at `0.75` seconds. No replacement
  fade, hit event, direction, or scale was inferred.
- Verified that the current `31x33` Mosqui icon contains the visible Idle_0
  pixels with a two-pixel transparent pad on every side; the existing icon
  contract remains unchanged.
- Kept the feature asset-only: no gameplay ID, current `slime` alias, monster
  registration, stats, AI, drops, collision, quest 313, save/LAN contract or
  runtime animation consumer changed.
- ADB authentication reproduced the 4.3.7 Mirror deserialize mismatch, so no
  live-world Mosqui scale, direction, collision, or attack timing is claimed.
- Independent UnityPy validation passed for the runtime object chain, all 22
  sprite rects/pivots/PPU values, controller/clip pointers, exact key sequences,
  sample rates, loop flags, durations and the death alpha binding.
- Source-target byte/SHA-256 and Idle_0-to-padded-icon pixel checks pass. Godot
  `4.6.stable.official.89cea1439` imports the atlas losslessly with mipmaps
  disabled.
- Inventory Transaction, Legacy and Survival/save suites completed with exit
  code `0`; existing invalid/corrupt-save fixture and resource-leak warnings
  remain visible. The manifest has 125 unique asset IDs/targets and 69
  `local_only` entries.

## Completed In This Feature

- Defined repository-wide multi-agent and stage rules.
- Added reusable workflow stage Skills.
- Established the initial Game Art Bible.
- Established the initial asset manifest and local-only provenance policy.
- Documented the Agent A scout findings and art-to-logic contract.
- Created external coordination records for Agent A and shared decisions.

## Reference UI Kit Feature

- Captured and classified 14 authorized runtime states at `720x1600`.
- Documented the observed navigation graph, dynamic exclusion regions, and visual
  system in `docs/reports/reference-screen-inventory.md`.
- Curated 26 exact exported UI images into
  `assets/treasure_hunter/ui/reference/` with stable names.
- Matched the exact `1024x1024` castle/village background used by the observed
  login and registration states.
- Matched the exact `683x1024` Halloween illustration used by the observed startup
  loading states.
- Added manifest provenance and evidence metadata for all selected UI sprites.
- Kept the feature additive: no gameplay, scene, script, or test file changed.

## Startup And Authentication Runtime Feature

- Rebuilt `StartupGate` with the exact Halloween loading illustration, server
  background, Treasure Hunter logo, age notice, panel, tab, line, and button assets.
- Added deterministic loading, register, login, and LAN-overlay captures at
  `720x1600` through `tests/RenderStartupGate.tscn`.
- Preserved the existing local, host, join, LAN status, and mode-selected methods;
  the change replaces presentation rather than authentication or networking logic.
- Corrected the active/inactive tab source mapping after runtime visual comparison.
- Kept LAN controls behind the observed `Xem thêm` affordance so the primary
  authentication state remains faithful to the reference capture.

## Fixed HUD And Hotbar Runtime Feature

- Replaced the drawn hotbar borders with the exact sliced `Panel_Stats` source.
- Added the contiguous outer hotbar frame and aligned eight existing action slots
  to the verified live/dead HUD captures without changing their input actions.
- Replaced the inferred joystick ring drawing with the exact
  `Icon_Joystick__5652.png` source after render comparison showed that
  `Joystick_1__6234.png` is a different orange gamepad-style control.
- Extended the deterministic HUD render to capture both live and dead states.

## Fixed HUD Chrome Feature

- Replaced the inferred top-right menu control with the exact `Button_Menu` source.
- Replaced the generic collapse icon with the verified dot-and-chevron
  `Icon_Arrow__5990.png` source while preserving the compact-HUD callback.
- Rejected `Button_MinimizeMode 2__6229.png` and the selected crossed-sword attack
  icon after direct comparison showed that they do not match those captured states.

## Fixed HUD Rail Feature

- Reused the exact sliced `Panel_Stats` source for the existing navigation rail
  buttons instead of the generic Godot button frame.
- Replaced the inferred item-atlas sword with the bit-exact
  `IconSlot_Weapon__1.png` single-sword source on the existing
  `character_attack` control.
- Kept hero, pet, mount, village, and bag fallback icons because current export
  candidates are not yet proven against a clean runtime crop.
- Preserved every existing rail callback, action ID, position, compact-HUD rule,
  and death-state rule.

## Fixed HUD Stat Icon Feature

- Captured a fresh authorized live HUD at `720x1600` and matched five exported
  icons directly against the visible power, health, damage, speed, and gold rows.
- Replaced the five inferred procedural icons with bit-exact Treasure Hunter
  sources while preserving stat calculations, signals, labels, and panel layout.
- Retained the procedural globe icon because no exported source has been proven.

## Fixed HUD Right Rail Icon Feature

- Matched the captured cape/back, paw, and concentric radar silhouettes to
  `IconSlot_Back__1.png`, `IconSlot_Pet__1.png`, and `IconSlot_Skill__6658.png`.
- Replaced the existing inventory, pet, and auto-farm presentation while keeping
  all three Emberfield callbacks and auto-farm state behavior unchanged.
- Deferred the left rail because its current callback meanings do not align with
  the observed Treasure Hunter chat/equipment/movement visuals.

## Fixed HUD Map Icon Feature

- Traced `UIManager/MainCanvas - Camera/HUDView/Panel/TopRight/Map/Icon` in the
  decoded `level1` scene to GameObject `23760`, its Unity UI Image component, and
  `sharedassets1.assets` Sprite `3015` (`F200_389`).
- Recovered the exact `15x15` blue-and-green globe directly from the
  `UIOtherIcons` atlas because the earlier batch-exported PNG was transparent.
- Replaced only the procedural coordinate-row globe; coordinate calculation,
  formatting, refresh cadence, and panel layout remain unchanged.

## Fixed HUD Portrait Frame Feature

- Traced `HUDView/Panel/Avatar` to `F200_1_41` (`sharedassets1.assets:3047`),
  a `64x64` frame with verified 15-pixel Unity nine-slice borders.
- Verified the nested `AvatarUI/BG` uses the already integrated
  `Login_Panel_0` source with 20-pixel borders, and reused it behind the portrait.
- Traced the active `AvatarVisualHost/AvatarHolder/Frame_New` overlay to
  `BorderAvatar` (`sharedassets1.assets:5893`) with 15-pixel borders; the inactive
  `Frame_Default` sibling is not used.
- Preserved the dynamic hero portrait, hero tint updates, bag callback, position,
  and size while replacing only the inferred Godot frame/background styling.

## Fixed HUD Stat Row Feature

- Verified every active fixed stat row points to the already integrated
  `Panel_Stats` background with 20-pixel borders.
- Traced the icon/value separator to `Line` (`sharedassets1.assets:6099`), a
  `16x48` source with verified 20-pixel top and bottom borders.
- Rebuilt all four existing Emberfield stat rows with those exact sources while
  preserving defense, HP, attack, and movement-speed values and update behavior.

## Fixed HUD World/Resource Row Feature

- Traced the active `RegionTime`, `Map`, and `Gold` background Images to the
  already integrated `Panel_Stats` source with verified 20-pixel nine-slice
  borders and `250x70` Unity RectTransforms.
- Traced the Map and Gold separator Images to the already integrated `Line`
  source. Verified that RegionTime intentionally has no icon or separator.
- Rebuilt the three existing Emberfield rows as independent sliced panels,
  removed the inferred group frame, and scaled icon, separator, and value
  regions from the decoded Unity layout.
- Preserved LAN role text, system time, player-coordinate calculation and
  formatting, inventory gold signals, panel placement, and the 0.5-second
  refresh cadence. No new asset or gameplay contract was introduced.

## Fixed Hotbar Outer Frame Feature

- Traced `InventoryView/InventorySlotUI Slot1/BG` to
  `sharedassets1.assets:6918` (`Button1_0`), a `48x48` sliced source with
  20-pixel borders.
- Verified all eight child item slots independently use `Panel_Stats`, so their
  existing texture remains unchanged.
- Replaced only the outer frame source and retained the existing black fill,
  eight action IDs, slot positions, sizes, locking, and input behavior.

## Fixed HUD XP Bar Removal

- Verified that neither the decoded Avatar/TopLeft hierarchy nor authorized
  live/dead captures contains an XP bar under the portrait.
- Removed the inferred blue `_xp_bar` node and its visual-only updates.
- Preserved XP state, `xp_changed` signal handling, level progression, portrait
  refresh, save data, and all fixed stat rows.

## Beginner Quest Suggestion Feature

- Replaced the inferred permanent zone label and generic three-row quest box
  with the decoded `BeginnerQuestView/SuggestionQuestPanel` presentation.
- Integrated the exact `F200_50` sliced frame, verified `Grass5` first-quest
  icon, and directly decoded Winbee guide sprite as local-only reference assets.
- The compact HUD suggestion now presents only the active main quest. Daily
  quests remain available in the existing full Quest menu.
- Preserved `QuestService` IDs, progress, ready state, claim behavior, rewards,
  saves, and the existing non-ready click path that opens the Quest menu.
- Later main quests intentionally show no icon until their source mappings are
  verified. This avoids presenting Grass5 as an unsupported generic quest icon.

## Fixed Joystick Visual Feature

- Corrected the earlier `Icon_Joystick` mapping using stronger active-scene
  pointer evidence.
- Replaced the movement background with exact `F200_Circle_10` and the
  procedural circle/arc thumb with exact `F200_Circle_11`.
- Preserved the existing touch region, floating center, input radius, dead zone,
  input action strengths, action IDs, opacity setting, and release behavior.
- Scaled the verified `256:128` Unity background/handle ratio into the existing
  HUD placement and constrained only the visual handle offset to its available
  travel range.

## Revive Button Visual Feature

- Replaced the generic themed death-state button background with the exact
  scene-verified `Button1_0` nine-slice already integrated as
  `button_orange.png`.
- Applied the decoded Unity normal, highlighted, pressed, and disabled color
  transitions while preserving nearest-neighbor filtering and 20-pixel slice
  borders.
- Preserved button position, size, Vietnamese label/countdown, disabled timer,
  `_respawn_town` callback, death state, and all gameplay contracts.

## Fixed Hotbar Geometry Feature

- Aligned the existing exact hotbar frame to the verified full-width
  `720x116` presentation at y=1400 and used the observed 2/3 CanvasScaler ratio
  to map its 20-source-pixel slice borders to 13 screen pixels.
- Aligned all eight existing slots to the captured 84-pixel center spacing,
  approximately 74-pixel control size, and y=1458 center.
- Preserved `hotbar_1` through `hotbar_8`, ordering, locked state, input
  behavior, assets, callbacks, inventory data, saves, and gameplay ownership.

## Fixed Joystick Placement Feature

- Rejected the connected-device joystick coordinate as a canonical default
  after confirming that Treasure Hunter exposes a saved custom HUD editor with
  explicit `Reset` and `Save` actions.
- Mapped the decoded default `1080x1920` CanvasScaler and bottom-centered
  `(0,542)` RectTransform to the verified `720x1516` Android game surface.
- Moved the existing joystick control so its rest center is `(360,1123)`, the
  rounded scene-derived default. Preserved the `238x300` touch area, exact
  background and handle assets, visual sizes, radius, dead zone, floating-center
  behavior, input strengths, action IDs, opacity, and release behavior.

## Box 149 Weapon Icon Contract Feature

- Added exact local-only source images for Treasure Hunter card IDs `28`, `29`,
  and `30` without assigning them to provisional Emberfield item IDs.
- Registered stable art IDs `item.weapon.card_28.icon`,
  `item.weapon.card_29.icon`, and `item.weapon.card_30.icon` with verified source
  paths, dimensions, alpha, pivots, pixels-per-unit values, and hashes.
- Kept all three entries at `selected`: this feature provides the art identity
  contract but does not create gameplay items, register Box 149, alter quests,
  or choose names/stats outside Agent B ownership.

## Post-Tutorial Quest Menu Kit Feature

- Logged into the user's existing, already-onboarded reference account through
  authorized ADB and captured main, daily, login-reward and achievement tabs at
  `720x1600` without claiming, rerolling or changing account state.
- Independently matched the visible objective strings to the supplied
  `Quest.json` and treated the captured progress/unlocks as account-state
  evidence rather than default-player data.
- Traced the active Unity `DailyQuestsView/Panel` hierarchy to exact main-card,
  claim-card, section-header, list-panel, selected-tab, unselected-tab, main,
  daily and achievement sprite sources.
- Added nine bit-exact local-only reference sprites with stable manifest IDs,
  Unity borders/pivots/PPU, source/target hashes and explicit `selected` status.
- Reused existing back, login, line, panel and button assets instead of copying
  duplicates. Rejected the ambiguous white `BG_1` fill because its final visual
  depends on runtime context not proven by the exported PNG alone.
- Did not modify `GameMenu`, `MobileHUD`, `QuestService`, quest content, claim
  behavior, rewards, saves, LAN or Agent B gameplay files.

## Validation Evidence

- Parsed `docs/architecture/asset-manifest.json` successfully with `jq`.
- Verified 121 assets, 121 unique asset IDs, and 121 unique target paths.
- Verified every non-null source and target path exists.
- Verified all 65 supplied Treasure Hunter entries use
  `distribution_scope: local_only`.
- Verified all nine quest-menu reference targets match their recorded sources
  bit-for-bit and have the manifest dimensions.
- Verified the player scene slices its `768x80` sheets into eight `96x80`
  AtlasTexture regions; manifest frame metadata matches the scene.
- Validated all ten project Skills with the Codex `quick_validate.py` script.
- Imported the project with Godot `4.6.stable.official.89cea1439`.
- Rendered loading, register, login, and LAN-overlay states at `720x1600` with
  Xvfb/OpenGL software rendering.
- Visually compared the fixed startup/authentication regions with the authorized
  ADB captures; exact background, logo, age notice, panels, tabs, line, and button
  sources are used. Pixel parity is not claimed because the original font metrics
  and quantitative dynamic-region mask are not yet available.
- Recorded masked full-frame RMSE baselines after excluding Game Booster and system
  navigation: loading `0.240604`, register `0.156490`, login `0.155654`. These are
  diagnostic baselines, not acceptance thresholds.
- Godot suites passed with exit code `0`: inventory transactions, legacy systems,
  survival systems, startup render, and mobile-HUD render.
- The HUD render produced `/tmp/emberfield-mobile-hud.png` and
  `/tmp/emberfield-mobile-hud-dead.png` at the configured `360x800` window size
  for scaled comparison with the verified `720x1600` live and dead ADB captures.
- Direct visual inspection confirms the five integrated stat/currency icons use
  the verified power, health, damage, speed, and gold sources in their existing
  rows. The coordinate row now uses the scene-pointer-verified `F200_389` globe.
  Pixel parity is not claimed for the full HUD because the map, player, labels,
  and several controls still differ.
- Direct visual inspection also confirms the cape/back, paw, and concentric
  radar silhouettes, scale, placement, and verified gray runtime tint in the
  three updated right-rail controls. Exact full-region parity is not claimed
  because the cape control's dynamic `+1` badge and other HUD regions differ.
- Whole-frame HUD hashes are not used as stable evidence because the rendered
  local-time row changes between runs; fixed visual regions require a masked or
  cropped comparison.
- Direct crop comparison confirms the world/resource stack now has three
  independent `Panel_Stats` frames, no separator in the time row, and the exact
  `Line` separator in the Map and Gold rows. Full-frame pixel parity is not
  claimed because fonts, dynamic values, terrain, and other HUD regions differ.
- Direct hotbar crop comparison confirms the outer frame now uses the verified
  `Button1_0` border/fill language while all eight `Panel_Stats` slots retain
  their order and placement. Pixel parity is not claimed because the current
  Emberfield hotbar height and surrounding terrain still differ.
- Direct top-left crop comparison confirms the unsupported blue XP bar is gone
  and the portrait-to-stat gap more closely follows the authorized capture.
  Full-region parity is not claimed because portrait content, font metrics, and
  dynamic stat values differ.
- Godot 4.6 imported the three quest-reference PNGs and parsed the updated
  `MobileHUD` without script or resource errors.
- Inventory transaction, legacy system, and survival suites completed with exit
  code `0`; their intentional corrupt-save and missing-HUD fixture warnings are
  unchanged from the existing tests.
- Startup and mobile-HUD render gates completed with exit code `0`. Direct
  inspection of `/tmp/emberfield-mobile-hud.png` confirms the Grass5 icon,
  sliced suggestion frame, Winbee overlap, and active-main-quest-only text.
- Direct inspection of `/tmp/emberfield-mobile-hud-dead.png` confirms the quest
  suggestion is hidden immediately in the death state.
- Verified the integrated quest assets as `21x17`, `38x39`, and `77x116` RGBA
  PNGs. Recorded SHA-256 hashes match the directly decoded/copied files in the
  manifest; all three remain `local_only`.
- Godot 4.6 imported the corrected `79x79` joystick background and new `34x34`
  handle without script or resource errors.
- Inventory transaction, legacy, and survival suites completed with exit code
  `0`; startup and live/dead HUD render gates also completed with exit code `0`.
- Direct HUD inspection confirms the decoded brown-tinted four-arrow background
  and exact circular handle replace the pale layout icon and procedural thumb at
  the existing movement-control location.
- Both joystick targets match their supplied exports bit-for-bit and their
  manifest hashes; provenance remains `local_only`.
- Godot 4.6 imported the updated HUD without script or resource errors.
- Inventory transaction, legacy, and survival suites completed with exit code
  `0`; startup and live/dead HUD render gates also completed with exit code `0`.
- Direct inspection of `/tmp/emberfield-mobile-hud-dead.png` confirms the normal
  revive state uses the brown/orange path ID `6916` nine-slice at the unchanged
  rectangle. The similarly named gray path ID `6918` hotbar variant was detected
  and rejected during visual validation.
- The integrated `button_orange.png` target matches the verified path ID `6916`
  export bit-for-bit. Hover, pressed, and disabled colors are metadata-verified
  but were not separately captured as runtime screenshots.
- Captured the active reference gameplay HUD from authorized device `SM_A047F`
  at `720x1600` as `/tmp/ths-hotbar-scout-after-login.png`.
- Godot 4.6 imported the hotbar-geometry change; inventory, legacy, survival,
  startup render, and live/dead HUD render gates completed with exit code `0`.
- At the shared `360x800` comparison scale, the first six slot interiors match
  the reference bounding boxes exactly; the final two differ by one horizontal
  raster pixel from accumulated half-scale rounding. All eight centers preserve
  the verified 84-pixel source cadence.
- The frame top, bottom, width, and height match the captured rectangle. Small
  corner-pixel differences remain because Unity and Godot round sliced borders
  differently; full pixel parity is not claimed.
- Godot `4.6.stable.official.89cea1439` imported the joystick-placement change
  with exit code `0`.
- Inventory transaction, legacy, and survival suites completed with exit code
  `0`; the intentional invalid-input and corrupt-save fixture warnings remain.
- Live and dead MobileHUD render gates completed with exit code `0`. The live
  capture is preserved as `/tmp/emberfield-mobile-hud-joystick-new.png`.
- The rendered center is `(180,561.5)` at the test's `360x800` half scale,
  corresponding to the planned `(360,1123)` logical center. A clean
  `origin/develop` comparison confirms the prior center was `(196.5,572.5)`.
- The fixed-image comparison differs in the joystick movement region as
  expected. Pixel parity against the connected-device runtime coordinate is not
  claimed because that reference coordinate belongs to a saved custom layout.
- Godot 4.6 imported all three Box 149 icon PNGs with lossless compression and
  mipmap generation disabled.
- Manifest validation passed with `112` assets, unique asset IDs and unique
  target paths; all `56` supplied/extracted entries remain `local_only`.
- Source-to-target SHA-256 checks pass for all three icons, and their imported
  dimensions remain exactly `13x21`, `9x20`, and `7x15`.
- Inventory, legacy, survival, and live/dead MobileHUD render gates completed
  with exit code `0`. The icons have no runtime consumer in this feature, so no
  in-game Box 149 visual parity is claimed yet.

## Quest 314 Rarity Field Presentation

- Authorized item-detail and inventory captures verify full occupied-field colors
  rather than Emberfield's former thin rarity glow: Common `#FFEDC3`, Rare
  `#27A1CB`, Epic `#A964DF`, and Legendary `#E1C321`.
- `InventorySlotUI` now uses those capture-derived colors for equippable items in
  inventory and equipment fields while retaining the prior background for
  materials/consumables plus empty, hover, selected and drop-target states. Drag
  previews follow the same boundary.
- Emberfield's additional Uncommon tier keeps its existing green as an explicit
  local fallback; it is not claimed as a Treasure Hunter rarity tier.
- The exported `Frame_Common_*`, `Frame_Rare_*`, `Frame_Epic_*`, and
  `Frame_Legendary_*` families remain unconsumed because the exact Unity
  ItemView binding is not yet verified.
- `RenderInventoryRarity` provides a deterministic output, asserts the four
  verified equipment field pixels, and verifies a non-equipment Epic item keeps
  the prior dark field before saving `/tmp/emberfield-inventory-rarity.png`.
- Godot `4.6.stable.official.89cea1439` imports the project and the focused Xvfb
  render passes with exact output pixels for all four verified tiers. Inventory
  Transaction, Legacy, and Survival/save suites complete with exit code `0`;
  existing missing-item, corrupt-save and resource-cleanup warnings remain.

## Not Yet Implemented

- Runtime asset registry.
- Character assembly and directional Treasure Hunter animation.
- Complete monster, pet, mount, item, equipment, UI, VFX, and audio migration.
- Quantitative visual-diff thresholds.

## Fidelity Rule

Use the exact reference asset and layout when verified. Do not redesign missing
states. Record unknown evidence and defer it until capture or metadata is available.
