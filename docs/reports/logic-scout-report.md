# Logic Scout Report

## 2026-11-06 — Quest 311 / Equip Rare Equipment

- Authorized Quest `311` follows `310` and precedes `312`. It is type `30`, requires one equipped
  item with raw `rareRequire: 1`, awards Box `98`, and uses Vietnamese `Mặc trang bị Rare` /
  `Độ hiếm của vật phẩm được xác định bằng màu sắc`.
- The recovered beginner chain and q314 establish raw rarity order Common `0`, Rare `1`, Epic `2`.
  Emberfield deliberately retains its additional Uncommon tier, so q311 must normalize to
  `ItemData.ItemRarity.RARE` rather than copying raw integer `1`.
- Existing `InventoryData.count_equipment_at_or_above_rarity()` and QuestService
  `equipped_rarity` evaluate authoritative current equipment state. They already reject invalid
  targets and count Rare-or-better equipment; no event counter or UI-derived progress is needed.
- Box `98` is already a retry-safe one-Diamond authority. The generic quest menu and Agent A's
  integrated Common/Rare/Epic/Legendary field colors already present the required state without a
  new asset or callback.
- Source Snailu Card `34` drops Rare Card `161` (`Back_8`), which naturally feeds this tutorial, but
  Emberfield has no back equipment type/slot/save/UI contract and no Agent A stable Back_8 art ID.
  Q311 itself accepts any Rare item, and the existing Rare `fire_blade` is sufficient for a focused
  quest slice; Card 161 remains separately gated.
- Public wiki data conflicts with the authorized local Card config for Snailu loot, indicating
  version drift. Local config remains the source of truth. ADB is still blocked at server selection,
  so exact live completion timing and whether higher tiers qualify remain unobserved.
- Agent A's Quest 324 Elixir catalog is metadata-only and disjoint. Shared runtime edits for q311
  are limited to the quest row and legacy index migration.

## 2026-11-06 — Quest 310 / Defeat Snailu

- Source Quest `310` follows `308` directly because `309` is empty/disabled. It uses
  `KillMobSpecific`, targets Card `34` exactly three times, awards Box `98`, and uses Vietnamese
  `Đánh bại Snailu` for both title and description.
- Card `34` verifies 200 HP, 30 damage, raw stats `0.3` and `0.5`, a 240-second prefab lifetime,
  collider radius `0.75`, and death Box `34` with 40-50 Gold plus Rare Card `161`. The official
  wiki independently places Snailu in Green Zone and summarizes 50 Gold/Rare Equipment.
- Recovered prefab structure supports a moving melee actor, source range `1.75`, target radius `5`
  and an inferred 1.0-second attack gate from raw/base timing values. At the approved 40 PPU those radii map to 70px, 200px
  and a 30px collider. Exact movement conversion, hit frame, spawn count/coordinates and lifetime
  semantics remain unknown.
- Agent A's exact `actor.monster.snailu.atlas` contains 21 centered 64x64 frames and verified
  idle/move/attack/death clips. The move sequence's second key is source `Idle_1`, not `Run_1`.
- Emberfield's legacy `shroom` ID displays a static Snailu icon but has unrelated stats and spawns.
  It remains untouched; the reference encounter uses additive stable gameplay ID `snailu`.
- Card `161` has source stat ranges and external art but no approved manifest/runtime item identity.
  The first implementation slice therefore includes verified Gold only and defers Rare equipment.
- Agent A's Quest 323 work is metadata-only in Agent A-owned files and has no gameplay overlap.

## 2026-11-06 — Quest 308 / Upgrade One Equipment To Level 2

- Source Quest `308` follows `307`, points directly to `310`, uses quest type `39`, requires one
  equipment item with raw `levelRequire=1`, and awards Box `151`. Vietnamese text is `Nâng cấp
  trang bị` / `Nâng cấp bất kỳ trang bị nào lên Cấp 2`.
- Cross-quest evidence proves the source level field is zero-based: Quest 312 raw `4` displays
  Level 5, while Quest 315 raw `2` displays Level 3. Emberfield therefore uses displayed target
  Level 2 rather than copying raw value `1` into the objective.
- Box `151` contains exactly Gold currency ID `1` x200 and is already covered by the immutable
  reward-box catalog. Quest `309` is an empty disabled node; Quest `310` declares `308` as its
  previous quest, so q308 does not route through q309.
