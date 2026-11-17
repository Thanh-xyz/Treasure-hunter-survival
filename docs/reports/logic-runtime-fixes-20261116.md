# Agent B runtime fixes — 2026-11-16

## Skill cooldowns — SCOUT

User renewed continuous work while BackSlot contract remains pending; continue independent gameplay bugs. Branch fix/th-logic-skill-cooldowns from develop@d5b7b6f86. Read coordination/status/handoffs, full SkillComponent, owner wiring, inventory augment mutations, legacy tests and recent history. Agent A equipment-detail-close feature is disjoint.

Verified code: Player connects every equipment_changed to rebuild_skills; apply_augment emits augments_changed and equipment_changed. SkillComponent clears its list and gives every rebuilt entry current_cooldown=0. Thus equipping unrelated armor or changing an augment resets a just-used skill. Duplicate same-ID entries can also show independent cooldown values. No source cooldown rule is invented: preserve the existing configured duration while repairing lifecycle resets.

## Skill cooldowns — BRAINSTORM

Choose per-skill-ID cooldown state owned by existing SkillComponent, ticking even while temporarily unequipped. Alternative preserve only entries still equipped fails rapid remove/re-equip. Global persistent service adds unnecessary save/network contracts. Existing available_skills remains presentation data; APIs/signals and configured costs/durations stay stable.

## Skill cooldowns — PLAN / HUMAN APPROVAL

Standing approval covers this isolated bug fix. Agent B files: sense/components/skill_component.gd, tests/inventory_transaction_tests.gd (regression), tests/legacy_system_tests.gd (replace direct display-field cooldown resets with elapsed-time simulation), this report. No UI/source art/scene/schema/transport changes. Reproduce with focused suite before fix; add private skill-ID timer map; activation commits one shared cooldown before signal; rebuild reads remaining timer; tick inactive timers without publishing hidden skills; emit existing cooldown signal once per active skill ID. Test unrelated rebuild, remove/re-equip with elapsed time, duplicate IDs, no repeated stamina charge and exact expiry. Run Godot 4.6 import, Inventory/Legacy/Survival; review and commit/PR to develop. Rollback private state and regression. MAIN remains separate Cinderwild history.

## Skill cooldowns — COOK / TEST entry

New Inventory regression reproduced failures before fix (exit 1), including unrelated rebuild reset, re-equip bypass, stale duplicate display and repeated stamina/activation. Evidence /tmp/th-skill-cooldowns/repro.log. Implemented private timer map; no method/signal/ID changed. Legacy fixtures now simulate configured cooldown elapsed time rather than mutating HUD-facing state. Full TEST next.

## Skill cooldowns — TEST / REVIEW

Initial implementation had an indentation parse error; import exited 0 despite it and Survival's harness printed ALL PASSED despite script errors. Those runs are invalid, retained as *-initial.log. Corrected indentation, terminated only the two inspected stuck test processes, and reran affected suites. Focused Inventory now exits 0 with ALL PASSED and no SCRIPT ERROR; full Legacy and Survival rerun follows. Review must check logs for script errors, not exit code alone.

## Skill cooldowns — TEST closeout / REVIEW

Corrected import plus InventoryTransaction, LegacySystem and Survival runners all exit 0, contain no SCRIPT ERROR/Parse Error, and report ALL PASSED. Logs: /tmp/th-skill-cooldowns/{import,inventory,legacy,survival}.log. Regression covers unrelated equipment rebuild, unequip/re-equip elapsed timers, duplicate ID bindings, stamina and activation counts. No LAN run: no transport or authority contract changed.

Review: diff is limited to SkillComponent cooldown state, existing legacy fixtures and this report. No high/medium issue, visual change, stable ID or Agent A overlap. Existing test harness's historical warnings remain; invalid initial runs with parse errors are retained separately and not counted as validation.
