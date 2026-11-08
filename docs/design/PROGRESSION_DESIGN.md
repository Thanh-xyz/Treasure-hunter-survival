# Equipment and Progression Specification

- Stage: BRAINSTORM · 2026-11-07
- Builds on: `GameState`, `CharacterStats`, `ItemData`, `InventoryData`, `GameContent.HEROES`,
  augment system. All numbers are starting values in data tables.

## 1. Character progression

| Layer | Range | Source | Effect |
| --- | --- | --- | --- |
| Player level | 1–45 | XP from kills, quests, first-time gathers/crafts | Base stat growth (existing `growth`), skill points, region gates |
| Hero stars | 1–5 (existing `HERO_MAX_STARS`) | hero shards | +% base stats, unlocks third tree branch at ★3, ultimate at ★5 |
| Skill tree | 3 branches × 5 nodes per hero | 1 point per level from 2 | Modifies the three hero skills and the passives |
| Gear score | derived | equipment, runes, pet, mount | Displayed power, region recommendations, matchmaking hint |
| Codex | account-wide | bestiary, exploration, collections | Small capped account bonuses |
| Ember Cycles (opt-in) — **deferred until after the first release** (owner decision) | prestige 0–10 | endgame | Reset level and regions; keep collection; +permanent "Ember Mark" bonuses |

XP curve: keep the existing `GameContent` curve shape and extend to 45. Target ~1 level per
45–60 min in Act III.

### Skill trees (example: Warden)

| Branch | Theme | Sample nodes |
| --- | --- | --- |
| Bulwark | Defence | Cleave gains a 1 s shield; +DEF %; block chance on Charge |
| Vanguard | Damage | Cleave radius +20%; War Cry adds crit; Charge stuns 0.8 s |
| Warden-Captain | Support (LAN) | War Cry affects allies; taunt aura; revive allies 30% faster |

Ranger branches: Skirmish / Marksman / Trapper. Mystic branches: Pyre / Rime / Hearth (heals).
Respec costs gold, and is free once per level band.

## 2. Combat attributes

| Stat (key) | Default | Notes | Exists? |
| --- | --- | --- | --- |
| Max HP (`hp`) | hero base | | yes |
| Attack (`atk`) | hero base | | yes |
| Defense (`def`) | hero base | Mitigation `dmg × 100 / (100 + def×k)` | yes (flat today) |
| Move speed (`spd`) | hero base | Mount multiplies | yes |
| Crit chance (`crit`) | 5% | cap 75% | partial (passive) |
| Crit damage (`crit_dmg`) | +50% | | **new** |
| Attack speed (`aspd`) | 1.0 | Attack cooldown divisor, cap 2.0 | **new** |
| Accuracy (`acc`) | 0 | Offsets target dodge | **new** |
| Dodge (`dodge`) | 0 | Chance to fully evade (`dodge − acc`, clamp 0–60%) | **new** |
| Lifesteal (`ls`) | 0 | % of damage dealt | yes (passive) |
| Counter (`counter`) | 0 | Chance to strike back when hit | **new** |
| Resistances (`res_fire/frost/poison/shock`) | 0 | % reduction of that element and status duration | **new** |
| Stamina (`sta`) | 100 | Dodge roll and skills | partial (stamina potion exists) |
| Gather power (`gather`) | 1 | Tool and rune bonus | **new** |
| Luck (`luck`) | 0 | Rarity roll weight | **new** |

All stat math moves into one pure `StatBlock` aggregator (hero base + level + stars + gear base +
affixes + enhancement + sets + runes + pet + mount + buffs + codex). It is shared by offline play
and the LAN host. This replaces the current scattered `get_total_*_bonus()` sums behind the same
public API.

## 3. Equipment slots

| Slot (id) | Exists? | Notes |
| --- | --- | --- |
| `weapon` | yes | Weapon class decides the attack pattern |
| `shield` | yes | Displayed as **Off-hand**: shield, tome, quiver. ID kept for save compatibility |
| `helmet` | yes | |
| `armor` | yes | |
| `gloves` | **new** | |
| `boots` | yes | |
| `cloak` | **new** | |
| `accessory_1`, `accessory_2` | yes | rings, amulets |

Seven to nine slots. New slots are additive; old saves simply have them empty.

## 4. Weapon classes

| Class | Pattern | Hero affinity (+10% dmg) | Gather bonus |
| --- | --- | --- | --- |
| Sword | 3-hit arc combo | Warden | — |
| Axe | slow wide arc, armour break | Warden | wood ×1.5 |
| Hammer/Mace | slam, stagger | Warden | stone/ore ×1.5 |
| Dagger | fast single, bleed | Ranger | herbs ×1.3 |
| Bow | bolt, pierce at high rank | Ranger | — |
| Staff | nova burst | Mystic | — |
| Tome (off-hand) | orbiting embers | Mystic | — |

Any hero can use any weapon. Affinity is a bonus, not a lock.

## 5. Rarity