- Emberfield already implements current-state `equipment_level` evaluation, authoritative equipped
  item upgrades, save persistence, post-transition refresh, retry-safe claims, and the integrated
  Equipment Detail presentation. No new event, model, schema, asset, UI or LAN message is needed.
- Generic Emberfield upgrade costs/stat growth remain explicitly provisional and Box 149 reference
  weapons remain locked. Activating q308 does not establish formula parity or authorize either
  contract to change.
- Agent A's Quest 321 work is documentation-only and does not overlap q308 source/tests.

## 2026-11-06 — Quest 307 / Equip Three Items

- Source Quest `307` follows `306`, precedes `308`, uses quest type `30`, requires exactly three
  currently equipped items, and awards Box `98`. Vietnamese text is `Mặc trang bị` / `Trang bị
  bất kỳ vật phẩm nào`.
- The singular localized description does not override the authoritative `minNumber=3` and
  `maxNumber=3`. Cross-quest evidence for type `30` confirms this is a current equipment-state
  check rather than an accumulated equip-action counter.
- Emberfield already implements `InventoryData.count_equipped_items()`, QuestService objective
  `equipped_count`, deferred refresh after equipment changes/save hydration, transition-time
  objective refresh, stable quest IDs, and retry-safe Box `98` rewards.
- No new data model, equipment event, UI callback, asset, animation, manifest entry, LAN message,
  or save field is required. The safe feature is additive quest registration plus legacy-index
  translation and regression tests.
- Post-completion behavior after unequipping is not directly evidenced. Emberfield's existing
  ready-state latch is preserved rather than introducing a speculative rollback rule.
- Agent A's Quest 320/Donx work is read-only SCOUT and has no active diff or dependency on q307.

## 2026-11-06 — Quest 306 / Turtle

- Source quest `306` follows `305`, uses `KillMobSpecific`, targets Card/Mob `33` once, and
  awards Box `98`. The verified Vietnamese objective is `Đánh bại Turtle` / `Đánh bại Rùa`.
- Card `33` and recovered behavior verify Health `100`, Damage `20`, Speed `0`, no movement or
  chase, melee attack enabled, effective attack gate `1.0s`, source attack range `1.75`, and
  target radius `5`. The approved `40 PPU` art contract converts the radii to `70px` and `200px`.
- Agent A already integrated stable ID `actor.monster.turtle.default` with a `384x256` atlas,
  `64x64` frames, and verified `idle`, `move`, `attack`, and `death` sequences. Turtle has no
  directional animation set.
- Emberfield already supports stable kill-target quests, retry-safe Box `98`, monster IDs in LAN
  snapshots, and death-event progression. It lacked a generic non-directional atlas adapter and
  a stationary melee profile.
- Exact source spawn coordinates, collision footprint, hit-frame event, XP, loot, and the prefab's
  `120s` lifetime semantics remain unknown. One Greenwood spawn is therefore a documented local
  playability assumption, not a parity claim.
- Agent A's concurrent Quest 319 work is documentation-only. No active Agent A diff overlaps the
  gameplay files in this feature.

## 2026-11-06 — Quest 305 Box 149 activation

- Source quest 305 is a main-chain type-29 objective after 335 and before 306. It requires exactly
  ten digs and awards Box 149; Vietnamese text is `Đào đất` / `Di chuyển đến bất kỳ ô nào và đứng
  yên để đào`.
- Emberfield `q01` already represents source quest 335 with one dig and Box 150's 100 Gold, but
  previously advanced directly to clean-room `q02`. Dig events and stable quest-ID persistence are
  already implemented.
- Box 149 card selection, Common stat generation, exact equipment materialization and durable
  pending-claim retry are all integrated prerequisites. The missing boundary was resolving a
  random quest reward once before journal preparation.
- Existing saves with stable quest IDs can survive insertion by ID. Legacy index-only saves need
  a one-position shift after q01 so old progress does not move backward into newly inserted q305.
- Agent A's active Equipment Detail work modifies only inventory presentation files. The planned
  quest/gameplay files and minimal Game Menu reward-preview hook have no direct overlap.

## 2026-11-06 — Box 149 initial Common stat generator

- Authorized 4.3.6 ARM64 IL2CPP analysis verifies the real Option-claim path calls the normal
  Common constructor with `isAllStat=false`; the preview-only all-stat path is not used.
