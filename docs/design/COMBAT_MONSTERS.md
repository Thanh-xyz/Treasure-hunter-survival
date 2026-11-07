# Combat and Monster Specification

- Stage: BRAINSTORM · 2026-11-07
- Builds on: Hitbox/Hurtbox/Health components (LOS, i-frames, knockback), `Combat` helper,
  `Monster` profiles (melee / flyer / ranged / charger / stationary_melee), `Boss` (2 phases),
  `HeroSkillRunner`, `SkillComponent` (equipment skills), `PassiveEffectProcessor`, telegraphs,
  projectiles, damage numbers.

## 1. Player combat

| Action | Input (mobile / desktop) | Notes | Exists? |
| --- | --- | --- | --- |
| Basic attack | attack button / A, hold to repeat | Weapon-class pattern (PROGRESSION §4), soft auto-aim to nearest target in a 70° cone | yes (pattern per hero, not per weapon) |
| Dodge roll | swipe-flick on the attack button or a dedicated button / Space | 0.35 s, i-frames 0.25 s, 25 stamina, 0.6 s cooldown | **new** |
| Hero skills ×3 | Z/X/C + buttons | Existing three per hero, modified by the tree | yes |
| Gear skills ×2 | Q/E | From runes with the active-skill family; existing Q/E/R/F model reduced to 2 slots to fit portrait | yes (4 slots → 2 + migration) |
| Potion | H / button | Shared cooldown 6 s | yes |
| Interact / gather | E / context button | Auto-chooses tool | yes |

### Damage formula (pure, shared offline and on LAN host)

```text
hit?      = rand() >= clamp(target.dodge - attacker.acc, 0, 0.60)
base      = attacker.atk × skill_mult × class_affinity
crit?     = rand() < attacker.crit           → base × (1.5 + attacker.crit_dmg)
mitigated = base × 100 / (100 + target.def × 1.0)
elemental = mitigated × (1 - target.res[element])
final     = max(1, round(elemental × vulnerability × variance(0.95..1.05)))
counter?  = target.counter chance → counter hit at 50% power
lifesteal = final × attacker.ls
```

This moves the existing scattered calculation into `sense/combat/combat.gd` as a pure function
with a seeded RNG parameter, so it can be tested and LAN-replayed.

## 2. Status effects

A new `StatusEffectComponent` replaces the TODO at `passive_effect_processor.gd:117`. It is
attached to the player and every monster.

| Effect | Behaviour | Stacking | Source |
| --- | --- | --- | --- |
| Burn | DoT 3%/s for 4 s | refresh | fire runes, Cinder mobs |
| Poison | DoT 2%/s for 6 s, −20% healing | 3 stacks | venom mobs, Fungal Shaman |
| Bleed | DoT on movement | 5 stacks | daggers, Briar Wolf |
| Chill → Freeze | −30% speed; 3 chills = 0.8 s freeze | escalate | frost runes, Frostvale |
| Shock | next hit chains to 2 targets | — | shock runes |
| Stun | no action | immunity 3 s after | hammer, bosses |
| Armour break | −25% DEF | refresh | axe |
| Ash-touched | −10% max HP while in an Ash zone at night without a torch | — | environment |

Resistances shorten the duration and reduce the DoT.

## 3. Monster model

A data row in `GameContent.MONSTERS` (existing). New fields are marked +.

```text
id, name, visual/asset_id, ai, level, hp, dmg, def+, spd, xp, gold, loot(table id+),
range, aggro, leash+, attack_interval, telegraph+, element+, res+, statuses+,
behaviours+ [patrol|guard|pack|flee_low_hp|summoner|burrow|kite],
elite_affixes+ (for elite rolls), night_only+, biome+
```

### AI state machine (generalised from `monster.gd`)

```text
IDLE ─► PATROL ─(aggro)─► CHASE ─(in range)─► WINDUP (telegraph) ─► ATTACK ─► RECOVER
  ▲                         │  ▲                                              │
  └──────── RETURN ◄─(leash)┘  └──────────────────────────────────────────────┘
                 ▲
     RETREAT (flee_low_hp / kite) ── HURT / STAGGER ── DEAD ─► loot, xp, events
```

New states: `RETURN` (leash and heal), `RETREAT`, `WINDUP` (every attack is telegraphed so
combat is readable), `STAGGER` (poise break).

### Ranks

