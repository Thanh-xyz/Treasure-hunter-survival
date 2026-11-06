# Agent A Art Scout Report

Date: 2026-11-04; updated 2026-11-06
Branch/worktree: `feature/th-game-art-workflow` in the Agent A worktree
Stage: SCOUT complete; no project implementation occurred during SCOUT.

## Quest 320 Donx Art Evidence

- Source quest `320` follows `319`, precedes `321`, uses quest type `33`,
  requires NPC `7`, awards Box `98`, and remains disabled. Vietnamese text is
  `Gặp Donx` / `Gặp Donx ở góc trên bên trái của làng`.
- Card `75` identifies Donx as the merge-ingredient NPC. Dialog `625` verifies
  proximity interaction; actual ingredient merging belongs to Quest `321` and
  is not part of the Quest 320 art contract.
- The standalone `Donx` and `Donx Icon` exporter PNGs are transparent because
  their pixels are packed in SpriteAtlas `UINPC`; they are not evidence that the
  source art is missing. The verified atlas is `2048x2048`, SHA-256
  `8d28832bfe609fea976358b4b4b24021fb748c44d6a39ee000d7e5c34881e420`.
- Sprite path ID `5441` restores a `247x196` packed portrait at logical offset
  `(5, 28)` inside its original `256x256` canvas. Sprite path ID `5668` restores
  the full `256x256` icon from atlas bottom-left `(0, 388)`. Both use centered
  pivots; PPU values are `100` and `83.11688232421875` respectively.
- The map NPC is separate: prefab `Donx Body` is a `1.2x` composite RoyalKnight
  hierarchy using the `Unit` Animator, body/limb/eye/clothing/armor/hair parts,
  `Sword_2`, `Shield_Knight_2`, shadow, sorting, and outline support. Neither UI
  image may be used as its world sprite.
- ADB confirmed Treasure Hunter `4.3.7` build `1390` on the connected Samsung
  device, but only the covered server-selection state was available. Exact live
  portrait placement, world scale, idle timing, prompt geometry, and map
  position remain unverified; no pixel-parity claim is made.

## Quest 319 Ingredient Level 2 Evidence

- Source quest `319` follows `318`, precedes `320`, keeps quest type `31`,
  requires `levelRequire: 1`, awards Box `98`, and remains disabled. Vietnamese
  text is `Nâng đá lên Lv2` / `Nâng bất kỳ nguyên liệu nào lên Cấp 2.`
- Source cards `64`, `66`, and `69` are upgradeable Common ingredient templates.
  Each records a static 10 Gold upgrade cost and `upgradeLevelRate: 1.5` in
  `Card.json`. These fields are source evidence only; Emberfield has no approved
  ingredient-instance level, upgrade authority, persistence, or Quest 319 event.
- Unity scene `level1` contains a dedicated `IngredientView` with an ingredient
  grid and selected-item detail: rarity, level, icon, stat rows, description,
  Sell, and a Gold/cost Upgrade button using `HoldButton`. It is distinct from
  `MergeIngredientView`, whose seven input slots, chance, Gold, and Merge action
  serve the later merge flow rather than Quest 319.
- Existing exact local-only identities `item.ingredient.card_64.icon`,
  `item.ingredient.card_66.icon`, and `item.ingredient.card_69.icon` cover the
  three beginner-chain ingredient icons but remain metadata-only.
- ADB verified Treasure Hunter 4.3.7 on the connected `SM_A047F` and captured
  the server-selection state. The active touch-lock overlay prevented navigation
  to `IngredientView`; no direct runtime layout, scale, hold duration, final
  values, or interaction capture is available, and no account resource changed.

## Quest 318 Defense Ingredient Evidence

- Source quest `318` follows `317`, requires one stat-type-4 Defense ingredient,
  awards Box `98`, remains disabled, and uses Vietnamese text `Đào đá Defense` /
  `Nguyên liệu rơi ngẫu nhiên khi đào ô`.