- The outer `Next(0, 1000)` suppresses two independently drawn stat indices for `0..499`, one
  for `500..899`, and none for `900..999`. Duplicate suppression indices are valid, producing
  one/two/three non-zero stats with probabilities `1/3`, `17/30`, and `1/10`.
- Non-suppressed values use the lowest quarter of each card range at 0.001 precision with an
  exclusive integer upper bound. The special random-multiplier path is card `2233` only and
  does not apply to cards 28/29/30.
- Existing reward materialization and pending-claim persistence already carry exact stat
  dictionaries, so no save-schema, quest-service or game-state change is required. A generated
  reward must be finalized before journal preparation to prevent retry rerolls.
- Agent A's rarity-field work is integrated and paused. No active art dependency or source-file
  overlap exists; quest 305 activation and combat-stat consumption remain separate features.

## 2026-11-06 — Treasure Hunter `RandomType` semantics

- The authorized `global-metadata.dat` is valid Unity 6 IL2CPP metadata version 108. Direct
  metadata decoding identifies `MCP.DataModels.BaseModels.RandomType` with enum fields
  `Option = 0` and `CheckBox = 1`; the relevant server methods are owned by `BattleManager`:
  `GetItemPacksFromBox`, `GetItemPackFromRandomPacks`, `GetValidRandomPacks`,
  `GetRandomPacks`, and `GetAllPossibleRandomPacks`.
- `Box.json` contains 634 Option boxes and 201 CheckBox boxes. CheckBox entries use only whole
  chances 50 or 100 in the inspected data, while Option entries are relative weighted choices
  and may use fractional weights.
- Box 149 is Option with weapon cards 28/29/30 at 34/33/33, confirming exactly one result.
  Box 153 is CheckBox with card 66 x2 and card 69 x2, both at 100, confirming both results are
  granted independently rather than selecting one.
- The next safe implementation slice is a mutation-free CheckBox resolver with injected RNG,
  validation-before-roll and additive reward merging. Registering Box 153 remains deferred until
  Stone_3 and Stone_6 have canonical gameplay and asset identities.

## 2026-11-06 — Verified currency reward-box catalog

- The beginner chain is strictly ordered from active quest 335 to quest 305 and then Turtle quest
  306. Quest 305 cannot be skipped, and its Box 149 cannot be migrated until card IDs 28/29/30
  receive canonical weapon identities.
- Reference boxes 98, 150, 151 and 152 are independently complete: one Diamond, 100 Gold, 200
  Gold and 300 Gold respectively, each with a single 100-percent entry.
- These four definitions can safely enter an isolated gameplay catalog without changing the active
  quest chain. Moving quests to random box IDs remains deferred until claim retries persist a
  materialized reward instead of allowing rerolls.

## 2026-11-06 — Weighted reward box resolver scout

- Reference box 149 is a guaranteed single selection across card IDs 28/29/30 with whole
  weights 34/33/33. It is not an enemy drop table and has no no-drop outcome.
- Existing `LootTable` is item-only, uses global RNG, supports repeated rolls and includes a
  no-drop weight. Reusing it would conflate enemy loot with quest reward-box semantics.
- `DigSpot` demonstrates the correct seeded `RandomNumberGenerator` ownership pattern, but its
  selector is coupled to field rewards, quantity ranges and fallback stone.
- The safe prerequisite is a standalone resolver that validates normalized reward dictionaries
  and accepts caller-owned RNG. Box 149 content remains blocked on canonical identities for its
  three distinct Common weapon cards.

## 2026-11-06 — Diamond wallet scout

- Authorized reference configs define Gold as currency ID 1, Diamond as currency ID 2, and
  beginner reward box 98 as exactly one Diamond.
- Emberfield previously stored only Gold in `InventoryData`; item and Gold changes already used
  one atomic transaction, save inventory contained `gold`, `slots` and `equipment`, and no
  Diamond state existed.
- The full beginner-chain reward migration therefore depends on a real Diamond wallet. Modeling
  Diamond as an item would contradict the reference; placing it in `GameState` would split the
  wallet and break mixed-reward atomicity.
- Agent A's fixed-joystick feature is integrated and has no overlap with the gameplay wallet,
  save service or tests. No open PR was present at feature start.
- LAN accepts only `item`, `gold` and `xp` reward kinds, and the fixed HUD displays only Gold.
  Both are explicit later contracts, not implied capabilities of the offline wallet.