| Rank | HP × | Dmg × | Extras | Loot |
| --- | --- | --- | --- | --- |
| Normal | 1 | 1 | — | biome table |
| Elite | 3 | 1.4 | 1 elite affix (Vampiric, Molten, Swift, Shielded, Splitting, Summoner) | +1 roll, Uncommon floor |
| Champion (camp leader, bounty) | 8 | 1.8 | 2 affixes, named | Rare floor, recipe scroll chance |
| Field boss | — | — | 2 phases | guaranteed set piece chance + embers |
| World boss | — | — | 3 phases, timed window | last-hit + participation tiers |
| Dungeon / Vault boss | — | — | 3 phases + arena mechanic | boss-exclusive table |

## 4. Roster (original designs)

Monster IDs `slime`, `shroom`, `boar` are kept for save/quest/LAN compatibility; only their
display names and visuals change. `snailu` and `turtle` retire (SAVE_MIGRATION_PLAN).

| Biome | Monster (id) | AI | Role |
| --- | --- | --- | --- |
| T1 | Gnatling (`slime`, was "Mosqui") | flyer | swarm chip damage |
| T1 | Bramble Snail (`shroom`, was "Snailu") | melee | slow tank, leaves slowing slime |
| T1 | Bristle Boar (`boar`, was "Astromophy") | charger | telegraphed charge |
| T1 | Puffcap (`puffcap`) | ranged | spore lobs, poison |
| T1 | Mossback Tortoise (`mossback`, replaces `turtle`) | stationary guard | tutorial target, shell-up phase |
| T1 night | Dusk Bat (`bat`) | flyer | existing |
| T2 | Briar Wolf, Hornet Swarm, Sapling Treant, Fungal Shaman | pack / swarm / stationary / healer | |
| T3 | Cave Crawler, Glowworm, Golemite, Shade Bat | burrow / light-lure / armoured / dark flyer | |
| T4 | Bone Grunt, Bone Archer (existing), Ash Wisp, Cursed Sentinel | melee / ranged / kamikaze / guard | |
| T5 | Frost Slime (existing), Rime Elk, Ice Troll, Snow Harpy | splitter / charger / regen brute / dive | |
| T6 | Magma Slime (existing), Cinder Hound, Ash Revenant, Ember Drake | splitter / pack / reviver / flyer-breath | |
| Hollowfolk | Raider, Slinger, Shieldbearer, Shaman, Chieftain | outpost units | |
| Ash Hunters | Ashstalker, Pyre Hound | tracker | hunt Kindled Key carriers and Ash-zone nights |

### Bosses

| Boss | Kind | Phase mechanics |
| --- | --- | --- |
| Mire King (existing) | world, T1 | P1 slam + summon slimes · P2 split into 3 mini-kings |
| Hollow Stag | field, T2 | P1 charge lanes · P2 antler bramble walls · P3 enrage at 25% |
| Rootmother | dungeon, T2 | rooted; vines across the arena; destroy 3 bulbs to expose her |
| Geode Wyrm | dungeon, T3 | burrows, crystal shards; break crystals to stagger |
| Lantern Colossus | world, T3 | darkness phase: only lantern light shows its telegraphs |
| Crypt Warden (existing) | dungeon, T1–2 | existing behaviour kept |
| Grey Choir Abbot | field, T4 | revives fallen skeletons; interrupt the chant |
| Bone Colossus (existing) | dungeon, T5 | existing 2 phases + P3 bone storm |
| Glacier Behemoth | world, T5 | freezing floor zones; shatter armour with fire |
| Pyre Sovereign | vault, T6 | 3 phases; Kindled Key bearers deal +20% damage |

Boss rewards follow the generic pattern of **last-hit bonus + participation tier by damage
share** (top 1 / ≥10% / any). Offline the player gets both. On LAN, rewards are split per peer
by the host.

## 5. Loot tables

`LootTable` (existing weighted) is extended to nested tables:

```text
table_id: {
  rolls: 1..n, guaranteed: [entries], entries: [{id|table, weight, qty: [min,max], cond?}],
  rarity_table?: "rarity_t3",   # for gear
  pity?: {id, after: N}         # e.g. boss-exclusive guaranteed after 10 kills
}
```

Conditions include `night`, `elite`, `first_kill`, `event:blood_ember`, and `luck` scaling of
rarity weight (≤ +30%). Boss-exclusive items carry `bound: true` on LAN.

## 6. Difficulty scaling

- Monster level by region band. Damage and HP grow ~12% per level.
- Under-levelled warning on region entry when GS < 80% of the recommendation.
- LAN party scaling: monster HP × (1 + 0.6 × (players − 1)); boss HP × (1 + 0.8 × (players − 1)).

## 7. Feel targets (TEST checklist)

- Input-to-swing < 50 ms; hit-stop 40–60 ms on crit; damage numbers coloured by element/crit.
- Every enemy attack telegraphs ≥ 0.4 s (bosses ≥ 0.7 s), so dodge can always answer it.
- No unavoidable damage except DoTs and environment.
