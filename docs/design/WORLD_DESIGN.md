# World and Content Direction

- Stage: BRAINSTORM (revised 2026-11-07 after owner decisions)
- Owner decision: the overworld has **three zones**, **Normal**, **Ash** and **Snow**, and each has
  its **own monster roster**. Difficulty follows that order: Normal (easy) → Ash (medium) → Snow
  (hardest).
- Existing original names (Hearthmoor, Greenwood, Crypt Depths, Frostvale, Mire King, Crypt Warden,
  Bone Colossus, Dusk Bat, Bone Grunt/Archer, Frost/Magma Slime) are kept.

## 1. World structure

Owner decision: the three zones are **concentric rings on one continuous overworld map**.
**Normal** is the centre, **Ash** surrounds Normal, and **Snow** surrounds Ash. Walking outward
means walking into danger.

```text
                 S N O W   (outer ring, T3, Lv 30–45, danger zone)
           ┌───────────────────────────────────────────┐
           │      A S H   (middle ring, T2, Lv 15–30)    │
           │    ┌───────────────────────────────┐       │
           │    │   NORMAL (centre, T1, Lv 1–15) │       │
           │    │      ◉ Hearthmoor hub          │       │
           │    │      ⌂ Homestead gate          │       │
           │    └───────────────────────────────┘       │
           │   outposts · Ember Vault · Gloamdeep Mines  │
           └───────────────────────────────────────────┘
             Frozen Sepulchre · Glacier Behemoth altar
```

| Zone (id) | Ring (starting values, tiles from centre) | Level | Biome feel | Danger rules |
| --- | --- | --- | --- | --- |
| **Normal** (`normal`, keeps the Greenwood name in UI) | 0–96 | 1–15 | meadow, woods, streams | no item loss |
| **Ash** (`ash`, "Cinderwaste") | 96–192 | 15–30 | grey ash plains, ruins, ember vents | **danger zone** |
| **Snow** (`snow`, "Frostvale") | 192–288 | 30–45 | snowfields, ice cliffs, frozen ruins | **danger zone** |
| Hearthmoor (`town`) | hub at the centre of Normal | — | village | safe |
| Homestead (`homestead`) | separate instanced scene, gate in Normal | — | clearing | safe except Ashfall raids |

### Ring layout rules

- Zone membership is decided by distance from the centre with **noise-warped borders**, so the
  rings feel natural rather than perfect circles. A 6–10 tile **transition band** blends tiles
  (grass dusted with ash, ash crusted with frost).
- Difficulty also rises **within** a ring from inner to outer edge. Monster level
  = lerp(zone min, zone max, radial position) ± sub-area offset.
- Each ring is split into **sectors** (for example 6 × 60°) that give sub-area identity
  (ruins sector, vent sector, outpost frontier…) and spread landmarks around the ring.
- **Soft gating, no walls**: players can walk outward at any time. They are held back by
  monster level, the danger-zone death roll, ash storms in Ash, and the **Cold** meter in Snow,
  which is near-lethal without a Frost Lantern or frost gear. Region entry shows an
  "under-levelled" warning when gear score is too low.
- Beacon shrines in every ring and sector give fast travel back to the centre.

### Technical approach

- One overworld scene, `res://sense/maps/overworld/overworld.tscn`, generated from a seed by an
  extended `FieldMap` (radial zone function plus per-zone tables).
- **Chunk streaming**: 32×32-tile chunks. Only chunks near players (offline: 1 player; LAN: up to
  4) are instantiated; monsters, nodes and props sleep or despawn outside the active set. Chunk
  deltas (broken tiles, depleted nodes, opened chests) are saved per chunk.
- The existing separate `greenwood.tscn` and `frostvale.tscn` scenes are kept until the
  overworld passes acceptance, then retired (approval). Saves mapping `current_zone`
  `greenwood`/`frostvale` → `overworld` plus a position are handled in save v7.
- LAN: all peers share one scene, so there's no zone hand-off, but the host must run every
  peer's active chunks. Interest management: each client only receives entities within its
  view radius.

### Dungeons (instanced, procedural rooms — existing `DungeonGenerator`)