## 2026-11-06 — Active dig tutorial correction

- Direct runtime evidence shows the visible `Đào đất` objective at `0/1`.
- Static quest ID 335 is active, requires one dig and leads to ID 305; ID 305 requires ten digs
  but is marked inactive. The prior proposal to change q01 to ten was therefore withdrawn.
- Active ID 335 rewards box 150, whose only payload is exactly 100 Gold. Emberfield's existing
  30 XP + 50 Gold reward was provisional and contradicted this direct config chain.
- The safe slice retains q01 ID/count/presentation and corrects only its reward to 100 Gold.

Date: 2026-11-04
Branch/worktree: `feature/th-game-logic` at `e8fc3c7`
Stage: SCOUT only; no gameplay implementation has started.

## Scope and evidence

The investigation covered the complete tracked Emberfield tree, project configuration,
architecture and workflow documents, current migration commits, both local agent worktrees,
the extracted Treasure Hunter 4.3.6 resources, remote Git refs, test harnesses, GitHub CLI
state, and ADB state.

Important constraints:

- The paths supplied as `/home/Documents/...` resolve locally under
  `/home/thanh/Documents/1.Projects/...`.
- No root `AGENTS.md`, shared Treasure Hunter workflow `SKILL.md`, or
  SCOUT -> BRAINSTORM workflow document exists in the fetched repository.
- `gh auth status` identifies an active `Thanh-xyz` login. GitHub inspection returned no open
  PR or issue and no additional repository integration branch.
- `git fetch --all --prune` completed. `origin/main` remains at `e8fc3c7` and no additional
  origin branches were advertised.
- ADB is installed, but no device or emulator is connected.
- No Godot executable was preinstalled. A Godot 4.6 binary was later downloaded to `/tmp` for
  feature testing without changing project dependencies.

## Current Emberfield architecture

Emberfield is a Godot 4.6 GDScript project with a `720x1600` portrait logical viewport and a
`360x800` test window. The runtime is component-based at the scene level, but several newer
survival systems are global-service and dictionary driven.

| Layer | Current implementation | Notes |
| --- | --- | --- |
| Entry/orchestration | `sense/main.gd`, `SceneTransitionService` | Loads profile, HUD, maps and local/LAN startup gate. |
| Static content | `GameContent`, `ItemDatabase`, `RecipeDatabase`, `SkillDatabase` | Content is split across four code-defined catalogs. |
| Player/profile state | `GameState`, `CharacterStats`, `InventoryData`, `QuestService` | Profile and inventory are separate but connected through global player lookup. |
| Combat | `Combat`, hitbox/hurtbox/health components, player/monster scripts, skill runners | Both legacy component combat and newer direct `apply_hit` paths coexist. |
| Actors | `player.gd`, legacy skeleton, data-driven `Monster`/`Boss`, pets | `player.gd` is a 1,476-line controller; `Monster` is 602 lines. |
| World | town, procedural dungeon, deterministic fields, homestead | Scene transitions are centralized; field content is code generated. |
| Presentation | legacy HUD/inventory/crafting plus portrait mobile HUD/menu | New UI adapts rather than replaces the existing panels. |
| Persistence | `SaveService` | Version 1 JSON, temporary file + backup, autosave and inventory serialization. |
| Networking | `LanSession`, `LanRemoteAvatar` | ENet host/client foundation with host-owned enemy HP, player vitals and loot transactions. |
| Tests | legacy, survival and multi-process LAN harnesses | Custom scene runners; CI currently builds Windows only on PRs to `main`. |

Autoloads include collision, interaction, events, items, scene/camera services, crafting,
skills, notifications, dialogs, state, quests, save, and LAN session. This is functional but
means domain rules frequently depend directly on the Godot scene tree and global singletons.

## Current migration progress

The migration is already a substantial vertical slice rather than an empty shell:

- Commit `345beee` added local progression, three heroes, pets, mounts, quests, field zones,
  homestead buildings, save/load, bosses, portrait controls and survival tests.
- Commit `e8fc3c7` added curated source-derived vegetation and three monster sprites, ground
  digging, a startup mode gate, extensive LAN synchronization, visual harnesses and device
  capture tooling.