- Card `69` is `Stone_6`, described as adding Defense to equipment; boxes
  `464`-`467` bind it across four source rarities. Box `153` also contains Rare
  Stone_3 x2 and Rare Stone_6 x2 as independent 100-percent CheckBox entries.
- Exact addressable sprite is `25x30`, transparent/partial alpha, SHA-256
  `0c34590bdb5c3d87a633ca09d7701bba8303094b37c9e24558cef624ec30dc06`.
  Pivot, PPU, live scale/frame and gameplay behavior remain unknown; Game
  Booster touch lock prevented direct runtime capture.

## Quest 317 Health Ingredient Evidence

- Source quest `317` follows `316` and requires one stat-type-0 Health
  ingredient. It awards Box `98`, remains disabled, and uses Vietnamese text
  `Đào đá Health` / `Nguyên liệu rơi ngẫu nhiên khi đào ô`.
- Card `64` is `Stone_1`, described as adding Health to equipment; Vietnamese
  description is `Thêm Sinh Mệnh cho trang bị của bạn`. Boxes `444`-`447` bind
  this card to the four source rarities.
- The exact addressable sprite is `28x31`, transparent/partial alpha, with
  SHA-256
  `1aae2b48e70a9591d0977e4c56e0f83049f1e7d4fcb9ddb4fae8d5422ad32a88`.
  Pivot, PPU, live scale/frame, drop behavior, and runtime presentation remain
  unknown; Samsung Game Booster touch lock prevented a direct capture.

## Quest 316 Damage Ingredient Evidence

- Source quest `316` is a disabled beginner-chain objective after `315` and
  before `317`. It requires one stat-type-1 Damage ingredient and awards Box
  `98`; Vietnamese text is `Đào đá Damage` / `Nguyên liệu rơi ngẫu nhiên khi
  đào ô`.
- Card `66` is `Stone_3`, an upgradeable rarity-colored ingredient whose source
  description is `Add damage to your equipment`; its Vietnamese description is
  `Thêm Tấn Công cho trang bị của bạn`. Boxes `452`-`455` bind the same card to
  the four source rarities.
- The selected exact addressable sprite is `29x32`, transparent/partial alpha,
  and SHA-256
  `49e02811b700b5a5c42771d73683852273bbf4d7a458535ea87c31b05ede4a2d`.
  Pivot, pixels per unit, live scale, rarity frame, drop behavior, and runtime
  quest presentation remain unknown.
- ADB confirmed the authorized Treasure Hunter 4.3.7 process, but Samsung Game
  Booster touch lock covered the game during this SCOUT. No live Quest 316
  capture or account-changing action occurred.

## Architecture

Emberfield is an existing Godot 4.6 GDScript project using GL Compatibility,
nearest-neighbor rendering, a `720x1600` portrait viewport, component-based scenes,
autoload services, code-defined content catalogs, and procedural map generation.

The migration preserves legacy inventory, equipment, crafting, shops, combat, and
dungeon systems while adding survival fields, heroes, pets, mounts, quests,
homestead, bosses, saves, mobile UI, and partial host-authoritative LAN play.

## Existing Visual Migration

- Four capture-derived field props are integrated.
- Mosqui, Snailu, and Astromophy extracted sprites are integrated.
- Greenwood ground color is measured as `#3c784a`.
- Mobile startup, HUD, field, inventory, death, and system states have render or
  capture harnesses, but no complete visual-diff certification exists.
- Player heroes still reuse generic soldier art or generated pixel visuals.

## Reference Evidence

The user-supplied `assets-ths` archive is approximately 1.7 GB. Its UnityPy
manifests contain 23,505 valid PNGs: 5,086 Texture2D exports and 18,419 cropped
sprites. All manifest files opened successfully during SCOUT.

Image transparency audit:

