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
| Equipment detail | Equipped pet accessory, live recapture | `/tmp/th-quest315-equipment-detail-live.png` | `Cấp 1 (Tối đa 10)`, property markers, item field, timed modifiers, description, and `Tháo`/`Nâng cấp`/`Bán`; no action invoked |
| Main menu | Expanded | `/tmp/ths-agent-a-main-menu.png` | Six stacked rows: mail, automation, friends, settings, help, safe exit |
| Settings | Device | `/tmp/ths-agent-a-settings.png` | Music/sound sliders, 60 FPS, movement mode, language, mail |
| Settings | Gameplay | `/tmp/ths-agent-a-settings-controls.png` | Alternating rows of square toggles for name and interaction filtering |
| Settings | Profile | `/tmp/ths-agent-a-settings-account.png` | Account-link form plus destructive and identity actions |
| Settings | Custom HUD layout | `/tmp/ths-agent-a-settings-advanced.png` | Full-screen draggable HUD editor with reset/save and visibility checkboxes |
| Village HUD | Post-tutorial account, alive | `/tmp/th-post-tutorial-live-hud.png` | Mounted character, pet, eight-slot hotbar, expanded currencies and high-level equipment; this is not a default-account state |
| Quests | Main | `/tmp/th-post-tutorial-quest-tab-1.png` | One active quest, queued next quests and completed section; captured account state is PvP `0/2` |
| Quests | Daily | `/tmp/th-post-tutorial-quest-panel.png` | Daily-point reward rail, rerollable objective cards and reset timer; no reroll or claim was performed |
| Quests | Login rewards | `/tmp/th-post-tutorial-quest-tab-3.png` | Day milestone rail, free/paid tracks and locked rows; no reward was claimed |
| Quests | Achievements | `/tmp/th-post-tutorial-quest-tab-4.png` | Achievement-point milestones and boss objective cards; no reward was claimed |
| Character | Overview and inventory | `/tmp/th-post-tutorial-character-panel.png` | Eight equipment positions, character preview, wallets, stats, skin row and eight-column inventory |
| Character | Inventory item detail | `/tmp/th-post-tutorial-inventory-item-detail.png` | Item rarity field, level, class restrictions, stat modifiers and equip/upgrade/sell actions; no action was invoked |
| Character | VIP progress | `/tmp/th-post-tutorial-character-tab-2.png` | Tier cards, benefits, monthly/daily reward rows and locked state |
| Character | Equipment-set editor | `/tmp/th-post-tutorial-character-tab-3.png` | Three presets, visual-effect slots, equipment loadout and Save action; no preset or Save action was invoked |
| Collection | Effect preview | `/tmp/th-post-tutorial-collection.png` | Central character preview, attack/run/idle selectors, category tabs, rarity/cost and eight-column grid |

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
  -> character overview
       <-> VIP progress
       <-> equipment-set editor
       -> inventory item detail
  -> collection effect preview
  -> main menu
       -> quests
            <-> main
            <-> daily
            <-> login rewards
            <-> achievements
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
| Equipment detail, live recapture | `61bcddaddf7ae747970449b3fe2a845a75669258cdbeecd61a862205a4b0af14` |
| Main menu | `dfcb5aa3b4bcd491289b8c4f4a446db514db87011f7d7ef161149f7b3cc0908b` |
| Device settings | `cce39dab7fcdcb56098ad674c990c95f444ff0e3b63594266fe3fb1cdefe50f9` |
| Gameplay settings | `060c1285856599d41a04c70976d645438c6c0c37128adf4720ef796dbd496996` |
| Profile settings | `a4e3b946301b21bcdec48e5688ba60d37f7ff6a8fe26cc1eed852c0956f5a47a` |
| Custom HUD layout | `43cd2b6baf1a5076515c2e15baba74d5b5f80c4659bddbe5c19826b8963a5b71` |
| Post-tutorial live HUD | `005075ff0326e34867e26aa62fc4c9ee1cf3d805a6478240d66e4013ba47cddc` |
| Main quest tab | `4bdcdc90b63b3fcd66b1561bfd236271a97c640351d430ecf9f44178827ec437` |
| Daily quest tab | `0258849d3a85239d42d8d43cbb3355f17fb752bda38d4111508e26ef9b3e6691` |
| Login-reward tab | `6c3755b757dafab56f77ebf76ea4371f32c79d037f3f46f01e94a087e5986493` |
| Achievement tab | `00a89d2d55116d12380b04496a21d1f184574b19d87ebe9705a598797ef5503f` |
| Character overview | `4b5b00e012ab045f098f9cfd015e51f9ed9540ee2eb03e41b9e066807b62881e` |
| Inventory item detail | `df3e179b9027389e734f20bf1fed86246ed5b932740113464da23ee7f4e53763` |
| VIP progress | `f920d936386b32e5e5c53e5c49880ac28f32cb14c180f817621e5141c1faedfc` |
| Equipment-set editor | `43371f9e28741e08d56af0ae30bf1b910fda2057846279529c222f76304dc22d` |
| Collection preview | `fd20e96fdaaf57337bce6b7d31bf5dd7438b472e91a07252a48035ff22e76e0c` |

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

Fifty-five source images were copied bit-for-bit into
`assets/treasure_hunter/ui/reference/`. Ten authentication/startup resources are
consumed by `sense/ui/mobile/startup_gate.gd`; `panel_stats.png`,
`joystick_ring.png`, `icon_weapon.png`, `icon_power.png`, `icon_health.png`,
`icon_damage.png`, `icon_speed.png`, `icon_gold.png`, `icon_back.png`,
`icon_pet.png`, `icon_skill.png`, `icon_map.png`, `portrait_frame.png`, and
`portrait_border.png`, and `stat_line.png` are consumed by the mobile HUD. The remaining
resources stay selected references for later HUD and settings work, except the
retained crossed-sword candidate documented below.