- Existing Emberfield systems remain available: 32-slot inventory, seven equipment slots,
  augments, timed buffs, equipment skills, crafting recipes, shops, procedural dungeon and
  component hitbox/hurtbox combat.
- LAN currently synchronizes handshake, avatars, host zone, enemies, enemy hits, loot capacity
  acknowledgement, player HP/death/respawn, combat profiles and health potion authority.
- LAN does not yet own equipment, crafting, selling, chests, gathering, digging, stamina,
  timed buffs, per-peer quests, pets, mounts, reconnect migration or persistent world state.
- PvP rules are not implemented despite the reference containing arena/PvP evidence.

## Reference resource findings

`assets-ths` is a 1.7 GB static extraction of Treasure Hunter Survival 4.3.6:

- Unity `6000.6.2f1`, ARM64 IL2CPP, package `com.megacombat.treasurehunter`.
- 828 game-specific Assembly-CSharp types, 50,985 MonoBehaviour instances and 30,231 scene
  GameObjects were indexed.
- 23,505 valid PNGs were exported: 5,086 textures and 18,419 sprites.
- Extracted data includes 3,752 cards, 835 boxes, 567 quests, 121 items, 149 character titles,
  98 events, 57 currencies, four arena definitions and network/RemoteConfig metadata.
- Static identifiers confirm combat abilities, buffs/debuffs, poison, shields, summons,
  character equipment/inventory/wallet/pets/mounts, crafting/upgrading/selling, quests,
  world/building systems and arena/PvP.
- Mirror, KCP, Telepathy and SimpleWebTransport are present, but the authoritative server
  implementation and original C# source are not present in the XAPK.

The extraction is evidence, not production source. It contains compiled native code,
metadata, client RPC stubs, raw configuration and assets. It does not provide a safe module
that can be copied into Godot.

## Reusable material and dependencies

| Material | Reuse decision | Required adaptation/dependency |
| --- | --- | --- |
| Extracted JSON configs | Reuse as reference fixtures and schema evidence | Build import/normalization tools; map numeric IDs/enums; reject service/IAP-only records. |
| Class/identifier catalogs | Reuse for feature inventory and naming evidence | Treat names as evidence only; no formulas can be inferred from identifiers alone. |
| Scene/script usage tables | Reuse to identify states, managers and component relationships | Validate against runtime capture before reproducing behavior. |
| Curated sprites already in repo | Reuse locally, subject to distribution rights | Agent A owns selection, manifests and animation metadata. |
| XAPK client code | Do not copy | IL2CPP native output is not source and omits server authority. |
| Existing Emberfield inventory/components | Reuse and characterize | Preserve public methods/signals while extracting domain services behind adapters. |
| `GameContent` and survival systems | Reuse as provisional clean-room implementation | Mark unverified values; replace only when reference evidence is sufficient. |
| `SaveService` and LAN harnesses | Reuse as foundations | Add validation/version migrations and separate transport from authority/domain commands. |

The extracted `Item.json` is mostly boxes, VIP/service entitlements, blueprints and offers; it
is not a direct equipment catalog. Equipment and balance evidence appears more likely in the
3,752 `Card` records and MonoBehaviour data and needs a dedicated mapping pass.

## Existing gameplay systems and gaps

### Character and progression

Implemented: local identity/name, hero selection, HP/stamina, level/XP, eight-direction
movement, six player states including digging, equipment bonuses, pets, mounts and buildings.

Gaps/risks: no mana model, progression numbers are explicitly provisional, hero IDs are
clean-room concepts rather than confirmed Treasure Hunter IDs, and profile rules are coupled
to global state and the live player node.

### Combat

Implemented: basic attacks, equipment and hero skills, random variance, fixed global critical
chance, defense subtraction, cooldowns, timed buffs/passive effects, PvE, boss mechanics,
projectiles and LAN-hosted enemy/player damage.

Gaps/risks: no PvP, no resistance model, RNG is not injectable/deterministic, and critical
logic exists in both `Combat` and `PassiveEffectProcessor`. Direct `apply_hit` calls coexist
with hitbox/hurtbox events, increasing the risk of divergent rules.

### Monsters

Implemented: data definitions, melee/flyer/ranged/charger AI, targeting, telegraphs, attacks,
damage, death, respawn camps, loot, elites and two-phase bosses.

Gaps/risks: the generic IDs `slime`, `shroom` and `boar` display Mosqui, Snailu and
Astromophy. This semantic mismatch will cause asset/data contract confusion unless aliases or
canonical IDs are agreed with Agent A.