- 23,454 RGBA images and 51 RGB images.
- 23,012 images contain transparent or partially transparent pixels.
- 442 RGBA images contain a fully opaque alpha channel.

Unity metadata reports 1,505 AnimationClip objects, 227 AnimatorControllers, 55
AnimatorOverrideControllers, 2,365 ParticleSystems, and 27 AudioClips. Standalone
audio files were not recovered by the current export.

## Reuse Assessment

Strong local-use candidates include monsters, pets, mounts, environment props,
village structures, UI frames/icons, equipment, and item art. Character animation,
particle effects, exact pivots, sockets, tile composition, and audio require more
metadata or reconstruction.

The user has authorized supplied assets for the local/private build. This does not
convert their provenance into a public redistribution license.

## Clone-App Methodology

The external clone-app Skill exists locally but is not installed in this project.
Its Expo scaffold is incompatible with Godot. The applicable method is retained:
screen/state inventory, visual-token extraction, component specification, render,
screenshot, diff, and correction.

## Git And Coordination

- `origin` exposes only `main`; no integration branch exists.
- Agent A and the migration base started at `e8fc3c7`.
- Agent B created `feature/th-logic-inventory-transactions` and began gameplay changes.
- Agent A's first feature does not touch those files.
- The shared coordination directory was missing at SCOUT completion.

## Tooling Evidence

- GitHub authentication succeeds as `Thanh-xyz`.
- No PRs were present during SCOUT.
- ADB later detected an authorized Samsung SM-A047F with
  `com.megacombat.treasurehunter` installed.
- No Godot executable was available on the inspected command path, so Godot tests
  were not run during SCOUT.

## Risks

- Mixed art/gameplay files can create cross-agent conflicts.
- Extracted frames often lack verified pivot, timing, and animation dependencies.
- Documentation is behind the current autoload and portrait architecture.
- Pixel parity cannot be claimed until deterministic Godot renders are available.

## Fixed HUD World/Resource Row Evidence

- Decoded `level1` GameObjects `16955` (`RegionTime`), `27924` (`Map`), and
  `15928` (`Gold`) each resolve their active Unity UI Image sprite pointer to
  `sharedassets1.assets:5844` (`Panel_Stats`). Their RectTransforms are
  `250x70`, and the image color is opaque white.
- `Map/Line` GameObject `6901` and `Gold/Line` GameObject `14793` both resolve
  to `sharedassets1.assets:6099` (`Line`). Each separator is placed at x=75 in
  a `25x65` RectTransform. The source is `16x48` with 20-pixel top and bottom
  borders.
- `RegionTime` has one active text child and no icon or separator child. `Map`
  and `Gold` use a left icon at x=40 in a `55x55` RectTransform and a right
  text region centered at x=171 in a `150x80` RectTransform.
- This supports a presentation-only replacement of inferred panel styling. It
  does not support changing coordinate calculation, LAN role text, local time,
  currency state, or refresh cadence.

## Fixed Hotbar Frame Evidence

- Decoded `InventoryView/InventorySlotUI Slot1/BG` GameObject `20660` and its
  active Unity UI Image component `118143`. The sprite pointer resolves to
  `sharedassets1.assets:6918` (`Button1_0`), not `Panel_Stats`.
- Sprite `6918` is `48x48` with verified 20-pixel borders on all sides. Direct
  UnityPy decoding and the supplied exported PNG are pixel-identical.
- Each of the eight active `Main/ItemUI_Inventory` child Images separately
  resolves to `sharedassets1.assets:5844` (`Panel_Stats`). The current slot
  texture therefore remains correct; only the outer hotbar frame requires
  replacement.

## Fixed HUD XP Bar Evidence

- The decoded `HUDView/Panel/Avatar` hierarchy contains `AvatarUI`,
  `EffectStatusHolder`, and `BuffStatusHolder`; it has no experience bar child.
- The decoded `HUDView/Panel/TopLeft` hierarchy contains health, stat, and
  protection groups; it has no experience bar or XP progress child.