| Tier (enum) | Colour + frame shape | Affix lines | Drop weight (base) |
| --- | --- | --- | --- |
| Common (0) | grey, plain | 0 | 600 |
| Uncommon (1) | green, notched | 1 | 250 |
| Rare (2) | blue, double | 2 | 110 |
| Epic (3) | purple, studded | 3 | 32 |
| Legendary (4) | orange, flame | 4 | 7 |
| **Mythic (5)** — new | crimson-gold, animated | 4 + 1 unique | crafted / vault only |

`ItemData.ItemRarity` gains `MYTHIC = 5`, appended so existing values don't change. Rarity is not
stored per instance in saves today, so this is safe.

## 6. Item instances, affixes and requirements

Equipment becomes **instance-based** (template + rolled data), generalising today's
`set_reference_instance_data`:

```text
EquipmentInstance {
  uid: String            # stable per instance, needed for LAN and trading
  template_id: String    # e.g. "ironbark_axe"
  rarity: int
  item_level: int        # roll band
  enhance: int           # +0..+15
  affixes: [{stat, value, tier}]
  runes: [rune_uid|null] # socket count by rarity
  ascension: int         # 0..2
  bound: bool            # LAN trade binding
}
```

- Affix pool per slot (for example, weapons: atk%, crit, crit_dmg, aspd, acc, ls, element on-hit).
  Value range scales with item level and affix tier.
- Requirements: player level ≥ item level − 2. Mythic needs a quest unlock.
- **Reroll** (Reforging Bench): reroll one affix for gold plus Ember Dust; lock other affixes
  for extra cost.

## 7. Enhancement (+0 … +15)

| Range | Success | On failure | Cost scale |
| --- | --- | --- | --- |
| +1 … +6 | 100% | — | gold + ingots |
| +7 … +9 | 80 / 70 / 60% | materials consumed | + ember dust |
| +10 … +12 | 50 / 40 / 30% | materials consumed; 50% chance to drop 1 level | + rift crystal |
| +13 … +15 | 25 / 20 / 15% | drop 1 level | + ember core |

- **Ward Charm** (crafted) prevents the level drop. **Pity**: +5% per consecutive failure,
  reset on success.
- Each + gives +6% base stats (+8% from +10). Milestones +5/+10/+15 unlock a socket or affix tier.
- Replaces today's always-succeeds `upgrade_equipment` cost curve. The existing levels map 1:1
  (see SAVE_MIGRATION_PLAN).

## 8. Ascension

At the Forge, an Epic or Legendary item plus a duplicate-class item of the same rarity plus
materials becomes the next rarity. The item keeps its affixes, gains one new affix, and rerolls
base stats within the new band (never lower than before). Mythic ascension needs an Ember Vault
core.

## 9. Sets

Each zone drops two named gear sets (5 pieces across weapon/helmet/armor/gloves/boots), each
with a theme:

| Set | Zone | 2-piece | 4-piece |
| --- | --- | --- | --- |
| Meadowguard | Normal | +8% HP | Heal 3% HP on kill |
| Thornweave | Normal | +6% crit | Hits apply bramble bleed |
| Deepdelver | Ash (Gloamdeep Mines) | +25% ore gather | Light radius +50%, +10% DEF in dungeons |
| Cinderbound | Ash | +10% fire res | Burning enemies take +15% damage |
| Rimewarden | Snow | +10% frost res | Every 5th hit freezes 0.6 s |
| Wayfarer | Snow | +10% all res | −50% death item-drop chance in danger zones; night stalkers deal −20% damage to you |

## 10. Runes (generalised augments)

The existing **Augment** system (stat boost / passive / active skill / timed buff) becomes
**Runes** in the UI, keeping the code name `augment` to avoid churn.

- Tier I–V. Higher tiers come from harder zones (Normal I–II, Ash II–IV, Snow III–V), bosses and vaults.
- Socket hosts: equipment (by rarity 0–3 sockets), **pets (2)**, **mounts (2)**. This generalises
  `apply_augment(equip_slot, …)` to any socket host.
- Families: Might (atk/crit), Bulwark (hp/def/res), Swiftness (spd/aspd/dodge), Fortune (gold/
  drop/luck), Elemental (burn/freeze/poison/shock on hit), Arcane (summon wisp, nova on crit,
  last-stand fury).
- Fusion at the Rune Altar: 3 same-tier same-family become 1 next tier (success 100/90/75/60%).
  Failure returns 1 rune.
- Existing items `flame_augment_t1..t3` and others keep their IDs as Rune templates.

## 11. Relics (trinket progression, replaces the "artifact" concept)

Two relic slots unlocked in Act III. A relic has a passive plus an **aura** (personal offline,
radius ally aura on LAN). Relics level up by feeding Ember Dust and evolve at levels 10 and 20.
Example: *Lantern of the First Kindler* (light radius, +ally regen aura).

## 12. Item comparison and power

- Long-press tooltip: side-by-side with the equipped item, per-stat delta, set count change, gear
  score delta.
- `gear_score = Σ(slot_weight × item_power) + rune_power + pet_power + mount_power`. Shown on HUD
  and region gates as "recommended GS".