### Inventory, equipment and crafting

Implemented: stacking, categories, seven slots, rarity, equipment stats, augments, active and
passive effects, ten tiered crafting recipes, validation and production.

Gaps/risks: no reference-grounded enhancement/upgrade or set-bonus model, duplicated slot
string lists across files, and mutable `ItemData` instances require careful copying for
per-item augments.

### Quests and world

Implemented: 15 main quests, three daily quests, rewards, unlock levels, exploration events,
resource gathering, digging, field bosses and homestead production.

Gaps/risks: these are clean-room/provisional rather than mapped from the 567 reference quests;
world state is only partially persisted.

### Save and recovery

Implemented: versioned snapshot, atomic-style temporary write, previous-save backup,
autosave, profile/quest/inventory/equipment/HP restore and corrupt-primary fallback.

Gaps/risks: version migration is a placeholder, there is no explicit schema validation,
checksum, save-result validation, world-state snapshot or per-player LAN profile store.

## Git, GitHub and Agent A status

- Logic worktree: `feature/th-game-logic`, clean before these reports, tracking `origin/main`.
- Agent A worktree: `feature/th-game-art-workflow`, clean at `e8fc3c7`, no commits or working
  tree changes beyond the common base.
- Emberfield worktree: `feat/survival-rpg`, clean at `e8fc3c7`.
- `origin/main`, both agent branches and `feat/survival-rpg` are currently identical.
- `main` points to upstream Emberfield `e4de441`; it is not the current migration base.
- Fetch found no dedicated integration branch on `origin`.
- GitHub authentication is valid; no open PR or issue was returned during the latest check.

## Potential conflicts

The highest-risk shared files are:

- `sense/globals/game_content.gd`: gameplay definitions mixed with asset keys/palettes.
- `sense/entities/player/player.gd`: gameplay state, animation, input, visuals and networking.
- `sense/entities/enemies/monster/monster.gd`: AI/combat plus sprite construction/scaling.
- `sense/globals/pixel_art.gd`: art-owned runtime visuals referenced by gameplay IDs.
- `sense/maps/field/field_map.gd` and `world_props.gd`: spawn/gameplay and art layout overlap.
- `project.godot`: autoloads, input mappings and display settings.
- `docs/survival_rpg.md`: both gameplay and visual status are documented together.

No edits to these files should begin until Agent A publishes the shared workflow and agrees to
the contracts in `docs/handoffs/logic-to-art.md`.

## Scout conclusion

The safest strategy is not a rewrite and not a bulk copy from `assets-ths`. Preserve the
working vertical slice, characterize it with executable tests, freeze cross-agent IDs, then
extract deterministic domain rules behind the existing Godot-facing APIs. Reference data
should enter through reviewed adapters and an evidence ledger, with every value labelled
confirmed, inferred or provisional.

## 2026-11-06 — Beginner quest equipment-objective scout

The authorized `Quest.json` confirms the early chain `305 -> 306 -> 307 -> 308 -> 310 ->
311 -> 312 -> 313 -> 314 -> 315`. Within that sequence, quest type `30` checks equipped item
count/rarity and type `39` checks the current count of equipment at a required level. The
Vietnamese descriptions explicitly require three equipped items, one Rare item, one Epic item,
one item at displayed levels 2 and 5, and three items at displayed level 3. The raw
`levelRequire` values are zero-based relative to the displayed descriptions.

Current `QuestService` supports event objectives and profile-state objectives, but it has no
equipped-count, equipped-rarity or equipment-level evaluator. `InventoryData` already owns the
seven equipped slots and an equipment-level query, while `Player` already observes every
successful equipment mutation. This makes a state-query adapter the smallest compatible slice;
counting upgrade clicks would contradict the reference evidence.

Replacing the current 15-quest clean-room chain is intentionally deferred. Saves persist
`main_index`, so insertion/reordering changes the meaning of existing progress. The reference
Turtle (card 33) also lacks an approved canonical runtime monster mapping, while current
placeholder IDs remain protected by the shared stable-ID decision. Agent A's active beginner
quest HUD work is presentation-only in `mobile_hud.gd`; logic must not modify that file.

## 2026-11-06 — Reference equipment instance evidence

