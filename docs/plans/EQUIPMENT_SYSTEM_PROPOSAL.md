# PROPOSAL — Equipment & Stat System (5 slots × 3 lines, HP / ATK / MOVE SPEED)

- Stage: PLAN · 2026-11-08 · **approved by the owner 2026-11-08 with the changes in §0**
- Source: owner brief "Equipment & Stat System Designer" (2026-11-08)
- Mechanics follow the genre pattern the owner asked for (three stat-focused equipment lines);
  every name, number and formula here is original to Cinderwild.

## 0. Owner decisions (2026-11-08) — these override the sections below where they differ

| Topic | Decision |
| --- | --- |
| Formula and table | Approved. Implement now |
| Lines | **Tank / Damage / Balanced** for helmet, armor, boots, back. The third line is **Balanced** (HP and ATK both mid, low speed), not Mobility |
| Speed | **Only the Dagger has outstanding move speed.** No other item has a large speed share, so the diminishing-returns rule isn't needed. A data-driven safety cap (`max_equipment_move_speed`) stays |
| DEF and other stats | Not on base equipment. They come from **stones socketed into equipment**, chosen by the player (the existing augment system becomes stone socketing) |
| Old equipment (~40 items) | Deleted from the game. Saves get the items' sell value back in gold, logged in `migration_log` (never silent) |
| Future equippables (later) | Pets, a special skill, and a non-removable **appearance set** (eyes, face, hair, skin) that can only be replaced by wearing a new one |

Balanced line shares: base HP 0.45 / ATK 0.45 / SPD 0.10, growth 0.475 / 0.475 / 0.05.

### Implemented table (computed by `EquipmentBalance`, 2026-11-08)

Dagger growth was raised to HP 0.20 / ATK 0.35 / SPD 0.45 after the tests found that at
Epic/Legendary levels 7–10 its ATK overtook its speed.

| Item | Slot | Line | L1 Common HP/ATK/SPD | L10 Rare HP/ATK/SPD |
| --- | --- | --- | --- | --- |
| Ironbark Helm | helmet | tank | 90 / 3 / 2 | 317 / 7 / 3 |
| Ember Visor | helmet | damage | 18 / 15 / 2 | 45 / 53 / 3 |
| Wayfarer Hood | helmet | balanced | 54 / 9 / 2 | 181 / 30 / 3 |
| Ironbark Plate | armor | tank | 125 / 3 / 2 | 420 / 8 / 4 |
| Ember Harness | armor | damage | 23 / 20 / 2 | 58 / 69 / 4 |
| Wayfarer Coat | armor | balanced | 70 / 12 / 2 | 235 / 39 / 4 |
| Ironbark Greaves | boots | tank | 81 / 3 / 1 | 285 / 7 / 3 |
| Ember Treads | boots | damage | 16 / 14 / 1 | 40 / 48 / 3 |
| Wayfarer Boots | boots | balanced | 49 / 8 / 1 | 163 / 27 / 3 |
| Ashwood Blade | weapon | sword | 62 / 12 / 2 | 219 / 41 / 5 |
| Ironbark Cleaver | weapon | axe | 8 / 23 / 1 | 25 / 75 / 3 |
| Ember Dirk | weapon | dagger | 23 / 9 / 10 | 93 / 29 / 29 |
| Ironbark Pack | back | tank | 90 / 3 / 2 | 317 / 7 / 3 |
| Ember Quiver | back | damage | 18 / 15 / 2 | 45 / 53 / 3 |
| Wayfarer Cloak | back | balanced | 54 / 9 / 2 | 181 / 30 / 3 |

## 1. Findings — how equipment works today

```text
GameState.compute_base_stats()  (hero base + level growth + stars + pet + mount + buildings)
        │  apply_to_stats()
        ▼
CharacterStats  base_max_health / base_attack_damage / base_defense / base_move_speed
        + equipment_*_bonus   ◄── apply_equipment_bonuses(inventory)
        + buff_*_bonus        ◄── BuffComponent
        × speed_multiplier / attack_multiplier (mount, War Cry)
        ▼
max_health, attack_damage, defense, move_speed  → Player movement (velocity), Combat, LAN profile
```

