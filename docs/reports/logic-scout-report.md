# Logic Scout Report

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
