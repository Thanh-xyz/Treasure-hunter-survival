# Treasure Hunter Reference Screen Inventory

Date: 2026-11-04
Evidence source: authorized ADB observation of
`com.megacombat.treasurehunter` on Samsung `SM_A047F`.

## Capture Contract

- Device screenshots are `720x1600` RGBA PNGs.
- The Unity surface occupies the portrait game area; the Samsung navigation bar
  occupies the bottom system region.
- Samsung Game Booster controls, floating avatar bubbles, notifications, server
  time, ping, player names, health values, and nearby players are dynamic regions.
- Raw captures remain local temporary evidence and are not committed because they
  contain account/player overlays and third-party runtime content.
- No purchase, sale, upgrade, equipment removal, account linking/deletion, or
  protected-data access was performed.

## Screen And State Inventory

| Screen | State | Local evidence | Verified observations |
| --- | --- | --- | --- |
| Startup | Loading phase 3/3 | `/tmp/ths-agent-a-after-load.png` | Halloween illustration, title logo, thin progress bar, phase and percent labels |
| Startup | Loading tip | `/tmp/ths-agent-a-post-loading.png` | Dimmed illustration, centered spinner, bordered tip panel with skull ornament |
| Authentication | Register | `/tmp/ths-agent-a-register-clean.png` | Two tabs, Asia26 server label, username/password fields, blue register CTA, orange quick-login CTA |
| Authentication | Login | `/tmp/ths-agent-a-login-tab.png` | Active login tab, username/password fields, blue login CTA, forgot-password link, orange quick-login CTA |
| Authentication | Progress | `/tmp/ths-agent-a-quick-login-result.png` | Checklist-style loading panel over startup illustration and localized tip panel |
| Village HUD | Dead | `/tmp/ths-agent-a-gameplay-entry.png` | Eight-slot hotbar, chat, joystick, compact stat/currency panels, village-respawn CTA |
| Village HUD | Alive | `/tmp/ths-agent-a-respawned.png` | Four stat rows left, three currency/server rows right, five-button left rail, four-button right rail, two consumable buttons |
| Material bag | Empty/locked | `/tmp/ths-agent-a-panel-left-bag.png` | Eight columns, two unlocked rows, three locked rows, title bar and close button |
| Equipment detail | Equipped armor | `/tmp/ths-agent-a-equipment-panel.png` | Cyan item field, orange level badge, HP/speed modifiers, remove/upgrade/sell actions |
| Main menu | Expanded | `/tmp/ths-agent-a-main-menu.png` | Six stacked rows: mail, automation, friends, settings, help, safe exit |
| Settings | Device | `/tmp/ths-agent-a-settings.png` | Music/sound sliders, 60 FPS, movement mode, language, mail |
| Settings | Gameplay | `/tmp/ths-agent-a-settings-controls.png` | Alternating rows of square toggles for name and interaction filtering |
| Settings | Profile | `/tmp/ths-agent-a-settings-account.png` | Account-link form plus destructive and identity actions |
| Settings | Custom HUD layout | `/tmp/ths-agent-a-settings-advanced.png` | Full-screen draggable HUD editor with reset/save and visibility checkboxes |

## Navigation Graph

```text
startup loading
  -> authentication register (default observed tab)
  <-> authentication login
  -> authentication progress
  -> village HUD dead
  -> village HUD alive (respawn)

village HUD alive
  -> material bag
  -> equipment detail
  -> main menu
       -> settings
            <-> device
            <-> gameplay
            <-> profile
            <-> custom HUD layout
```

The graph records only observed transitions. It does not claim full game navigation
coverage.

## Capture Hashes

The local `/tmp` paths are ephemeral; hashes preserve the identity of the exact
files used for this report.

| State | SHA-256 |
| --- | --- |
| Loading phase 3/3 | `2ce391d2ea6bdb20feca993033dd8c36a70fd0dc3d21c635efff8f55372a5234` |
| Loading tip | `96d33d7a613a753ed5dadf5117c6fd1ae1a22f9f124d77abcab37e416bd7e947` |
| Register | `2dfb8fcf6a8fb10b0d9613059142ec6b426b78d5b71aadd43f4980c49afabf6b` |
| Login | `dd1acc5c85a2bd1233fcbb03c1d21091c946703f6a37bac25cd219810c782c24` |
| Authentication progress | `9cb8bd13e5a8c05e674b4313a004ff492acc1c64d2c63fa5deb48fd434fdfdf8` |
| Dead HUD | `cf0b287d1e76534c8ae37f77444972405a3a83d093c1678aac7d4d9aef59c863` |
| Live HUD | `f1e481756a79bf89a6327818b9c794d8c72007810591ea426a7126e98cb63ef0` |
| Live HUD recapture, stat evidence | `913e84cfd09c8d483250b5fbfdac0d0854c1bf2f55651b890b7924061a3bc2b6` |
| Material bag | `1c862f350519db03ce3b376fc8dc77d805bd4566e40960bf920f8e92b61f14f4` |
| Equipment detail | `be578e2fe764b503c1f86257880764c1d08daf1b67c1206af2b74f5615fe6543` |
| Main menu | `dfcb5aa3b4bcd491289b8c4f4a446db514db87011f7d7ef161149f7b3cc0908b` |
| Device settings | `cce39dab7fcdcb56098ad674c990c95f444ff0e3b63594266fe3fb1cdefe50f9` |
| Gameplay settings | `060c1285856599d41a04c70976d645438c6c0c37128adf4720ef796dbd496996` |
| Profile settings | `a4e3b946301b21bcdec48e5688ba60d37f7ff6a8fe26cc1eed852c0956f5a47a` |
| Custom HUD layout | `43cd2b6baf1a5076515c2e15baba74d5b5f80c4659bddbe5c19826b8963a5b71` |

