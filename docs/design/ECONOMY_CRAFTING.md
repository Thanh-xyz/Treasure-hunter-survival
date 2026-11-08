# Economy and Crafting Specification

- Stage: BRAINSTORM · 2026-11-07
- Builds on: `InventoryData.transact` (atomic), `CraftingRecipe`/`RecipeDatabase`, `ResourceNode`,
  homestead production, `LootTable`, shops.

## 1. Currencies

| Currency | Earned by | Spent on | Exists? |
| --- | --- | --- | --- |
| Gold | mobs, selling, quests | enhancement, building, shops, respec, reroll | yes |
| Embers | bosses, vaults, outposts, Blood Ember nights, achievements | hatching, Mythic crafts, beacon banking, ascension | **new** (replaces "diamonds" as the earned rare currency; `diamonds` saved value migrates 1:1) |
| Hero shards | mobs, dungeons | hero stars | yes |
| Valor | LAN arena, bounties | cosmetic and recipe shop | new |
| Renown | quests, raids defended | homestead tier gates (not spendable) | new |

There's no purchasable currency. Embers are the scarce, earned currency.

## 2. Inventory model

| Container | Capacity | Holds | Notes |
| --- | --- | --- | --- |
| **Bag** | 32 → 64 (satchel upgrades) | equipment, consumables, quest items, keys | existing 32 slots |
| **Material pouch** | 40 → 120 stacks, stack 999 | materials, ingredients, runes (unsocketed) | **new**: materials move out of the bag. Never dropped on death (only one equipped or bag item can drop, WORLD §7) |
| **Homestead storage** | 60 per Storehouse level (max 240) | anything | **new**: safe; reachable from beacons with an upgrade |
| Equipment | 9 slots | gear | existing 7 + gloves + cloak |
| Hotbar | 4 skills + 8 items | references only | existing |

Operations, all through `transact`: add, remove, stack, **split stack** (new), move between
containers (new), sort (exists), **filter by category/rarity** (new), **lock slot** (new; protects
from bulk sell/salvage), bulk-sell commons, salvage to Ember Dust.

## 3. Materials and processing chains

```text
Raw (gathered)        Processed (station)          Refined (station)
logs ───────────────► planks (Sawhorse) ─────────► treated planks (Workshop)
copper/iron/silver ─► ingots (Smelter) ──────────► alloys (Forge) ─► frost-silver, ash-iron
hide/pelt ──────────► leather (Tannery) ─────────► hardened leather
herbs ──────────────► extracts (Alchemy Table) ──► elixirs, salves
crystals ───────────► cut crystal (Lapidary) ────► rune blanks
fibre/cotton ───────► cloth (Loom) ──────────────► embroidered cloth (cloaks)
crops ──────────────► meals (Cookfire) ──────────► feasts (Kitchen)
salvaged gear ──────► Ember Dust (Salvage Anvil)
```

About 60 material IDs in v1, roughly 8–12 per tier. Existing IDs (`wood`, `stone`, `iron_ore`,
`gold_ore`, `bone`, `monster_bone`, `herb_segment`, shards, `power_fragment`, `spirit_essence`,
`venom_gland`, `boss_core`, `pet_treat`) are kept and placed in the chains.

## 4. Gathering

| Source | Tool | Speed formula | Respawn |
| --- | --- | --- | --- |
| Trees | axe (any weapon at 0.5×) | `hits = ceil(node_hp / (tool_power × tier_match × gather))` | 3–6 min, per region save |
| Ore veins | pickaxe / hammer | same, ore tier must be ≤ tool tier+1 | 5–10 min |
| Herbs | sickle / dagger | instant pick, 1–3 yield | 4 min, night-only herbs |
| Breakable terrain | any; hammer ×1.5 | tile HP | 10 min regrow |
| Dig plots | shovel (bag tool) | stand to dig (existing) | per plot |
| Crops | hand | growth timer | replant |

**Tools** are a hotbar-independent tool belt (axe, pickaxe, sickle, shovel, rod), tiers 1–5,
crafted at the Workbench or Forge. They're auto-selected by target, so there's no extra button
on mobile. Gather power is affected by tool tier, weapon class bonus, Deepdelver set, Fortune
runes, and pet utility skills.

