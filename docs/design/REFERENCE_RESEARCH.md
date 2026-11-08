# Reference Gameplay Research — Treasure Hunter – Survival

- Stage: BRAINSTORM · 2026-11-07
- Purpose: understand the **categories and general mechanics** of the reference game so Emberfield
  can reach comparable breadth and depth with its own design. This document is not a content
  source. Names below appear only so they can be avoided.

## Sources

| Tag | Source | Result |
| --- | --- | --- |
| AS | App Store listing `id6476144608` | Read |
| WIKI | `wiki.treasurehunter.asia` — llms index + 13 system pages (equipment, ingredient, object, pet-mount, artifact, mobs, boss, viking, clan, arena, final-war, daily-activities, items) | Read; pet-mount page partly truncated |
| GDWC | `thegdwc.com/games/f0770b4a-…` | **HTTP 404** — no data |

Not used, deliberately: `assets-ths/**` (decompiled XAPK and its configs), `docs/original-captures/`,
the reference research already in `docs/research/treasure-hunter-survival/`, and the in-repo
reference catalogs. See [ASSET_LICENSE_AUDIT.md](../reports/ASSET_LICENSE_AUDIT.md).

Not found publicly: quest structure, character levels/classes/XP, a personal (non-clan) village,
player-to-player trading, and player/server counts.

## Product facts

- Free-to-play mobile (iOS/iPadOS, Android). Monetised with loot-box IAPs, cosmetic boxes,
  ad-skip packs and optional rewarded ads. Rated 12+.
- Online, server-based, with region server windows (Asia, EU/US) and server transfers.
- Roughly **monthly seasons**. At season end gold and most equipment reset; pets, mounts,
  cosmetics, artifacts and premium currency carry over.
- Mentioned features include an auto-farm/auto-move mode, mail, cosmetics, chat and PvP.
- Player reviews mention a pay-focused design and a missing inventory sort.

## System-by-system summary (general mechanics)

### A. Character
- Stats named publicly: HP, damage, defense, speed, critical chance, critical bonus, dodge,
  accuracy, counter-attack, lifesteal, multi-target, and elemental on-hit effects.
- Power is gated by equipment and stat stones far more than by character level. A VIP ladder
  (to ~30) adds gear tiers. No class system was documented.

### B. Equipment
- About five gear slots (weapon, helmet, body, back, boots), grouped into themed **sets** with a
  stat focus (damage, health, speed) plus special sets.
- Four rarity tiers. Sources: breaking terrain, mob drops scaled by rarity, an NPC shop, crafting.
- Crafting uses socketable stones plus gold. **Rarity ascension** can raise all stats by a random
  percentage, and higher tiers roll higher.
- Gear can be dismantled.

### C. Inventory and economy
- Separate equipment bag and **ingredient (stone) pouch**, each expandable by special items.
- Currencies: gold (soft), diamonds (premium), shards, clan currencies, arena points and coins.
- Buff potions raise drop rates of a chosen currency for a timed period.
- Mounts can be sold on a market. No general player trading was documented.

### D. World and exploration
- Zones graded by danger: an easy green zone, a mid gray zone, a hard ice zone, timed special
  lands (undead, survival, team arena), a central PvP hub, and a season-end war map.
- Some areas are **safe**: certain items can't be used there.

### E. Gathering and crafting
- The world is made of **breakable terrain tiles**. Each has HP and a drop chance for equipment,
  potions, stones, keys or boss-summon items. Breaking tiles is the main gathering loop.
- Crafting happens at **campfire stations**. Each recipe can be crafted once.
- Clan buildings mine one material type per area indefinitely.

### F. Combat
- Auto-targeted action combat on mobile. Mobs are tiered by zone. Bosses come in field,
  world-on-a-timer, event and clan types, with **last-hit plus participation rewards**.
- Some bosses are summoned with items found by breaking terrain.

### G. Village and development
- Village building is **clan-based**: main building, towers, healing totem, storage, watch tower,
  resource miners, transport building, trophy tower, pet stable and forge.
- A forge produces **elemental traps** and **siege units**. Traps are placed in the world or the
  village and expire unless repaired.
- Villages can be **captured** under score, role and hit-count rules. Shields can be bought.
  Trophies decay over time.
- Fortified **NPC villages** in the hard zone can be raided but not captured.

### H. Pets and mounts
- Rarity tiers like gear. The top tier can take the form of lower tiers.
- Sources: NPC shop, NPC quests, season rankings, boss-dropped summon scrolls, arena
  achievements, and **egg hatching** in a stable building.
- Pets, mounts and cosmetics take stat stones. Collections grant bonuses.

### I. Treasure hunting
- **Keys** found by breaking terrain (or by killing the carrier) open a chest at a fixed location
  after a channel of a few minutes. Rewards are premium currency, high-tier stones, or pets/mounts.
- A second key type works only inside a timed special land.
- Publicly, a key only "can be taken by killing the player who holds it". **No location reveal**
  was documented. Emberfield's "marked carrier" rule is therefore our own design.

### J. Multiplayer and social
- Open-world PvP, a 1v1 arena with entry fee and rating points, and 5-member clan-vs-clan arena
  with totems.
- Clan founding, clan level, scores and trophies. A season-end **faction siege** of a fortress.
- A fixed daily/weekly **event schedule** that unlocks by server age: world boss every 2 hours,
  double gold or double materials on set days, monthly chaos event.

### Extra system — Artifacts
- Consumable-style items that permanently raise stats when used. Legendary ones can evolve, and
  some project an **aura** to nearby allies.

## Takeaways for Emberfield

1. **Depth comes from interlocking systems, not from levels.** Gear, stones, pets, mounts and
   artifacts all feed one stat pool, and every activity drops inputs for another.
2. **Terrain-breaking is the core gathering verb.** Emberfield has resource nodes and dig plots;
   a destructible-tile layer is the biggest structural gap.
3. **Socketable stat stones are the main long-term sink.** Emberfield's augment system is the
   natural home for this. It should be generalised to pets and mounts.
4. **Risk/reward is social**: carried keys, PvP zones, raidable storage. Offline, this needs AI
   pressure (hunters, raids) to work.
5. **The schedule drives retention**: timed bosses, rotating bonus days, seasons. Offline, use the
   local clock.
6. **The reference's monetisation (loot boxes, ad gates, VIP) is not a gameplay system to copy.**
   Emberfield earns everything by play.

## What Emberfield will deliberately do differently

| Reference pattern | Emberfield direction |
| --- | --- |
| Clan-only village | Personal **Homestead** offline, shared in LAN co-op; optional LAN siege mode later |
| Server seasons that wipe gear | Optional **Ember Cycles** (opt-in prestige with permanent bonuses); no forced wipes offline |
| Ice-zone NPC villages | **Hollowfolk Outposts**: raidable camps with their own original faction and buildings |
| Carried key drops on death | **Kindled Key**: carrying it marks you, summons hunters, and must be channelled at a vault |
| VIP tiers and loot boxes | None. Earn-only economy |
| Fixed server event clock | Local-clock event calendar, also mirrored by the LAN host |
| Four rarities | Six rarities, including Uncommon and Mythic |
| No classes | Three hero archetypes (existing) with star progression and skill trees |