## Verified Visual System

- Pixel UI uses near-black interiors, muted purple-gray panels, gray/white beveled
  borders, orange active tabs, blue primary buttons, red destructive buttons, and
  cream/yellow labels.
- Most reusable panel/button sources are small sprites intended for sliced scaling,
  not full-resolution screenshots.
- The HUD is edge-anchored and intentionally dense. It does not use modern floating
  cards or large rounded mobile controls.
- Gameplay remains visible behind most inventory and item-detail overlays.
- Settings replace gameplay with a full-screen panel and persistent icon tab bar.
- The hotbar has exactly eight visible slots in both live and dead states.

## Selected Local UI Kit

Thirty-seven source images were copied bit-for-bit into
`assets/treasure_hunter/ui/reference/`. Ten authentication/startup resources are
consumed by `sense/ui/mobile/startup_gate.gd`; `panel_stats.png`,
`joystick_ring.png`, `icon_weapon.png`, `icon_power.png`, `icon_health.png`,
`icon_damage.png`, `icon_speed.png`, `icon_gold.png`, `icon_back.png`,
`icon_pet.png`, and `icon_skill.png` are consumed by the mobile HUD. The remaining
resources stay selected references for later HUD and settings work, except the
retained crossed-sword candidate documented below.

| Group | Stable targets |
| --- | --- |
| Branding | `logo_title.png`, `notice_age_18.png` |
| Startup background | `loading_background_halloween.png` |
| Authentication background | `login_background_server.png` |
| Authentication | `login_panel.png`, `login_tab_active.png`, `login_tab_inactive.png`, `login_line.png` |
| Buttons | `button_blue.png`, `button_orange.png`, `button_close.png`, `button_back.png`, `button_menu.png` |
| HUD | `joystick.png`, `joystick_ring.png`, `icon_minimize.png`, `icon_chat.png`, `icon_attack.png`, `icon_weapon.png`, `icon_power.png`, `icon_health.png`, `icon_damage.png`, `icon_speed.png`, `icon_gold.png`, `icon_back.png`, `icon_pet.png`, `icon_skill.png`, `panel_stats.png`, `panel_level.png` |
| Settings tabs | `icon_settings.png`, `icon_gameplay.png`, `icon_profile.png`, `icon_login.png` |
| Custom layout | `layout_back.png`, `layout_bag.png`, `layout_mount.png`, `layout_pet.png` |

Every curated asset has a `local_only` provenance entry in
`docs/architecture/asset-manifest.json`.

The original tab filenames did not describe visual state reliably. Runtime visual
comparison verified that `Login_Tab_0__6356.png` is the yellow active state and
`Login_Tab_1__6566.png` is the gray inactive state; stable target names and manifest
source mappings now reflect the observed appearance.

HUD render comparison also separated two misleading joystick sources:
`Joystick_1__6234.png` is the orange gamepad-style button, while
`Icon_Joystick__5652.png` is the circular directional ring seen around the live
movement thumb. The runtime uses only the verified ring for movement presentation.

The top-right collapse control uses `Icon_Arrow__5990.png`. The four-direction
`Button_MinimizeMode 2__6229.png` candidate was rejected because its silhouette
does not match the captured dot-and-chevron control.

The captured right-rail attack control uses a single diagonal sword silhouette.
`IconSlot_Weapon__1.png` matches that silhouette and is consumed as
`icon_weapon.png`. `IconSlot_Attack__6270.png` contains crossed swords, so it is
retained only as a rejected comparison candidate and is not rendered at runtime.

The fixed navigation rail buttons now reuse the verified sliced `Panel_Stats`
frame. A clean runtime crop directly verifies `IconSlot_Back__1.png`,
`IconSlot_Pet__1.png`, and `IconSlot_Skill__6658.png` as the second, third, and
fourth right-rail silhouettes. They now replace the existing inventory, pet, and
auto-farm presentation while preserving those Emberfield callbacks. The original
semantic meaning of the cape/back control remains unknown and is not inferred.
The left rail keeps its current fallbacks because its callback semantics do not
map cleanly to the observed chat/equipment/movement icons.

A fresh authorized `720x1600` runtime capture verified exact mappings for the
first four left stat rows and the right gold row: `Icon_Power__6088.png`,
`Icon_Health__2.png`, `Icon_Damage__5.png`, `Icon_Speed__25.png`, and
`Icon_Gold__2.png`. These now replace the inferred procedural icons while keeping
all stat values and signals unchanged. The globe/coordinate icon remains a
fallback because no exported source has been proven.

## Missing Evidence

- Startup and authentication have deterministic Emberfield renders at `720x1600`;
  quantitative masked visual-diff thresholds are not yet established.
- Font asset and exact font metrics are not yet linked to the observed labels.
- Sliced-border values and Unity pixels-per-unit settings require metadata or
  controlled reconstruction.
- The globe/coordinate icon and left-rail icons remain unmapped.

## Recommended Integration Order

1. Finish the remaining fixed HUD panels, icons, and stat layout without changing
   gameplay behavior.
2. Add inventory/settings panels only after the shared UI ownership contract is
   agreed with Agent B.
