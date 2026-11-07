# Treasure Hunting Specification

- Stage: BRAINSTORM · 2026-11-07
- Builds on: `DigSpot` (stand to dig, staged cracks, reward roll), chest pickups, `LootTable`,
  `RewardBoxResolver` (resolution and claim journal; reference box IDs will be retired).

## 1. Layers

| Layer | Risk | Reward | Region |
| --- | --- | --- | --- |
| Buried caches (dig plots) | none | materials, coins, map fragments | all |
| Treasure maps | low–medium | Rare+ cache, recipe scroll | all |
| Hidden locations (secret rooms, cracked walls, sealed cellars) | low | codex + cache | all |
| Dungeon chests and secret rooms | medium | gear, runes | dungeons |
| Outpost storage | medium | materials, embers | T3+ |
| **Kindled Keys → Ember Vault caches** | **high** | embers, tier-IV/V runes, eggs, Mythic recipe | Ash zones |
| Ember Vault (dungeon) | very high | Mythic gear, vault-exclusive pets/mounts | T6 |

## 2. Treasure maps

- **Fragments** drop from terrain, dig plots and mobs. 4 fragments make a **Weathered Map**
  (T1–T3). Rare drops make **Gilded Maps** (T4+).
- Reading a map rolls a target location in a region (seeded, saved), shown as a sketched
  minimap clue: a landmark silhouette plus a distance ring that tightens as you approach.
- At the spot a special dig plot appears. Digging it may spawn **guardians** (mimic chest,
  champion, or a Hollowfolk ambush) before the cache opens.
- Map quality affects reward table and guardian chance. Maps are tradeable on LAN.

## 3. Kindled Keys (the marked-carrier mechanic)

This is Emberfield's own risk-versus-reward rule. Public sources only say the reference game's
keys can be taken by killing the holder; the reveal, hunter and channel rules here are original.

### Acquisition
- Rare drop from breaking **ash crust** terrain, Ash-zone elites, outpost chieftains and Blood
  Ember nights. Never purchasable.

### While carrying (the "Kindled" state)
1. The key occupies a bag slot and **can't be banked, stored or dropped by choice**.
2. The carrier glows. Their position is **marked on every minimap**: for LAN peers, and for the
   AI director offline.
3. Mount speed is reduced by 30% (the key is heavy). Fast travel is disabled.
4. **Ash Hunters** spawn on a timer (first after 45 s, then every 60–90 s, escalating). They track
   the carrier from off-screen.
5. If the carrier hasn't reached a vault in 10 minutes, the key **gutters**: the hunter rate
   doubles. After 15 minutes it burns out into Ember Dust (a consolation reward).

### Opening
- Each Ash region has 2–3 **Ember Vault caches** (fixed landmark positions per seed).
- The carrier must **channel 60 s** at the cache. Taking damage pauses (doesn't reset) the channel.
  Hunters spawn in a final wave during the channel.
- Rewards: embers (40–120), a tier IV–V rune, a chance at an egg or mount token, Vault recipe
  scraps. Better rewards if channelled at night or during Blood Ember.

### Death and theft
- On death the key drops at the death spot (always, regardless of Ash-zone rules). It stays
  marked for 2 minutes, then returns to the terrain pool.
- **LAN PvP** (opt-in or in the Ashen Wastes PvP flag): killing a carrier takes their key. In
  co-op without PvP, a party can **escort**: allies near the carrier get +10% damage, and hunters
  split their focus.

### Tuning knobs (data)
`hunter_first_delay`, `hunter_interval`, `gutter_time`, `burnout_time`, `channel_time`,
`speed_penalty`, `reward_table_by_region`.

## 4. Ember Vault (endgame dungeon)

- Entry costs one **Vault Sigil**, crafted from 5 Vault recipe scraps plus embers.
- 3 wings (procedural rooms from the existing dungeon generator) with vault traps (flame jets,
  falling ash, sealed doors needing switches), then the Pyre Sovereign.
- Exclusive loot: Mythic templates, vault pets/mounts, relic evolution cores.
- Weekly lockout for the boss chest. The wings remain farmable.

## 5. Hidden locations

- Cracked walls and brambles are breakable terrain variants with a subtle visual tell.
- A Dowsing Rod (bag tool, T2 recipe) pings within 12 tiles when a secret or buried cache is
  near.
- Each region has 3–5 authored secret stamps. Finding them all completes the region codex.

## 6. Systems touched

| System | Change |
| --- | --- |
| `DigSpot` | Support "map target" and "guardian" variants |
| Terrain layer | Ash crust tiles drop keys and fragments |
| `GameState` | Carried key state, active maps, opened caches (save v7 world section) |
| Minimap | Carrier mark, map clue overlay |
| AI director | New `AshHunterDirector` per region |
| LAN | Key ownership host-authoritative; carrier position broadcast; PvP transfer |
| Quests | `open_vault`, `read_map`, `find_secret` objectives |