| Area | Current state | File |
| --- | --- | --- |
| Item stats | `attack_bonus`, `defense_bonus`, `health_bonus`, `speed_bonus` per template; upgrade multiplies **all** by 1.1^(level−1) | `sense/items/item_data.gd` |
| Slots | 7: helmet, armor, weapon, **shield**, boots, **accessory_1/2** | `inventory_data.gd`, `save_service.gd` |
| Totals | `InventoryData.get_total_*_bonus()` sums equipped items + augments | `inventory_data.gd:562+` |
| Character | `CharacterStats.apply_equipment_bonuses()` replaces (doesn't add) equipment bonuses → no double counting today | `character_stats.gd:92` |
| Speed unit | px/s; hero base 118–135; items ±5…15 | `game_content.gd`, `item_database.gd` |
| Defence | `take_damage = max(dmg − defense, 1)`; armour/helmets/shields give DEF | `character_stats.gd` |
| Equipment skills | Q/E/R bound to weapon/**shield**/**accessory** slots | `skill_component.gd:44+` |
| Save | equipment saved as `{slot: {id, qty, level, augments}}`, slots validated against the 7-slot list | `save_service.gd` |
| UI | Inventory panel (tabs, 7 slots, ATK/DEF totals), equipment detail modal (no comparison) | `inventory_panel.gd`, `equipment_detail_panel.gd` |
| LAN | Peer combat profile sends HP/ATK, host clamps | `lan_session.gd` |

Conclusions:
- The stat pipeline is a good fit and stays. The new system plugs in where
  `InventoryData.get_total_*_bonus()` is computed.
- Moving to the brief's **5 slots** removes `shield` and both accessory slots. That affects saves,
  equipment skills and existing items (see §7). It is a save-format change 🔒.
- The brief's three core stats don't include **DEF**. Combat currently uses it (§7, decision D2).

## 2. Slots and lines

| Slot (id) | Tank | Damage | Mobility |
| --- | --- | --- | --- |
| Helmet (`helmet`) | tank | damage | mobility |
| Armor (`armor`) | tank (highest HP of all armour) | damage | mobility |
| Boots (`boots`) | tank | damage | mobility (**strongest speed slot**) |
| Weapon (`weapon`) | **Sword** (`sword`): HP + ATK balanced | **Axe** (`axe`): ATK, ~no HP | **Dagger** (`dagger`): speed, ATK below axe |
| Back (`back`, new) | tank | damage | mobility |

## 3. Data model (no per-item stats in gameplay code)

Three small data tables drive every item. Adding a new item is one row, with no new logic.

```text
EquipmentLines (slot, line) → base_share {hp, atk, spd}, growth_share {hp, atk, spd}
SlotBudget     slot          → budget multiplier
Rarity         rarity        → budget multiplier
EquipmentTemplate  id, name, icon_id, slot, line, rarity, [stat_override]
EquipmentInstance  uid, template_id, level (1–10), augments   (saved)
```

**Stat formula** (pure function `EquipmentStats.compute(template, level)`):

```text
points(slot)      = 120 × SlotBudget[slot]                     # level 1, Common
budget(L, R)      = points(slot) × Rarity[R] × (1 + 0.12 × (L − 1))
extra             = budget − points(slot)
stat_points[s]    = points(slot) × base_share[s] + extra × growth_share[s]
HP = stat_points.hp ÷ 1      ATK = stat_points.atk ÷ 6      MOVE SPEED = stat_points.spd ÷ 8
```

- **Conversion weights** (1 ATK = 6 HP, 1 speed = 8 HP) make "equal power" measurable. They are
  based on hero growth (Warden: +14 HP per +2 ATK per level).
- **Growth share** puts upgrades mostly into the line's main stat, so a Tank item stays a Tank
  item at every level (the brief's §4 rule). Upgrades don't scale everything evenly.
- An optional `stat_override` exists for rare hand-tuned items (bosses, events). The gate test
  still checks its power budget.

| Table | Values |
| --- | --- |
| SlotBudget | helmet 1.0 · armor 1.3 · boots 0.9 · weapon 1.3 · back 1.0 |
| Rarity | Common 1.00 · Uncommon 1.25 · Rare 1.55 · Epic 1.90 · Legendary 2.30 |
| Level growth | +12% budget per level, levels 1–10 (existing upgrade range) |

| Line | base_share HP/ATK/SPD | growth_share HP/ATK/SPD |
| --- | --- | --- |
| tank (armor: 0.80/0.10/0.10) | 0.75 / 0.15 / 0.10 | 0.85 / 0.10 / 0.05 |
| damage | 0.15 / 0.75 / 0.10 | 0.10 / 0.85 / 0.05 |
| mobility (boots: 0.075/0.075/0.85) | 0.15 / 0.15 / 0.70 | 0.30 / 0.30 / 0.40 |
| axe | 0.05 / 0.90 / 0.05 | 0.05 / 0.90 / 0.05 |
| sword | 0.40 / 0.48 / 0.12 | 0.45 / 0.50 / 0.05 |
| dagger | 0.15 / 0.35 / 0.50 | 0.25 / 0.40 / 0.35 |

## 4. Proposed starting table — all 15 items (Level 1, Common)

| Slot | Line | HP | ATK | MOVE SPEED | Power (budget) |
| --- | --- | --- | --- | --- | --- |
| Helmet | Tank | **90** | 3 | 2 | 124 (120) |
| Helmet | Damage | 18 | **15** | 2 | 124 (120) |
| Helmet | Mobility | 18 | 3 | **10** | 116 (120) |
| Armor | Tank | **125** | 3 | 2 | 159 (156) |
| Armor | Damage | 23 | **20** | 2 | 159 (156) |
| Armor | Mobility | 23 | 4 | **14** | 159 (156) |
| Boots | Tank | **81** | 3 | 1 | 107 (108) |
| Boots | Damage | 16 | **14** | 1 | 108 (108) |
| Boots | Mobility | 8 | 1 | **11** | 102 (108) |
| Weapon | Axe | 8 | **23** | 1 | 154 (156) |
| Weapon | Sword | **62** | **12** | 2 | 150 (156) |
| Weapon | Dagger | 23 | 9 | **10** | 157 (156) |
| Back | Tank | **90** | 3 | 2 | 124 (120) |
| Back | Damage | 18 | **15** | 2 | 124 (120) |
| Back | Mobility | 18 | 3 | **10** | 116 (120) |

Same-slot items stay within ±7% of their budget (rounding only). Starting hero for scale:
Warden 120 HP / 10 ATK / 120 speed.

### How it scales (examples)

| Case | HP | ATK | MOVE SPEED |
| --- | --- | --- | --- |
| Axe L10 Rare | 25 | 75 | 3 |
| Sword L10 Rare | 219 | 41 | 5 |
| Dagger L10 Rare | 110 | 32 | 25 |
| 4-piece Tank set (no weapon) L10 Rare | 1339 | 29 | 13 |
| 4-piece Damage set L10 Rare | 188 | 223 | 13 |
| 4-piece Mobility set L10 Rare | 403 | 66 | 102 |
| 4-piece Mobility set L10 Legendary | 639 | 107 | 141 |

### Move-speed rule (needed, decision D3)

Without a limit, a Legendary Mobility set would more than double run speed (+141 on a 120 base),
which breaks camera, collision and combat. Proposal:

```text
effective_equipment_speed = raw            if raw ≤ 60
                          = 60 + (raw−60)×0.5, capped at +100   otherwise
```

Mobility keeps clearly the best speed (and still more HP than the Damage line), but endgame speed
tops out at about +80% of base. Mount multipliers apply on top, as they do today.

## 5. Character totals, swapping and comparison

- `EquipmentManager` (logic in `InventoryData`, no new autoload) owns the 5 slots and exposes
  `equip(index)`, `unequip(slot)`, `preview_swap(index) → {before, after, delta}`.
- `CharacterStatCalculator.compute(base, equipped, buffs) → {hp, atk, spd}` is a pure function.
  It's used by `CharacterStats`, the UI comparison and the LAN host. Totals are always **recomputed
  from the equipped set**, never incremented, so repeated swaps can't double count (tested).
- Final stats follow the brief's §5 sums (plus the existing buff/mount multipliers).

## 6. Inventory UI

```text
┌───────────────────────────────┐
│        [Helmet]               │
│ [Weapon]  (hero)   [Back]     │   ← 5 slots around the character, rarity frames from the UI kit
│        [Armor]                │
│        [Boots]                │
│  HP 1234   ATK 87   SPD 2,15  │   ← live totals
├───────────────────────────────┤
│ ▢ ▢ ▢ ▢ ▢ ▢  bag grid (rarity frames, HP/ATK/SPD mini-stats)
├───────────────────────────────┤
│ Ironbark Helm · Lv 10 · Rare  │   ← selection card
│ HP +20  ATK +85  SPD +2       │
│ So với đang mặc: HP +20 ▲  ATK +35 ▲  SPD −3 ▼   [Trang bị] [Tháo]
└───────────────────────────────┘
```

Built with the Ember UI kit (P0-5). Deltas are green ▲ / red ▼ (shape plus colour).

## 7. Impacts and migration (🔒 save-format change)

| Change | Effect | Proposal |
| --- | --- | --- |
| Slots 7 → 5 (`shield`, `accessory_1/2` removed, `back` added) | Equipped shields/rings/amulets have no slot | Migration moves them to the bag (overflow → Lost & Found). Keep them as sellable/salvage items |
| Equipment skills bound to shield/accessory | Q/E/R lose their sources | Bind equipment skills to weapon + back + armor in the interim; the full skill redesign stays P3-5 |
| Existing ~40 equipment templates | Use attack/defense/health/speed freely | Re-map each to (slot, line, rarity) and compute stats by formula (decision D4) |
| DEF not in the 3 core stats | Combat uses DEF | **D2** |
| Rarity tiers | Brief lists 5; design docs had 6 (Mythic) | Use the brief's 5; Mythic stays a later extension (data-only) |
| Upgrade curve 1.1^(L−1) on all stats | Replaced by the budget formula | Existing item levels keep their numbers |
| P0-8 starter weapons | Owner said weapon stats come later | The three starters become **Sword / Axe / Dagger** rows of this table (`ashwood_blade` sword, `ironbark_cleaver` axe, `ember_dirk` dagger) |
| Save version | equipment slots + item instance data | New save version after v6. Fixtures from P0-4 prove no loss |
| LAN | profile stats unchanged in shape | Protocol bump for slot set |

## 8. Implementation plan (after approval)

| Step | Deliverable | Tests |
| --- | --- | --- |
| E1 | `EquipmentStats` tables + pure formula; `EquipmentTemplate` rows for the 15 base items | budget equality per slot (±7%), primary-stat dominance at every level/rarity, no line dominates another on all three stats |
| E2 | `CharacterStatCalculator` + wiring into `CharacterStats` | sums equal the brief §5 formula; 100 random equip/unequip sequences never double count |
| E3 | 5-slot `InventoryData` + `back` type + weapon classes | equip/unequip/swap rules per slot |
| E4 🔒 | Save migration (slots, templates) + fixtures | every P0-4 fixture loads; displaced items preserved |
| E5 | Inventory screen (5 slots around hero, comparison card) | render tests; delta values match calculator |
| E6 | Speed rule, LAN profile, skill binding interim | movement test with capped speed; LAN harness |

## 9. Decisions needed

| ID | Question | Recommendation |
| --- | --- | --- |
| D1 | Approve the formula and starting table (§3–§4)? | Yes: tune numbers later in data |
| D2 | DEF: remove from equipment entirely (HP absorbs its role), or keep DEF as a small Tank-only secondary? | Remove from equipment; DEF stays on heroes/buildings/runes |
| D3 | Move-speed diminishing returns and cap (§4)? | Yes |
| D4 | Existing equipment items: re-map to the new lines by formula, or retire them? | Re-map (keeps players' items) |
| D5 | Shield/ring/amulet items after slots are removed: keep as sell/salvage, or convert into Back items? | Convert shields → Tank Back, rings/amulets → sell value |
| D6 | Order: do this before or after finishing P0-5 (UI kit) and P0-8 (save v6)? | Finish P0-5 first (the new inventory screen needs the kit); merge this with P0-8 so there is a single save migration |