Decoded Treasure Hunter metadata confirms that cards 28, 29 and 30 are distinct Common weapon
definitions with Health, Damage and Speed ranges. Authorized runtime inspection also shows
multiple equipment instances using the same `Weapons_0` icon while carrying different decimal
values, including Health `13.9`/`14.6`, Damage `29.8`/`29.2` and Speed `0.08` on Epic instances,
plus Health `7.7` and Damage `26.3` on a Rare instance.

This rules out representing a reference weapon solely as a catalog item ID. The minimum safe
carrier is a duplicated equipment instance containing its source card ID, stable art asset ID
and exact rolled stat payload. The observed values are preserved as evidence only: their random
distribution, rarity transformation, rounding and contribution to Emberfield combat remain
unknown and are not inferred by this feature.

## 2026-11-06 — Reference weapon materialization scout

Card records 28/29/30 confirm three distinct Common weapons named `Weapons_0`, `Weapons_1` and
`Weapons_2`. Each has exact Health/Damage/Speed ranges, cost and upgrade cost of 10 Gold, upgrade
rate 1.4, equipment type Weapons and a distinct integrated stable icon ID. Box 149 selects one
of them with weights 34/33/33.

The official Treasure Hunter equipment guide documents a chance to add 20-100% of all stats when
upgrading to a new tier, but neither that guide nor the extracted client data exposes the initial
stat-roll distribution or rounding rule. The client contains server-facing equipment models and
identifiers such as `BoxToEquipmentFromRandompack`, `rawStatData` and `EquipmentState`, while the
authoritative implementation remains absent.

Therefore the next safe boundary is deterministic validation/materialization of an exact stat
payload supplied by an authority or replay record. Generating random values, applying rarity/tier
transforms and displaying rounded values remain unknown behavior and must not be derived from the
observed examples alone.

## 2026-11-06 — Pending quest-claim durability scout

- Current quest rewards are committed through `GameState.grant()`, but claim completion was not
  durably saved at the mutation boundary. A process exit before the next autosave could lose both
  reward and quest transition.
- Box 149 will eventually create one exact equipment instance. Resolving it again after a failed
  save would permit a reroll, so the resolved payload must be persisted before inventory mutation.
- Extracted client identifiers confirm request/response quest claiming (`CmdClaimRequest`,
  `RpcClaimQuest`, `ClaimQuestResponse`) but do not reveal the original server's idempotency or
  retry formula. The implementation therefore claims offline durability, not server parity.
- Agent A's Turtle contract adds stable art IDs only and has no overlap with the save, quest,
  reward resolver or gameplay-test files in this feature.

## 2026-11-06 — Exact equipment reward payload scout

- `ClaimQuestResponse` contains separate `EquipmentsReward` and `CurrenciesReward` identities,
  supporting equipment instances as a distinct reward domain rather than item quantities.
- Current `ReferenceEquipmentCatalog` can validate/materialize exact card 28/29/30 stat payloads,
  `InventoryData.transact()` can commit instance objects atomically, and save schema v3+ preserves
  their card, stable asset ID and decimal stats.
- The missing boundary is the canonical reward/journal shape: it supports only XP, currencies and
  item-ID quantities, so exact equipment data would currently be discarded by `GameState.grant()`.
- Initial stat RNG, rounding, rarity transformation, Box 149 registration and quest 305 remain
  unknown and are not implied by this prerequisite.

## 2026-11-06 — Box 149 authority-boundary scout

- `Box.json` verifies that Box 149 is an available non-stackable Option box with one Common
  equipment result: card 28 at weight 34, card 29 at 33 or card 30 at 33. Every result has quantity
  one. Quest 305 is the inactive ten-dig follow-up that rewards this box.
- Native client metadata includes `BoxToEquipmentFromRandompack`, `EquipmentsReward`,
  `rawStatData`, `CreateStats` and multiplier-stat methods, but the available export does not expose
  their executable initial stat-roll or rounding logic. The quest response shape supports an
  authority returning already materialized equipment.
- Public Treasure Hunter documentation describes later tier upgrades, not the initial Beginner
  Weapon roll. Four observed inventory instances are insufficient to infer a distribution and
  include Rare/Epic transformations outside Box 149's Common result.
- The safe integration boundary therefore selects the source card independently, then requires an
  exact catalog-valid stat payload from an offline/host authority before it creates a canonical
  reward. Quest insertion remains deferred.
