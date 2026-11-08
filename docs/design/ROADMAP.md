# Prioritised Implementation Roadmap

- Stage: BRAINSTORM (roadmap draft). The detailed per-task PLAN (files, steps, tests) is written
  milestone by milestone after the owner approves this roadmap.
- Each task is one branch → TEST → REVIEW → PR. Sizes: **S** ≤ 1 day, **M** 2–4 days,
  **L** ≥ 1 week (to be split further in PLAN).
- 🔒 = requires explicit owner approval before IMPLEMENT (directive §10).
- Feature IDs refer to [FEATURE_MATRIX.md](FEATURE_MATRIX.md).

## Dependency overview

```text
P0 Foundation ──► P1 World/Character ──► P2 Items ──► P3 Combat ──► P4 Crafting/Economy
     │                    │                  │             │               │
     │                    └──────────────────┴─────► P5 World content ◄────┘
     │                                                      │
     │                                     P6 Village ◄─────┤
     │                                     P7 Pets/Mounts ◄─┤
     │                                     P8 Quests/Events ◄┘
     └──► L2 CommandBus (start in P1, every system adds its command) ──► P9 LAN ──► P10 Online design
```

## P0 — Foundation

| Task | Feature | Size | Depends on | Acceptance |
| --- | --- | --- | --- | --- |
| P0-1 🔒 New `AGENTS.md` + shared decisions for the original-game direction; stand down Agents A/B (branches kept) | F0.1 | S | D1, D4 | Owner signs off on the text |
| P0-2 🔒 Portable Godot 4.6 in the scratch dir (or owner-installed); run every existing suite | F0.2 | S | D6 | Baseline report with real pass/fail output |
| P0-3 Provenance registry schema + `CREDITS.md` + **provenance gate test** (dev mode allows `unverified`) | F0.3 | M | P0-2 | Gate passes on current tree in dev mode and lists every excluded asset |
| P0-4 Save fixtures v1–v5 (original content + reference cases) and a fixture runner | F0.5 | M | P0-2 | Current v5 code loads all fixtures (baseline) |
| P0-5 Original **Ember UI kit** (route A/B) behind asset IDs | K1 | L | P0-3 | Render tests show no reference image |
| P0-6 T1 monster replacements (Gnatling, Bramble Snail, Bristle Boar, Mossback) + `reference_melee` → `timed_melee` | F12 | M | P0-3 | Gate: no `assets/treasure_hunter/monsters` refs |
| P0-7 Field props + Warden Captain portrait replacements | F0.4 | S | P0-3 | Gate |
| P0-8 🔒 Tutorial t01–t07 (original text), original reward tables, original starter weapons; **save v6 migration**; LAN protocol bump | J2, I6, B13, F0.5 | L | P0-4, P0-6 | All fixtures migrate with no loss; new game works end-to-end |
| P0-9 🔒 Retire excluded assets/code/docs after P0-5…P0-8 pass (separate PR) | F0.4 | S | P0-8, D3 | Gate passes in **strict** mode for the reference set |
| P0-10 Logo, icon, title screen | F0.8 | S | P0-5 | Visual review |
| P0-11 `AudioService` skeleton + event hooks (silent until assets exist) | K3 | S | — | Unit: events route to buses |

## P1 — Core world and character

| Task | Feature | Size | Depends on |
| --- | --- | --- | --- |
| P1-1 `StatBlock` pure aggregator behind the existing API (no behaviour change) | A5 | M | P0-2 |
| P1-2 `CommandBus` + `LocalAuthority` skeleton; route attack/gather/equip through it | L2 | M | P1-1 |
| P1-3 Zone data model + radial ring function (noise borders, sectors); `FieldMap` reads zones from data | E1 | M | — |
| P1-3b 🔒 Continuous overworld scene with 32×32 chunk streaming; spawn tables per ring; old greenwood/frostvale scenes kept until acceptance | E2 | L | P1-3 |
| P1-4 Breakable terrain layer (TileMap damage map, drops, regrow, per-chunk deltas) | D1 | L | P1-3b |
| P1-5 Tool belt + tool-tiered gathering formula; `ResourceNode` respawn persistence | D2, D3 | M | P1-1 |
| P1-6 🔒 `WorldClock` day/night + save v7 world section | E7, E9 | M | P0-8 |
| P1-7 Level cap 45 + skill points | A2 | S | P1-1 |
| P1-8 Beacons, fast travel, fog of war | E5, E6 | M | P1-3, P1-6 |

## P2 — Complete item system

| Task | Feature | Size | Depends on |
| --- | --- | --- | --- |
| P2-1 🔒 Equipment instances (uid, affixes) + material pouch + storage + gloves/cloak + embers rename — **save v8** | B4, C2, C3, B1, C6 | L | P1-1 |
| P2-2 Mythic rarity + rarity frames | B3 | S | P2-1 |
| P2-3 Split/filter/lock/bulk-sell | C5 | M | P2-1 |
| P2-4 Comparison tooltip + gear score | B11, A6 | M | P2-1 |
| P2-5 Enhancement +0…+15 (success/fail/pity/ward) | B5 | M | P2-1 |
| P2-6 Ascension, salvage | B6, B12 | M | P2-5 |
| P2-7 Region sets | B7 | M | P2-1 |
| P2-8 🔒 Runes: generalise augments, tiers, fusion — save v9 | B8 | L | P2-1 |

## P3 — Complete combat