- Authorized live/dead HUD captures also show no bar between the portrait and
  fixed stat stack. Emberfield's blue `_xp_bar` is therefore an inferred visual
  without reference support and should be removed without changing XP state.
- The selected `Panel_Level` source appears in the runtime HUD only at
  `SkillGroup/PotionShortcut/ItemUI/ItemInfo/Level`; it must not be repurposed as
  a player-level or XP frame.

## Beginner Quest Suggestion Evidence

- The authorized runtime capture `/tmp/ths-next-scout-login-progress.png` shows
  the first suggestion as `Đào đất`, progress `0/1`, with a Grass5 icon and the
  Winbee guide character on the right edge.
- Decoded hierarchy
  `UIManager/MainCanvas - Camera/BeginnerQuestView/SuggestionQuestPanel` identifies
  the suggestion panel independently from the full `QuestView/QuestProgressPanel`.
- The popup Image resolves to `sharedassets1.assets:9248` (`F200_50`), a `21x17`
  source with Unity borders left `7`, top `4`, right `6`, bottom `8`, and black
  tint alpha `0.470588`.
- The verified first-quest icon resolves to `sharedassets1.assets:4738`
  (`Grass5`), source size `38x39`.
- The guide character resolves to `sharedassets1.assets:6001` (`Winbee`), source
  size `77x116`. The batch-exported PNG is fully transparent; loading both
  `sharedassets1.assets.split0` and `sharedassets0.assets.split0` recovers the
  valid sprite and its texture dependency.
- `Quest.json` and Emberfield `GameContent.MAIN_QUESTS` both identify `q01` as
  the dig tutorial. Later quest icon mappings remain unverified and must not
  reuse Grass5 by inference.
- No Android device was connected during this feature SCOUT, so the existing
  authorized capture and decoded scene/assets remain the available runtime
  evidence.

## Fixed Joystick Evidence

- No Android device was connected during this SCOUT, so no new runtime capture
  was created or claimed.
- Decoded active GameObject `30170` (`Fixed Joystick`) has a `256x256`
  RectTransform and centered child `30169` (`Handle`) with `128x128` size.
- The active background Image component `130484` resolves through external file
  ID `2` to `sharedassets1.assets:3600`, `F200_Circle_10` (`79x79`), with Image
  tint `Color8(181, 130, 107, 255)`.
- The Handle Image component `130482` resolves to
  `sharedassets1.assets:8030`, `F200_Circle_11` (`34x34`), with opaque white
  tint.
- Direct UnityPy decode is pixel-identical to both supplied exports.
- `Icon_Joystick` (`sharedassets1.assets:5652`) belongs to a separate help/custom
  layout hierarchy and is not the active gameplay joystick background.

## Revive Button Evidence

- Decoded active GameObject `6089` at
  `UIManager/MainCanvas - Camera/HUDView/Panel/Bot/ReviveButton` has a
  `349.1254x111.2323` RectTransform. The established HUD scale maps this to the
  existing Emberfield `254x80` rectangle, so the layout remains unchanged.
- Image component `99195` resolves through external file ID `2` to
  `sharedassets1.assets:6916`, `Button1_0`, a `48x48` sprite with 20-pixel
  borders on every side. The same verified image is already integrated as
  `assets/treasure_hunter/ui/reference/button_orange.png`; the similarly named
  hotbar frame is a visually different `Button1_0` variant at path ID `6918`.
- Button component `99196` uses Unity color transitions over that image: opaque
  white normal, `245/255` highlighted, `200/255` pressed, and `200/255` with
  `128/255` alpha when disabled.
- Runtime localization evidence is insufficient to replace Emberfield's current
  Vietnamese label. Position, size, countdown text, disabled timer, and
  `_respawn_town` callback therefore remain unchanged.

## Fixed Hotbar Geometry Evidence

