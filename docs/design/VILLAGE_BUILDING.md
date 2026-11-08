# Village and Building Specification

- Stage: BRAINSTORM · 2026-11-07
- Builds on: `HomesteadMap` (30×40 tiles, 6 fixed plots), `GameContent.BUILDINGS` (6 types with
  levels), offline real-time production, `GameState.plots` save field.

## 1. Goals

The homestead is the player's **bank, factory and fortress**. It must give long-term goals
(Renown tiers), daily reasons to return (production, crops) and recurring tension (Ashfall raids).

## 2. Grid placement

- The homestead expands from 30×40 tiles to **48×64**, unlocked in rings by Renown tier
  (inner 24×32 → mid → full).
- **Build mode**: drag a ghost footprint on a 16-px grid. Validity is shown green/red. Rotate
  where the footprint isn't square. Move a building for free; demolish refunds 50%.
- Validation (pure function, also host-run on LAN): inside unlocked area; no overlap with
  buildings, paths, the spawn point or resource props; adjacency rules (Well within 6 tiles for
  the farm bonus); count limits per Renown tier; the player must hold the costs at commit time.
- Saved as `{uid, type, level, cell: Vector2i, rot, state}` per building (SAVE_MIGRATION_PLAN v10).
- The existing 6 plots migrate to fixed grid positions with their types and levels intact.

## 3. Buildings (v1 roster)

| Building | Footprint | Max lvl | Function | Exists? |
| --- | --- | --- | --- | --- |
| Hearth (core) | 3×3 | 10 | Sets Renown tier cap, raid HP pool, unlock rings | new |
| Storehouse | 2×2 | 4 | Safe storage +60 slots/level | new |
| Workbench | 2×1 | 5 | Station | new building (UI exists) |
| Smelter | 2×2 | 5 | Station | new |
| Forge | 3×2 | 5 | Station, traps, siege kits | new building (NPC smith exists) |
| Tannery / Loom | 2×2 | 3 | Stations | new |
| Alchemy Table | 2×1 | 5 | Station | new building |
| Rune Altar | 2×2 | 5 | Station | new |
| Cookfire / Kitchen | 1×1 / 2×2 | 3 | Station | new |
| Hatchery | 2×2 | 4 | Eggs → pets | new |
| Stable | 3×2 | 5 | +10% mount speed/level (existing), mount training | exists |
| Lumber Mill | 2×2 | 5 | Wood over time | exists |
| Stone Quarry | 2×2 | 5 | Stone over time | exists |
| Herb Garden | 2×2 | 5 | Herbs and pet treats | exists |
| Ore Drill | 2×2 | 5 | Ore of a chosen zone tier (needs that zone's boss cleared) | new |
| Farm plot | 2×2 | 3 | Crops | new |
| Well, Scarecrow | 1×1 | 3 / 1 | Farm modifiers | new |
| Training Hall | 3×2 | 5 | +ATK per level (existing) | exists |
| Watchtower | 1×1 | 5 | +DEF/HP (existing), raid early warning, ranged auto-fire | exists |
| Ballista Tower | 1×1 | 5 | Raid defence, single target | new |
| Ember Brazier | 1×1 | 3 | Raid AoE burn, light radius | new |
| Walls / Gates | 1×1 | 3 (wood → stone → ash-iron) | Pathing blockers with HP | new |
| Traps (Spike, Snare, Fire, Frost) | 1×1 | 2 tiers | Single-use or limited charges; rearm costs materials | new |
| Beacon Relay | 1×1 | 1 | Lets world beacons access storage | new |
| Trophy Hall, statues, banners | various | — | Cosmetic, achievement showcase | new |

Production buildings keep the existing offline real-time model. Output accumulates up to a
storage cap (8 h base, +2 h per level), then stops.

## 4. Costs and upgrade times

Cost formula per building row: `cost(level) = base × growth^(level−1)`, with material types
shifting by tier (wood/stone → planks/ingots → alloys → embers). Upgrade timers run from 0 s
(level 1) to 6 h (level 5 core buildings), with one build queue and a second unlocked at Hearth 5.

## 5. Renown tiers

| Tier | Hearth lvl | Unlocks |
| --- | --- | --- |
| Camp | 1 | inner ring, 6 buildings, workbench |
| Hamlet | 3 | mid ring, smelter, forge, farm, first Ashfall raids |
| Village | 5 | outer ring, rune altar, hatchery, towers, second build queue |
| Stronghold | 8 | ash-iron walls, Snow-tier ore drill, beacon relay |
| Ember Keep | 10 | cosmetic keep, Mythic recipes, Ember Cycle eligibility |

Renown comes from quests, raid defences, codex and building levels.

## 6. Interaction

Tap a building to get context actions: collect, open station UI, upgrade, move. NPC helpers (one
per tier) walk between buildings, giving visual life and auto-collecting (Village+).

## 7. Ashfall raids (offline defence)

- From Hamlet onward, every ~3 in-game days, a raid warning fires 2 minutes ahead (Watchtower
  extends this).
- Hollowfolk or Ash creatures attack from the map edges. They path around walls (A*/flow-field on
  the homestead grid), attack the nearest structure, and target the Hearth.
- Defence: player plus pet, towers, traps, walls. Waves scale with Renown and the last defence
  result.
- Outcome: win gives Renown, embers and a raid chest. Loss means production is paused for 2 h and
  a percentage of the **production buffers** (never storage) is stolen. Buildings are "damaged"
  (repair costs materials) and never destroyed.
- The player can skip a raid if they're away: towers resolve it with a simulated outcome using
  the same rules at reduced rewards. This keeps it fair offline.

## 8. Hollowfolk Outposts (raidable NPC villages)

The Ash zone contains fortified outposts: palisade, gate, 3–6 destructible buildings
(Barracks, Slinger Nest, Totem that heals defenders, Storage that drops loot when broken,
Chieftain's Hut). Destroying the Chieftain's Hut clears the outpost and gives a big chest and
embers. The outpost rebuilds after 24 h with a higher level. This uses the same building
data/HP code as the homestead, inverted.

## 9. LAN

- Host's homestead is the shared world homestead. Guests can build with host permission
  (permission levels: visitor / builder / co-owner).
- Each guest keeps their own personal homestead in their own save, used offline.
- Optional LAN **siege mode** (owner decision): teams attack a host-created arena homestead.
  Deferred to P9+.