| Task | Feature | Size | Depends on |
| --- | --- | --- | --- |
| P3-1 Pure damage function with seeded RNG (acc/dodge/crit/def/res/counter) | F4 | M | P1-1 |
| P3-2 Dodge roll + stamina | F2 | M | P3-1 |
| P3-3 `StatusEffectComponent` (8 effects) | F5 | M | P3-1 |
| P3-4 Weapon classes and attack patterns | B2, F1 | L | P2-1 |
| P3-5 🔒 Skill input consolidation (3 hero + 2 rune) + skill trees | F3, A4 | L | P2-8 |
| P3-6 AI states (leash, retreat, windup, stagger); merge skeleton into `Monster` | F6 | L | P3-1 |
| P3-7 Elites/champions + nested loot tables with pity | F7, F11 | M | P3-6 |
| P3-8 Boss framework: 3 phases, last-hit/participation rewards | F9, F10 | M | P3-6 |

## P4 — Crafting and economy

| Task | Feature | Size | Depends on |
| --- | --- | --- | --- |
| P4-1 Recipe model v2 (stations, duration queues, success, unlocks) | D6 | M | P2-1 |
| P4-2 Processing chains + material catalogue (~60) | D5 | M | P4-1 |
| P4-3 Data-driven shops + new NPCs | C7 | M | P4-1 |
| P4-4 Farming plots + crops | D8 | M | P6-1 |
| P4-5 Economy simulation script + first balance pass | C10 | M | P4-2 |

## P5 — World content

| Task | Size | Depends on |
| --- | --- | --- |
| P5-1 Normal ring (centre): sectors, full roster, Hollow Stag, 2 sets | L | P1-4, P3-8 |
| P5-2 Ash ring (around Normal): tileset, roster, outposts, Grey Choir Abbot, Lantern Colossus, Gloamdeep Mines | L | P5-1 |
| P5-3 Danger-zone death roll (monster kill: lost; player kill: killer pickup) | M | P1-6, P2-1 |
| P5-4 Treasure maps + guardians | M | P1-4 |
| P5-5 Kindled Keys + Ash Hunter director + vault caches | L | P5-3, P3-6 |
| P5-6 Snow ring (outermost; replaces the separate Frostvale scene): roster, Cold meter, blizzards, Glacier Behemoth, Frozen Sepulchre | L | P5-2 |
| P5-7 Ember Vault (Ash endgame) | L | P5-5 |
| P5-8 Hidden locations + dowsing; world-boss altar per zone | M | P1-4 |

## P6 — Village and building

| Task | Size | Depends on |
| --- | --- | --- |
| P6-1 🔒 Grid placement + validation; migrate 6 plots — save v10 (part) | L | P2-1 |
| P6-2 Station buildings (workbench … salvage anvil) | M | P6-1, P4-1 |
| P6-3 Renown tiers + Hearth | M | P6-1 |
| P6-4 Walls, towers, traps | M | P6-1, P3-3 |
| P6-5 Ashfall raids (pathing, simulation fallback) | L | P6-4 |
| P6-6 Hollowfolk Outposts | L | P6-5 |

## P7 — Pets and mounts

| Task | Size | Depends on |
| --- | --- | --- |
| P7-1 🔒 Pet/mount instances — save v10 (part) | M | P6-1 |
| P7-2 Eggs + Hatchery + rarity | M | P7-1, P6-2 |
| P7-3 Pet AI states + skills + evolution remap | M | P7-1 |
| P7-4 Mount levels, gear, signature moves, stamina | M | P7-1 |
| P7-5 New pets ×8, mounts ×6 (content) | L | P7-2…4 |
| P7-6 Runes on pets/mounts, collection bonuses | S | P2-8, P7-1 |

## P8 — Quests and long-term progression

| Task | Size | Depends on |
| --- | --- | --- |
| P8-1 New objective types | M | P1-4, P4-1, P6-1 |
| P8-2 Main chain acts I–IV (original narrative) | L | P5 content |
| P8-3 Side quests, weeklies, bounties | M | P8-1 |
| P8-4 Achievements + codex | M | P8-1 |
| P8-5 Event calendar (Blood Ember, bonus days, wandering merchant, Season of Embers) | M | P1-6 |
| P8-6 Ember Cycles prestige — deferred after the first release | — | — |

## P9 — LAN multiplayer (4 players)

| Task | Size | Depends on |
| --- | --- | --- |
| P9-1 `HostAuthority`/`RemoteAuthority`; port existing LanSession handlers | L | P1-2 |
| P9-2 LAN discovery, content hash, session tokens, reconnection ledger | M | P9-1 |
| P9-3 Sync equipment/crafting/gathering/chests/buffs | L | P9-1 |
| P9-4 Sync pets/mounts/building/keys/clock/quests credit | L | P9-3 |
| P9-5 PvP duel, arena, Ash-zone flag (no sieges) | M | P9-1 |
| P9-6 4-process harness, bandwidth measurements | M | P9-2 |

## P10 — Online architecture (design only)

P10-1 Server/accounts/persistence/anti-cheat design document; no implementation.

## Immediate next steps after approval

1. P0-1 and P0-2 (rules plus test baseline). Neither changes gameplay.
2. PLAN for P0-3 … P0-9 in full detail (files, steps, tests, risks), then the next approval.

## Approval gates summary

| Gate | Tasks |
| --- | --- |
| Project rules | P0-1 |
| Tool install | P0-2 |
| Save format changes | P0-8 (v6), P1-6 (v7), P2-1 (v8), P2-8 (v9), P6-1/P7-1 (v10) |
| Removal of copied content | P0-9 |
| Major system redesigns | P1-3b (continuous overworld), P3-5 (skill input) |