| Dungeon | Entrance | Tier | Boss | Status |
| --- | --- | --- | --- | --- |
| Crypt Depths | Hearthmoor portal | T1 | Crypt Warden | exists |
| Gloamdeep Mines | Ash ring, ruins sector | T2 | Geode Wyrm | new |
| Ember Vault | Ash ring (Kindled Key–gated) | T2+ endgame | Pyre Sovereign | new |
| Frozen Sepulchre | Snow ring, outer edge | T3 | Bone Colossus (moved from field) | new |

## 2. Zone definition (data model)

A new zone table (format decided in PLAN) consumed by the overworld generator:

```gdscript
"ash": {
    "name": "Cinderwaste", "tier": 2, "level": Vector2i(15, 30),
    "ring": Vector2(96, 192),          # tiles from centre; borders noise-warped
    "tileset": "tileset.zone.ash", "palette": "ash",
    "danger_zone": true,
    "terrain": {"break_tile": "ash_crust", "density": 0.20},
    "sectors": ["ash_plains", "charred_ruins", "ember_vents", "hollowfolk_frontier"],
    "resources": [["ore_ashiron", 30, Vector2i(1, 3)], ["obsidian", 15, Vector2i(1, 2)],
                  ["ashbloom", 20, Vector2i(1, 3)], ["charred_log", 25, Vector2i(2, 4)]],
    "spawns": {"day": "ash_day", "night": "ash_night"},   # zone-exclusive monster tables
    "camps": 6, "elite_camps": 2, "outposts": 3,
    "loot_table": "zone_t2", "dig_table": "dig_t2",
    "landmarks": ["abbot_chapel", "vault_ruins", "ember_vent_field"],
    "music": {"calm": "music.ash.calm", "tense": "music.ash.tense"},
}
```

## 3. Monster rosters (zone-exclusive)

Each zone has its own monsters; no regular mob appears in two zones. Full stats and AI are in
[COMBAT_MONSTERS.md](COMBAT_MONSTERS.md) §4.

| Zone | Regular monsters | Night-only | Elite/champion | Bosses |
| --- | --- | --- | --- | --- |
| **Normal** | Gnatling, Bramble Snail, Bristle Boar, Puffcap, Mossback Tortoise, Briar Wolf, Sapling Treant | Dusk Bat | Thornback Boar (champion) | Mire King (world, altar) · Hollow Stag (field) · Crypt Warden (dungeon) |
| **Ash** | Magma Slime, Cinder Hound, Ash Wisp, Bone Grunt, Bone Archer, Ash Revenant, Hollowfolk (Raider, Slinger, Shieldbearer, Shaman) | Ash Hunters (Ashstalker, Pyre Hound) | Hollowfolk Chieftain, Ember Drake | Grey Choir Abbot (field) · Lantern Colossus (world) · Geode Wyrm (dungeon) · Pyre Sovereign (vault) |
| **Snow** | Frost Slime, Rime Elk, Ice Troll, Snow Harpy, Frostbound Knight, Glacier Crab | Wraith of the White (night stalker) | Rimeborn Sentinel | Glacier Behemoth (world) · Bone Colossus (dungeon) |

## 4. Terrain and gathering surfaces

| Surface | Interaction | Exists? |
| --- | --- | --- |
| **Breakable terrain tiles** per zone: grass rubble & bramble (Normal), ash crust & charred stone (Ash), packed snow & ice block (Snow) | Hit with any weapon (tools faster). HP by tier. Drops from the zone table: materials, potions, gear (low chance), map fragments; Kindled Keys from ash crust only | **New**: the main gathering verb. Implemented as a TileMap layer plus damage map |
| Resource nodes | Normal: wood, stone, copper, herbs · Ash: ash-iron, obsidian, charred log, ashbloom · Snow: frost-silver, rime crystal, pelt, frostcap | Partial (`ResourceNode`) |
| Dig plots | Stand to dig; treasure-map targets surface here | Exists (`DigSpot`) |
| Crops | Homestead farm plots | New |
| Fishing | Normal-zone streams (stretch) | New, optional |

Tile-break rules: per-tile HP; damage = tool power × tier match; broken tiles regrow after N
minutes; broken state persists per zone in the world save.

## 5. Landmarks, secrets and exploration rewards

Per zone, seeded placement of authored stamps:

