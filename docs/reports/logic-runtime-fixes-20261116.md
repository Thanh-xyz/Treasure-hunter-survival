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

## Health bonus removal — SCOUT / BRAINSTORM

2026-11-17: user resumed continuous work. CharacterStats setters clamp HP, but apply/clear equipment and buff bonuses only emit health_changed after max-health changes. Removing +HP equipment or an expired buff can therefore leave current_health above max_health. Owner Player already calls these methods on equipment/buff events. Existing tests check bonus values, not HP bounds. Inspected AGENTS/copilot, current stats/owner methods, relevant tests, coordination files and recent history; Agent A equipment-close scope is disjoint.

Recommendation: reconcile current_health through its existing clamping setter only when it exceeds the new maximum, otherwise preserve the existing health_changed notification. Alternative percentage-based rescaling or auto-heal on max increase invents new balance behavior. Central pure bound reconciliation preserves current absolute HP and existing schema/signals. No source-game parity claim beyond the already-defined HP invariant.

## Health bonus removal — PLAN / HUMAN APPROVAL

Standing continuous-work approval covers this isolated gameplay correction. Dedicated fix/th-logic-health-bonus-removal branch from integrated develop. Agent B owns CharacterStats and inventory regression tests/report. Add private helper used by four equipment/buff apply/clear methods; clamp excess HP, never heal on cap increase, never re-emit died for already-dead unchanged HP, emit health_changed exactly once per update with final valid values. Tests exercise authoritative equip/unequip, timed-buff expiry, explicit clear, wounded/dead state and notification counts. No new node/UI/layout/asset/ID/save/LAN interface. Run focused regression before/after, import, Inventory/Legacy/Survival, then review, commit, PR to develop. Rollback helper/call sites/tests only.

## Health bonus removal — COOK / TEST entry

Regression run failed before fix (exit 1, /tmp/th-health-bonus/repro.log): current HP remained above cap on unequip, equipment clear, buff expiry and buff clear. Added four call sites to one private reconciliation helper; existing setter clamps excess and emits once, unchanged HP emits directly to avoid repeated died on already-dead state. No auto-heal on cap increase. Integrated base includes Agent A PR139 close presentation and skill PR140, both preserved. Full combined-tree suites follow.

## Health bonus removal — TEST / REVIEW

Godot 4.6 import, InventoryTransaction, Legacy phases1-7 plus embedded Survival/save and standalone Survival exit 0, report ALL PASSED and contain no script/parse errors. Regression verifies all four bonus updates, real timed expiry, equip/unequip, wounded/dead HP and exact one-notification behavior. Known negative-save, missing-HUD fallback and exit-resource warnings remain. Two-process LAN player-vitals regression running because HP feeds its profile; no payload/schema changed.

Review of full three-file diff: one private helper/four call sites, focused regression and owned report. No high/medium finding, art/UI edit, unrelated balance/stat change or ownership conflict. No live reference comparison or source maximum-HP rescaling semantics claimed; this repairs the existing absolute-HP invariant.

LAN player-vitals host/client both exit 0; logs/JSON /tmp/th-health-bonus/lan-*. No script errors in either process. Full test/review gates complete before commit. Skill #140 integrated as 90c9203ac; combined base also includes disjoint Agent A #139, so exact equality to the pre-art skill tree was not claimed. Combined suites validate both.
