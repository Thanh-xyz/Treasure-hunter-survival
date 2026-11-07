# Technical Risks (SCOUT, 2026-11-07)

Severity: Critical · High · Medium · Low.

| # | Risk | Severity | Evidence | Mitigation |
| --- | --- | --- | --- | --- |
| R1 | **Project direction conflict.** Repo rules and shared decisions mandate a pixel-parity recreation; the new brief mandates an original game. Following either silently violates the other. | Critical | `AGENTS.md`, `shared/coordination/decisions.md`, asset manifest project name | Owner decision D1; rewrite AGENTS.md + decisions before BRAINSTORM |
| R2 | **IP contamination** — extracted art, quest text, IDs, stats and captures are in runtime code, content tables, docs and Git history. | Critical | `assets/treasure_hunter/**`, `reference_*.gd`, `reward_box_catalog.gd`, q305–q311, `docs/original-captures/` | Replace-then-retire plan; provenance gate test; clean repo/history before any public release |
| R3 | **No local validation.** Godot 4.6 not installed; the binary earlier agents used in `/tmp` is gone. Every later stage needs headless test runs. | High | `which godot` empty; reports cite `/tmp/th-godot-ISNBhK/...` | Owner approves a portable Godot 4.6 binary in scratch (D6); first TEST = baseline of existing suites |
| R4 | **Save/LAN compatibility when retiring reference IDs** (`th_weapon_28..30`, `q305..q311`, Box 98/149–152, `snailu`, `turtle`). | Medium-High | `save_service.gd` strict version check (v5), stable-ID quest restore, `LanSession.PROTOCOL_VERSION = 5` | Bump `SAVE_VERSION` → 6 with explicit ID mapping in `_migrate`; bump LAN protocol; migration tests |
| R5 | **Large multi-responsibility files** make new systems risky to add. | Medium | `player.gd` 1,510 lines, `lan_session.gd` 1,123, `mobile_hud.gd` 984, `game_menu.gd` 740 | Extract only along seams a feature needs (e.g. gathering, dodge), each with tests; no big-bang refactor |
| R6 | **Duplicate content models**: legacy `ItemDatabase` items vs reference "cards"; skeleton vs `Monster`; equipment Q/E/R/F skills vs hero Z/X/C skills; legacy 1280×720 popups auto-scaled into portrait. | Medium | `item_database.gd`, `reference_equipment_catalog.gd`, `skeleton.gd`, `monster.gd`, `MobileHUD._fit_legacy_popup` | Decide one model per concept in BRAINSTORM/PLAN; migrate the other behind its stable IDs |
| R7 | **Biome system absent**: zone resources/spawns hard-coded in map scripts. | Medium | `field_map.gd` `_scatter_world`, `_build_camps`; `GameContent.zones` has no tables | Introduce biome definitions (tileset, resource, spawn, loot, difficulty) as data consumed by `FieldMap` |
| R8 | **No audio pipeline** — retrofitting buses and SFX hooks late touches many scenes. | Medium | no audio files, no bus layout | Add an `AudioService` autoload + event-driven SFX early (P1/P2) |
| R9 | **Third-party asset licenses unknown.** | Medium | no license files; manifest `unknown` | D5; CREDITS.md; replace anything that can't be verified |
| R10 | **Art consistency**: mixing 32×32 icons, 96×80 soldiers, 128×128 skeletons, 16 px tiles and ASCII sprites at camera zoom 2 in portrait. | Medium | asset dimensions in ASSET_INVENTORY.md | Art bible in BRAINSTORM: one base tile size, character height, palette rules |
| R11 | **LAN surface grows with every system** (equipment, crafting, gathering, chests, building all un-synced). | Medium | `docs/survival_rpg.md` "Chưa đồng bộ" list | Keep the command/authority-adapter boundary for every new system so the host can validate it later |
| R12 | **Coordination debt**: two paused agents, two worktrees, ~30 local feature branches, two prunable `/tmp` worktrees, 2,800-line status logs. | Low-Medium | `git worktree list`, `git branch` | D4: stand down/archive; don't delete branches without approval |
| R13 | **Reverse-engineering artifacts on disk** (decompiled smali, IL2CPP metadata, Pairip/Play Integrity analysis, two XAPKs). | Low (for code) / owner's legal call | `assets-ths/` | Keep out of the repo and of any agent workflow; never use to bypass protections |
| R14 | **Mobile performance**: per-frame loot magnet, runtime texture generation, up to 96-enemy LAN batches. | Low | `field_map.gd MAGNET_INTERVAL`, `LanSession.MAX_ENEMY_BATCH` | Profile once biomes add density; cache already exists in `PixelArt` |

| R15 | **Continuous concentric overworld** (owner decision 2026-11-07): one large map (~576×576 tiles) needs chunk streaming, per-chunk persistence and LAN interest management; the current game loads one small zone scene at a time. | Medium-High | `WORLD_DESIGN.md` §1; `scene_transition_service.gd`, `LanSession` zone sync | Prototype chunking early (P1-3b) with a frame-time budget on a low-end phone before building content on it |

## Unknowns

- Whether the existing test suites currently pass on this machine (not run).
- Actual frame-time on a target phone.
- Whether the upstream team granted rights to reuse their code.