| Group | Stable targets |
| --- | --- |
| Branding | `logo_title.png`, `notice_age_18.png` |
| Startup background | `loading_background_halloween.png` |
| Authentication background | `login_background_server.png` |
| Authentication | `login_panel.png`, `login_tab_active.png`, `login_tab_inactive.png`, `login_line.png` |
| Buttons | `button_blue.png`, `button_orange.png`, `button_close.png`, `button_back.png`, `button_menu.png` |
| HUD | `joystick.png`, `joystick_ring.png`, `icon_minimize.png`, `icon_chat.png`, `icon_attack.png`, `icon_weapon.png`, `icon_power.png`, `icon_health.png`, `icon_damage.png`, `icon_speed.png`, `icon_gold.png`, `icon_map.png`, `icon_back.png`, `icon_pet.png`, `icon_skill.png`, `portrait_frame.png`, `portrait_border.png`, `stat_line.png`, `panel_stats.png`, `panel_level.png` |
| Settings tabs | `icon_settings.png`, `icon_gameplay.png`, `icon_profile.png`, `icon_login.png` |
| Custom layout | `layout_back.png`, `layout_bag.png`, `layout_mount.png`, `layout_pet.png` |
| Quest menu | `quest_panel_normal.png`, `quest_panel_claim.png`, `quest_section_label.png`, `quest_list_panel.png`, `quest_tab_active.png`, `quest_tab_inactive.png`, `quest_icon_main.png`, `quest_icon_daily.png`, `quest_icon_achievement.png` |

Every curated asset has a `local_only` provenance entry in
`docs/architecture/asset-manifest.json`.

The post-tutorial quest session was captured from the user's existing account.
Its progress, unlocked systems, inventory and currencies are account-state
evidence only; they are not treated as the default new-player profile.

The 2026-11-06 equipment-detail recapture used the same saved account after an
authorized login. It confirms the item-detail composition and visible `100`
upgrade cost for that one selected live item. No Remove, Upgrade, Sell, Claim,
settings, or account action was invoked. The selected item identity, exact cost
derivation, currency binding, and `HoldButton` behavior remain unknown.

## Quest Menu Visual Contract

The decoded `level1` hierarchy places the captured screen under
`DailyQuestsView/Panel`. Its tab group contains `MainQuestPanel`,
`DailyQuestPanelV2`, `LoginGiftPanelV2`, and `AchievementPanelV2`; the observed
main/daily/login/achievement states correspond to those four panels.

- The selected and unselected tab frames resolve to `UITab1_0` and `UITab2_0`.
- Main, daily and achievement icons resolve to `IconSlot_MainQuest`,
  `IconSlot_DailyQuest`, and `IconSlot_Achievement`. The login tab reuses the
  already selected `IconSlot_Login` asset.
- The active main-quest card frame resolves to `Panel_Nomal`; its claim-ready
  sibling resolves to `Panel_Claim`. The claim-ready state was not activated on
  the observed account, so only its scene identity is verified.
- Both queued-next and completed-list containers resolve to `Panel2_0` with
  20-pixel Unity slice borders. Their section headers reuse `panel_1`, tinted
  near-black by the runtime Image components.
- `BG_1` is referenced by internal quest/reward fill Images but its exported
  file is an opaque white `8x8` region whose final appearance depends on runtime
  context. It is intentionally excluded from the selected kit rather than
  assigned unsupported final colors.

The original tab filenames did not describe visual state reliably. Runtime visual
comparison verified that `Login_Tab_0__6356.png` is the yellow active state and
`Login_Tab_1__6566.png` is the gray inactive state; stable target names and manifest
source mappings now reflect the observed appearance.

HUD render comparison initially separated two misleading joystick sources:
`Joystick_1__6234.png` is the orange gamepad-style button and
`Icon_Joystick__5652.png` is the help/custom-layout joystick icon. Subsequent
scene-pointer decoding proved that neither is the active movement control. The
active `Fixed Joystick` uses `F200_Circle_10` as its `256x256` background and
`F200_Circle_11` as its centered `128x128` Handle; both are now rendered by the
runtime movement control.

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
all stat values and signals unchanged. The globe/coordinate icon was subsequently
traced through the decoded scene to `F200_389` and integrated as `icon_map.png`.
The portrait frame was likewise traced to `F200_1_41`; its nested background is
the already integrated `Login_Panel_0` source, and its active foreground overlay
is `BorderAvatar` rather than the inactive `Frame_Default_0` sibling.
Every active fixed stat row uses `Panel_Stats` plus the `Line` separator between
its icon and value; both Unity border definitions are preserved in the HUD.

## Missing Evidence

- Startup and authentication have deterministic Emberfield renders at `720x1600`;
  quantitative masked visual-diff thresholds are not yet established.
- Font asset and exact font metrics are not yet linked to the observed labels.
- Sliced-border values and Unity pixels-per-unit settings remain incomplete for
  UI sources that have not yet been traced through scene metadata.
- The left-rail icons remain unmapped to compatible Emberfield callbacks.

## Recommended Integration Order

1. Finish the remaining fixed HUD panels, icons, and stat layout without changing
   gameplay behavior.
2. Add inventory/settings panels only after the shared UI ownership contract is
   agreed with Agent B.