- Authorized ADB capture `/tmp/ths-hotbar-scout-after-login.png` records the
  active gameplay HUD at the device's native `720x1600` resolution. The Android
  navigation region begins at y=1516 and is external to the game UI.
- Direct pixel inspection places the fixed hotbar frame at x=0, y=1400, with a
  720-pixel width and approximately 116-pixel height. Decoded
  `InventoryView/InventorySlotUI Slot1` independently reports a bottom-anchored
  `1080x166` RectTransform, consistent with a 2/3 width-based CanvasScaler.
- The eight captured slot centers are approximately x=`66+84*i`, y=1458. Each
  framed control is about `78x78`, with a `72x72` near-black interior.
- Before this feature Emberfield rendered the frame at x=4, y=1412 with size
  `712x120`, and rendered `80x80` slots at x centers `68+84*i`, y=1471. The
  source asset and slot order were correct, but the complete group was visibly
  low and slightly oversized.
- ADB UI hierarchy does not expose Unity's internal controls, so the capture and
  decoded RectTransform evidence are used together. No gameplay behavior is
  inferred from these measurements.

## Fixed Joystick Placement Evidence

- Authorized device `SM_A047F` was connected and the package
  `com.megacombat.treasurehunter` was observed at `720x1600`; Android reports
  the Unity game surface as `720x1516` with the final 84 pixels owned by system
  navigation.
- The active runtime capture `/tmp/ths-runtime-joystick-scout.png` places the
  joystick around screen center `(447, 897)`, but the settings flow exposes a
  full-screen custom HUD editor with explicit `Reset` and `Save` actions in
  `/tmp/ths-game-settings-runtime.png`. The runtime coordinate is therefore a
  saved custom layout and is not treated as the canonical default.
- No `Reset` or `Save` action was invoked. The editor was entered and exited
  read-only, so the reference account layout was not changed.
- Decoded `MainCanvas - Camera` uses a `1080x1920` CanvasScaler reference,
  `Scale With Screen Size`, and `matchWidthOrHeight=0.5`. On the verified
  `720x1516` game surface, its scale factor is approximately `0.725527`.
- Active GameObject `30170` (`Fixed Joystick`) is anchored at `(0.5, 0)` with
  anchored position `(0, 542)`, size `256x256`, and pivot `(0.5, 0.5)`. This
  maps its default center to approximately `(360, 1122.76)` and its background
  size to approximately `185.74` pixels.
- Emberfield's existing exact-source visual is `184` pixels and its touch area
  is `238x300`; only the control origin needs to move from `(274,980)` to
  `(241,958)` to place its rest center at `(360,1123)`. Input semantics and the
  established source scaling remain outside this placement correction.

## Box 149 Beginner Weapon Icon Evidence

- `Box.json` ID `149` (`Box Beginner Weapon Common`) is an Option reward with
  card IDs `28`, `29`, and `30` at exact chances `34`, `33`, and `33` percent.
- `Card.json` independently maps these three Common `equipmentType=6` cards to
  `Icons/Items/6_Weapons/Weapons_0`, `Weapons_1`, and `Weapons_2`. Their stat
  ranges are distinct, so one generic icon or existing gameplay alias would
  collapse three separate identities.
- Direct Unity files `f12b282c6f8114427b25c083a7b06ae6`,
  `5fad2197f28434ea184bc586080b8f51`, and
  `e4413bcbcf7024a99b15760a98718778` each contain one Texture2D at path ID `1`
  and one Sprite at path ID `2`. Sprite and texture exports are bit-identical.
- Verified dimensions are `13x21`, `9x20`, and `7x15`; each source has alpha,
  one mip level, 32 pixels per unit, and a distinct normalized pivot recorded in
  the asset manifest.
- Existing Emberfield `wooden_sword`, `iron_sword`, and `battle_axe` IDs and
  atlas icons have no proven one-to-one mapping to cards `28/29/30`. They remain
  separate gameplay identities.