## 5. Crafting

### Stations

| Station | Where | Crafts | Exists? |
| --- | --- | --- | --- |
| Campfire | world camps in every zone, homestead | basic meals, torches, bandages | new |
| Workbench | homestead | tools, planks, basic gear, building kits | partial (crafting panel) |
| Smelter | homestead | ingots | new |
| Forge | homestead / Hearthmoor smith | weapons, armour, enhancement, ascension, traps | partial (blacksmith NPC) |
| Tannery, Loom | homestead | leather, cloth, cloaks, gloves | new |
| Alchemy Table | homestead / Hearthmoor | potions, elixirs, buffs (existing `*_tonic`, `*_elixir`, `*_brew`) | partial |
| Rune Altar | homestead (Act III) | runes, fusion | partial (augment crafting) |
| Cookfire / Kitchen | homestead | meals (timed buffs), pet food | new |
| Hatchery | homestead | eggs → pets | new |
| Salvage Anvil | homestead | gear → Ember Dust | new |

### Recipe model (extends `CraftingRecipe`)

```text
Recipe {
  id, result_id, result_qty, rarity_roll?: {table}
  inputs: [{id, qty}], gold, embers
  station: id, station_level
  duration_s           # 0 = instant; otherwise queued
  success: 1.0         # < 1 only for runes / Mythic
  unlock: {level?, quest?, recipe_scroll?, codex?}
  category, tier
}
```

- **Queues**: each station has 1–3 queue slots by level. Timers run in real time, including
  offline (same mechanism as existing building production).
- **Unlocks**: recipe scrolls dropped by bosses/outposts/vaults, quest rewards, NPC side quests.
- **Rarity on craft**: crafted gear rolls rarity from a station-level table, with a floor of
  Uncommon. Mythic only from Vault recipes.
- The existing 1–3 tier recipes and category tabs are preserved and migrated into this model.

## 6. Shops and NPC trade

| NPC | Sells | Buys |
| --- | --- | --- |
| Smith (existing) | tools T1–T2, basic gear | gear (sell value) |
| Merchant (existing) | potions, satchel upgrades, seeds | materials at 30% |
| Quartermaster (new) | building kits, trap blueprints | — |
| Stablekeeper (new) | feed, saddles, eggs (rotating) | — |
| Wandering merchant (event) | rare recipes, eggs, cosmetics | — |
| Valor vendor (new) | cosmetics, titles, rune blanks | — |

Shop stock and prices are data-driven, with weekly rotation slots.

## 7. Sources and sinks (balance frame)

| Flow | Sources | Sinks |
| --- | --- | --- |
| Gold | mobs, selling, quests, Gold Press building | enhancement (~45%), building (~25%), rerolls/respec (~15%), shops (~15%) |
| Embers | bosses, vaults, outposts, nights, achievements | hatching, ascension, Mythic, beacon banking, relic evolution |
| Materials | gathering, terrain, production buildings, salvage | crafting, building, enhancement, feeding |
| Gear | drops, crafting | salvage, ascension fodder, selling |

Targets for TEST: a player at the zone's recommended GS can afford one enhancement attempt per
~10 minutes of farming that zone. Gold income per hour by zone: Normal 2k–8k, Ash 15k–45k,
Snow 70k–120k (rising across sub-areas), with costs scaled to match. A simulation script (headless) will check the
curves before tuning by hand.

## 8. Farming

- **Farm plots** are homestead grid buildings: 2×2, levels 1–3, with crop slot count by level.
- Seeds from the merchant, herb drops and the wandering merchant. 12 crops in v1, each with a
  growth time of 10 min–8 h and a season affinity (event calendar).
- Watering (optional) via a Well building or rain: +25% yield. Scarecrow building: prevents crow
  losses during Ashfall.
- Outputs: cooking ingredients, pet food, alchemy inputs, cloth fibre.

## 9. Anti-exploit rules

- Every economic mutation goes through `transact` (atomic). LAN uses the host's copy as the
  authority, with idempotency IDs (existing loot-ACK pattern).
- Offline timers use a saved monotonic timestamp. A backwards clock jump pauses production
  instead of rewarding. A forward jump is capped at 24 h of production.