- **Beacon shrine**: lights fast travel and reveals nearby fog (3–4 per zone).
- **Elite camps** and, in Ash, **Hollowfolk Outposts** (VILLAGE §8).
- **Hidden spots**: cracked walls, bramble thickets, ice caves with caches.
- **Boss lairs and world-boss altars**: Normal (Mire King), Ash (Lantern Colossus), Snow (Glacier
  Behemoth).
- **Lore stones** completing codex pages.

Exploration reward: fog reveal % per zone with chests at 25/50/75/100%.

## 6. Day/night and weather

- 20-minute real-time day (14 day / 6 night) via a new `WorldClock` autoload, saved and
  host-synced on LAN.
- Night: darker modulation, light radius, night-only monsters, +25% rare drops; Ash Hunters active
  in Ash, the Wraith of the White in Snow.
- **Blood Ember night** (~1 in 7): elites everywhere, double embers.
- Weather: rain (Normal), ash storm (Ash: lower visibility), blizzard (Snow: −15% move speed
  without frost gear).
- Snow zone **Cold** meter: rises outside heat sources, causes Chill when full; warmed by fires,
  braziers, Frost Lantern, frost-resistance gear.

## 7. Death rules (owner decision)

- Respawn at the last beacon or the homestead after 3 s (existing respawn flow).
- **Normal zone**: no item loss.
- **Danger zones (Ash, Snow)**: on death there is a **chance** (data value, starting at 25%) to
  drop **one random item** chosen from equipped gear **or** the bag. Locked items are never chosen.
  - **Killed by a monster** (or environment): the item is **lost permanently**.
  - **Killed by another player** (LAN PvP): the item drops on the ground and **only the killer**
    can pick it up (60 s), after which it is lost.
- A carried **Kindled Key** always drops on death regardless of the chance (TREASURE §3).
- Mitigations: item lock, the Ashwalker set (−50% drop chance), a crafted Ward Charm consumed
  instead of an item.
- The rule applies to **both Ash and Snow** (owner confirmed 2026-11-07).

## 8. Quests (all original text)

| Type | Count (v1) | Source | Notes |
| --- | --- | --- | --- |
| Tutorial | 7 (`t01`–`t07`) | Hearthmoor | Dig, defeat, equip, enhance, defeat, equip Uncommon+, craft. Replaces q305–q311 one-for-one by function |
| Main chain | ~40 across 3 acts (one per zone) | Warden Captain + zone NPCs | Original q01–q15 kept and re-sequenced into Act I |
| Side quests | 3–5 per NPC | Hub NPCs | Unlock recipes, buildings, pets |
| Dailies | 3 of a pool of 15 | Bounty board | Existing `d_hunt` / `d_gather` / `d_boss` kept |
| Weeklies | 2 of a pool of 8 | Bounty board | Embers |
| Bounties | Rotating named elites per zone | Bounty board | |
| Achievements | ~80 | Codex | Titles and small capped bonuses |

The quest engine stays `QuestService`. New objective types: `gather`, `break_tiles(zone, n)`,
`craft`, `build`, `explore(zone, pct)`, `open_vault`, `reach_gear_score`, `tame`, `defend_raid`.

## 9. Events (local clock, host-mirrored on LAN)

| Event | Cadence | Effect |
| --- | --- | --- |
| World boss window | every 2 h of play-clock, 20-min window, one altar per zone | Last-hit + participation rewards |
| Blood Ember night | ~1/7 nights | Elite surge, double embers |
| Forge Day / Harvest Day | Saturday / Sunday (local) | −20% enhancement cost / ×2 gather and crop yields |
| Ashfall raid | every ~3 in-game days after Act I | Homestead defence |
| Wandering merchant | random daily | Rare recipes/eggs |

Clock-manipulation guard: monotonic play-clock; forward jumps grant at most one missed event.

## 10. Zone summary

| Zone | Gather focus | Signature mechanic | Secret |
| --- | --- | --- | --- |
| Normal — Greenwood | wood, stone, copper, herbs, hide | Learning loop: gather, craft, homestead | Sunken well, hidden grove |
| Ash — Cinderwaste | ash-iron, obsidian, ashbloom, bone | Kindled Keys, Hollowfolk outposts, ash storms, item-drop risk | Sealed cellars, vault approaches |
| Snow — Frostvale | frost-silver, rime crystal, pelts, frostcap | Cold meter, blizzards, hardest monsters, item-drop risk | Ice caves |
