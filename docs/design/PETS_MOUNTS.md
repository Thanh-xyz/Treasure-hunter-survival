# Pets and Mounts Specification

- Stage: BRAINSTORM · 2026-11-07
- Builds on: `PetFollower` (follow, attack, heal, evolve at Lv5/Lv10), `GameContent.PETS`
  (4 pets with roles), `GameContent.MOUNTS` (4 mounts: speed/attack/defense, skins), Stable
  building, pet treats.

## 1. Pets

### Roster (v1: 12; existing 4 kept)

| Pet (id) | Role | Rarity range | Source |
| --- | --- | --- | --- |
| Ember Fox (`ember_fox`) | attack | Common–Legendary | existing; starter quest |
| Moss Turtle (`moss_turtle`) | defence | Common–Epic | existing |
| Dusk Owl (`dusk_owl`) | support | Uncommon–Legendary | existing |
| Lucky Cat (`lucky_cat`) | utility (luck) | Uncommon–Legendary | existing |
| Thorn Pup | attack, bleed | Common–Epic | Normal-zone egg |
| Glowmoth | utility, light radius | Uncommon–Epic | Gloamdeep Mines (Ash) |
| Pebble Golem | defence, taunt | Rare–Legendary | Hollowfolk outposts (Ash) |
| Cinder Imp | attack, burn | Rare–Legendary | Ash-zone egg |
| Frost Kit | support, chill | Rare–Legendary | Snow-zone egg |
| Ash Raven | utility, finds secrets | Epic–Legendary | Kindled Key vaults |
| Hearth Drakeling | attack, fire breath | Legendary–Mythic | Ember Vault |
| Lantern Wisp | support, heal + light | Epic–Mythic | achievement line |

Existing IDs are the real keys in `GameContent.PETS` and stay unchanged. Existing mount IDs are
`dust_pony`, `tusk_boar`, `shell_tortoise`, `gale_stag`.

### Acquisition
- **Eggs** drop from regions, bosses and vaults, or come from the Stablekeeper's rotating stock.
  Hatched at the Hatchery (timer 30 min–12 h by rarity, costs embers). Hatching rolls the
  rarity within the egg's range, weighted by Hatchery level.
- Quests and achievements give specific pets.

### Progression
| Layer | Range | Input |
| --- | --- | --- |
| Level | 1–30 | food (`pet_treat`, crops, meals); XP shared from kills |
| Evolution | 3 forms at Lv 1 / 10 / 20 | visual change + skill upgrade (existing evolve at 5/10 remaps to 10/20) |
| Stars | 1–5 | duplicate pets or pet shards |
| Rarity ascension | up to the pet's cap | ascension stone + embers |
| Runes | 2 sockets | same Rune system as gear |

### Abilities
- 1 active (auto-cast on cooldown, AI-driven) plus 1 passive (owner aura) plus 1 utility at
  evolution 2 (auto-loot magnet radius, gather assist, secret ping, light).
- Pet AI states (extend `PetFollower`): FOLLOW, ENGAGE (target owner's target), SUPPORT (heal or
  shield below HP threshold), FETCH (collect loot), GATHER (assist the node owner is hitting),
  STAY (command).
- Pets can be downed (not killed). They revive after 10 s or on owner interaction.

### Collection bonus
Owning N distinct pets gives small account-wide stat bonuses (codex).

## 2. Mounts

### Roster (v1: 10; existing 4 kept)

| Mount | Category | Signature | Source |
| --- | --- | --- | --- |
| Dust Pony | speed | — | existing; Act I quest |
| Tusk Boar | attack | charge-through | existing |
| Shell Tortoise | defence | shell-up (damage reduction) | existing |
| Gale Stag | speed | double dash | existing |
| Bramble Ram | attack | knock-back butt | Normal zone |
| Cave Strider | utility | climb ledges (shortcuts) | Gloamdeep Mines (Ash) |
| Rime Elk | speed | ice-walk (no slide) | Snow zone (tamed) |
| Ash Hound | attack | ignores Ash-touched | Hollowfolk outposts (Ash) |
| Ember Drake (ground) | utility | hover over lava/ash pits | Ember Vault |
| Lantern Moth | utility | light radius, glide | achievement |

### Mechanics
- Mount/dismount (existing toggle). Mounted: speed × category multiplier, no gathering, no basic
  attack except the mount's signature move. Taking damage over 15% max HP dismounts you.
- **Mount level 1–20** via Stable training (time plus feed). Raises speed and signature power.
- **Gear**: saddle (stat), barding (defence), plus 2 rune sockets.
- **Skins**: existing skin list kept, with more as achievement and event rewards.
- Mount stamina for sprinting, regenerating when idle.

### Collection
The mount codex gives account-wide bonuses (for example +1% move speed per 3 mounts, capped),
an idea generic to collection games.

## 3. Save and LAN

- Pets and mounts become instance records `{uid, species, rarity, level, xp, stars, evolution,
  runes[], skin}` (save v10). Existing `pets` (species → level dict) and `mounts`
  (`{skin, skins}`) migrate to one instance per owned species.
- On LAN, each peer's active pet and mount are simulated on the host as allies of that peer. The
  host owns pet damage. Clients send only commands.
