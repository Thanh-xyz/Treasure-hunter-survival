# Crafting inventory binding — 2026-11-21

## SCOUT

Resumed the existing two-file fix on `fix/th-logic-crafting-inventory-binding`,
based on `develop@08f06f7db`. `CraftingPanel.set_player_inventory()` subscribed to
replacement inventories without disconnecting the previous resource. Old inventory
changes could therefore refresh a panel bound to a different inventory. Inspected
recent crafting history, the seven coordination records and Agent A's handoff/diff;
its equipment-detail stat-cell changes are disjoint and untouched.

## BRAINSTORM / PLAN / HUMAN APPROVAL

Select setter-managed signal rebinding: disconnect only a different previous resource,
then connect and refresh the current resource. Connecting repeatedly without disconnecting
retains stale subscriptions; recreating the panel would change its lifecycle unnecessarily.
The user's standing continuous logic approval covers this bounded repair. Exact files:
`sense/ui/crafting/crafting_panel.gd`, `tests/inventory_transaction_tests.gd`, and this
Agent B report. No scene, visual, asset, gameplay ID, save, or LAN contract changes.
Acceptance: initial binding, replacement, same-resource refresh/connection repair and null
clearing preserve exactly one subscription to the active inventory.

## COOK

The setter now disconnects its refresh callback from a different previous inventory.
The existing connect/refresh path still runs for same-resource assignments, including
repairing an externally disconnected signal. Regression coverage checks initial binding,
replacement, repeated assignment, missing-connection repair and null clearing.

## TEST

Earlier continuation references to `/tmp/th-crafting-binding` are unavailable in this
session and are not counted as verified evidence. Fresh final-code validation used
Godot `4.6.stable.official.89cea1439` with isolated `XDG_DATA_HOME` directories:

- `godot --headless --path . --editor --import --quit`: exit `0`.
- `godot --headless --path . tests/InventoryTransactionTests.tscn`: exit `0`, `ALL PASSED`.
- `godot --headless --path . tests/SurvivalTests.tscn`: exit `0`, `ALL PASSED`.
- `godot --headless --path . tests/LegacySystemTests.tscn`: exit `0`; Legacy phases 1–7
  and embedded Survival both report `ALL PASSED`.
- `git diff --check`: exit `0`.

Logs: `/tmp/th-logic-loop-session/binding-{import,inventory,survival,legacy}.log`.
No script, parse, or compile errors. Expected unknown-shop-item/corrupt-save fixture
errors and existing exit-resource warnings remain. Rendering/LAN were not run for this
signal lifecycle fix; no visual parity claim. Coordination inspections are recorded in
`/tmp/th-logic-loop-session/stages.jsonl`.

## REVIEW

Independent read-only review found no high/medium issue. It suggested preserving the
old setter's same-resource connection repair; the guard was simplified and a regression
added before the fresh tests. Follow-up review passes with no blocking findings. Exact
three-file scope remains intact; Agent A requires no adaptation.

## PR / INTEGRATION

PR target is `develop`; the separate original-content `main` is excluded. Integration
receipt will be recorded in Agent B's shared status/handoff after merge.
