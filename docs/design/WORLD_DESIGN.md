# World and Content Direction

- Stage: BRAINSTORM · 2026-11-07
- Everything here is original. Existing original names (Hearthmoor, Greenwood Meadow, Crypt
  Depths, Frostvale, Mire King, Crypt Warden, Bone Colossus, Dusk Bat, Bone Grunt/Archer,
  Frost/Magma Slime) are kept.

## 1. World structure

The frontier is a ring of regions around the Ash heartland. Each region is a separate Godot scene
built by the existing seeded `FieldMap` generator, extended with **hand-placed landmarks**
(see §4) so every seed still has an authored identity.

```text
                      [Frostvale Peaks T5]
                             │
 [Cinder Ruins T4] ── [Ashen Wastes T6 ☠] ── (Ember Vault)
        │                    │
 [Gloamdeep Caverns T3]  [Thornwood T2]
        │                    │
        └──── [Greenwood Meadow T1] ──── [Hearthmoor hub] ── [Homestead]
```

| Region (id) | Tier | Level | Biome | Safe? | Status |
| --- | --- | --- | --- | --- | --- |
| Hearthmoor (`town`) | hub | — | village | safe | exists |
| Homestead (`homestead`) | home | — | clearing | safe except during Ashfall raids | exists (6 plots) → grid |
| Greenwood Meadow (`greenwood`) | T1 | 1–8 | grassland | open | exists |
| Thornwood (`thornwood`) | T2 | 8–16 | forest | open | new |
| Gloamdeep Caverns (`gloamdeep`) | T3 | 16–24 | cave / mining | open, dark | new |
| Cinder Ruins (`cinder_ruins`) | T4 | 24–32 | ruins | **Ash zone** | new |
| Frostvale Peaks (`frostvale`) | T5 | 32–40 | mountain / snow | **Ash zone** | exists as "Frostvale Ruins" → renamed and expanded |
| Ashen Wastes (`ashen_wastes`) | T6 | 40–45 | blight wasteland | **Ash zone, LAN PvP-enabled** | new |

**Ash zones** apply the carried-materials risk rule (§6) and spawn Ash Hunters at night.

### Dungeons (instanced, procedural rooms — existing `DungeonGenerator`)

| Dungeon | Entrance | Tier | Boss | Status |
| --- | --- | --- | --- | --- |
| Crypt Depths | Hearthmoor portal | T1–T2 | Crypt Warden | exists |
| Hollow Burrows | Thornwood | T2 | Rootmother | new |
| Gloamdeep Mines | Gloamdeep Caverns | T3 | Geode Wyrm | new |
| Frozen Sepulchre | Frostvale Peaks | T5 | Bone Colossus (moved from field) | new |
| Ember Vault | Ashen Wastes | T6 | Pyre Sovereign | new (endgame, key-gated) |

Each dungeon gets: room theme set, mob table, chest table, a secret-room chance, and a floor
modifier (darkness, ice floor, poison mist).

## 2. Biome definition (data model)

A new `GameContent.BIOMES` table (or `res://data/biomes/*.tres`, decided in PLAN) consumed by
`FieldMap`:

```gdscript
"thornwood": {
    "name": "Thornwood", "tier": 2, "level": Vector2i(8, 16),
    "tileset": "tileset.biome.thornwood",          # asset ID, not a path
    "palette": "thornwood",
    "ash_zone": false,
    "terrain": {"break_tile": "bramble_block", "density": 0.18},
    "resources": [  # node_id, weight, cluster size
        ["tree_oak", 40, Vector2i(2, 5)], ["tree_ironbark", 12, Vector2i(1, 2)],
        ["herb_thornberry", 20, Vector2i(1, 3)], ["ore_copper", 10, Vector2i(1, 2)]],
    "spawns": {"day": "thornwood_day", "night": "thornwood_night"},  # spawn tables
    "camps": 4, "elite_camp": 1, "outposts": 0,
    "loot_table": "biome_t2", "dig_table": "dig_t2",
    "landmarks": ["hollow_stag_glade", "old_watchtower", "hidden_grove"],
    "music": {"calm": "music.thornwood.calm", "tense": "music.thornwood.tense"},
}
```

## 3. Terrain and gathering surfaces

| Surface | Interaction | Exists? |
| --- | --- | --- |
| **Breakable terrain tiles** (rubble, bramble, crystal, ice, ash crust) | Hit with any weapon (tools faster). HP by tier. Drops from the biome table: materials, potions, gear (low chance), treasure-map fragments, keys (Ash zones) | **New**: the main gathering verb. Implemented as a TileMap layer plus damage map, not one node per tile |
| Resource nodes (trees, ore veins, herbs) | Tool-tiered gathering with respawn | Partial (`ResourceNode`) |
| Dig plots | Stand to dig; treasure-map targets surface here | Exists (`DigSpot`) |
| Fishing spots | Timing mini-game (P5 stretch) | New, optional |
| Crops | Homestead farm plots | New |

Tile-break rules: per-tile HP; damage = tool power × tier match; broken tiles regrow after N
minutes unless the area is "claimed" (homestead). Broken state persists per region in world save.

## 4. Landmarks, secrets and exploration rewards

Each region has hand-designed landmark stamps placed at seeded positions:

- **Beacon shrine**: lighting it unlocks fast travel and reveals nearby fog.
- **Elite camp**: champion plus guards; first clear gives a codex entry and chest.
- **Hidden grove / sealed cellar**: reached by breaking a cracked wall or bramble; holds a cache.
- **Hollowfolk Outpost** (T3+): fortified camp with destructible buildings (see VILLAGE §8).
- **Boss arena**: field boss lair; world boss altar in T1, T3, T5.
- **Lore stones**: original lore fragments that complete a codex page.

Exploration rewards: fog-of-war reveal percentage per region with milestone chests at 25/50/75/100%,
codex completion bonuses (+1% stat per completed bestiary page, capped).

## 5. Day/night and weather

- 20-minute real-time day (14 day / 6 night), driven by a new `WorldClock` autoload that is
  saved and host-synced on LAN.
- Night: darker canvas modulation, light radius around the player and torches, nocturnal spawn
  tables, +25% rare drop chance, Ash Hunters active in Ash zones.
- **Blood Ember night** (event, ~1 in 7 nights): elites everywhere, double ember drops.
- Weather per biome (rain, snow, ash storm) is visual first; gameplay modifiers in P5.

## 6. Death and the carried-materials risk

- On death: respawn at the last beacon or the homestead after 3 s (existing respawn flow).
- **Safe regions** (T1–T3): no item loss.
- **Ash zones** (T4–T6): the **material pouch's unbanked contents** drop as a *Remnant* at the
  death spot for 10 minutes. Equipment and bag are never lost. Reaching the Remnant recovers it.
  Banking at a beacon (costs embers) or at the homestead secures materials.
- A carried **Kindled Key** always drops on death (TREASURE §3).

Owner question: confirm the full-pouch drop, or soften it to 25%.

## 7. Quests (all original text)

| Type | Count (v1) | Source | Notes |
| --- | --- | --- | --- |
| Main chain | ~45 across 4 acts | Warden Captain + region NPCs | Replaces q305–q311. Original q01–q15 are kept and re-sequenced |
| Tutorial | 7 (`t01`–`t07`) | Hearthmoor | Dig, defeat, equip, enhance, defeat, equip Uncommon+, craft. Replaces q305–q311 one-for-one by function |
| Side quests | 3–5 per NPC | Hub NPCs | Unlock recipes, buildings, pets |
| Dailies | 3 of a pool of 15 | Bounty board | Existing `d_hunt` / `d_gather` / `d_boss` kept and extended |
| Weeklies | 2 of a pool of 8 | Bounty board | Bigger goals; Ember rewards |
| Bounties | Rotating hunts on named elites | Bounty board | Uses spawn-table champions |
| Achievements | ~80 | Codex | Permanent titles and small account bonuses |

The quest engine stays `QuestService` (event-driven, stable IDs, durable claim journal). New
objective types: `gather(item, n)`, `break_tiles(biome, n)`, `craft(recipe|category, n)`,
`build(building, level)`, `explore(region, pct)`, `open_vault`, `reach_gear_score(n)`,
`tame(pet_rarity)`, `defend_raid(n)`.

## 8. Events (local clock, host-mirrored on LAN)

| Event | Cadence | Effect |
| --- | --- | --- |
| World boss window | every 2 h of play-clock, 20-min window, per T1/T3/T5 altar | Boss spawns at altar; last-hit + participation rewards |
| Blood Ember night | random ~1/7 nights | Elite surge, double embers |
| Forge Day | Saturday (local) | −20% enhancement cost |
| Harvest Day | Sunday (local) | ×2 crop and gather yields |
| Ashfall raid | every ~3 in-game days after Act II | Homestead defence (VILLAGE §7) |
| Wandering merchant | random daily | Rare recipe/egg stock |
| Season of Embers | monthly | Event quest line plus cosmetic reward track |

Clock-manipulation guard: offline events key off a monotonic play-clock plus a sanity check on
wall-clock jumps; jumps forward grant at most one missed event.

## 9. Region content summary

| Region | Gather focus | Mobs (see COMBAT) | Boss | Secret |
| --- | --- | --- | --- | --- |
| Greenwood Meadow | wood, stone, meadow herbs, copper (rare) | Gnatling, Bramble Snail, Bristle Boar, Puffcap, Dusk Bat (night) | Mire King (world, altar) | Sunken well cache |
| Thornwood | oak/ironbark, thornberry, hide, copper | Briar Wolf, Hornet Swarm, Sapling Treant, Fungal Shaman | Hollow Stag (field) | Hidden grove |
| Gloamdeep Caverns | copper/iron/silver ore, glowcap, crystal | Cave Crawler, Glowworm, Golemite, Shade Bat | Geode Wyrm (dungeon), Lantern Colossus (world) | Collapsed shaft |
| Cinder Ruins | ash-iron, old relic scraps, bone | Bone Grunt, Bone Archer, Ash Wisp, Cursed Sentinel | Crypt Warden lineage, Grey Choir Abbot (field) | Sealed cellar |
| Frostvale Peaks | frost-silver, rime crystal, pelts | Frost Slime, Rime Elk, Ice Troll, Snow Harpy | Bone Colossus (dungeon), Glacier Behemoth (world) | Ice cave |
| Ashen Wastes | ember ore, obsidian, ash-bloom | Magma Slime, Cinder Hound, Ash Revenant, Ember Drake | Pyre Sovereign (vault) | Vault approaches |
