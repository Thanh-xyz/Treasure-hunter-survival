# AugmentPanel source lifecycle — 2026-11-27

## SCOUT / BRAINSTORM

Real AugmentPanel probe failed3 checks: retained old inventory subscription, an old-source add_item reopened the hidden current panel, and actual upgrade_equipment left the panel holding an obsolete equipment Resource because upgrade emits equipment_changed without inventory_changed. Final simplified probe/log: /tmp/th-logic-continue-20261127/{augment-probe.gd,AugmentProbe.tscn,augment-final-red.log}, exit1, no script errors. An earlier exploratory log with unnecessary shield/swap fixtures is retained separately and is not the acceptance reproduction.

Choose existing inventory/equipment signal ownership over adding inventory_changed to every equipment transaction or polling/recreation. Private callback filters target slot. Inspected scene/runtime, InventoryData transactions and legacy augment event tests/history, seven coordination files and Agent A active equipment detail diff/handoff; disjoint. No reference visual behavior inferred.

## PLAN / HUMAN APPROVAL / COOK

Standing gameplay subscription/state approval covers exact3 files: shared sense/ui/augment/augment_panel.gd runtime, owned tests/inventory_transaction_tests.gd and this report. Dedicated fix/th-logic-augment-panel-lifecycle from develop@ed9264b10; full plan /tmp/th-logic-continue-20261127/augment-plan.md. Setup detaches differing old inventory/equipment listeners, guarded-connects the current source, and delegates to existing null-safe refresh. A private target-slot equipment callback refreshes actual current equipment. Same-source connections repair without duplication; null detaches/hides/clears then can reconnect. Existing apply/remove transaction/event behavior stays intact. No public method/event/payload, scene/drawing/art/ID, save/LAN or parent-child lifetime change. Rollback3 files, no migration.

## TEST

Godot4.6.stable.official.89cea1439 editor import (timeout120), InventoryTransaction, standalone Survival, Legacy1–7+embedded Survival (timeout150 with independent XDG_DATA_HOME) all exit0/ALL PASSED, no script/parse/compile errors. Original final reproduction now failures0, exit0. git diff --check passes. Evidence /tmp/th-logic-continue-20261127/augment-{green,import,inventory,survival,legacy}.log.

Regression instantiates actual panel and catalog Resources: old-source detachment/inactivity, unrelated listeners, same-source uniqueness/repair, actual equipment-only upgrade Resource/stats refresh, unrelated equipment slot filtering, current inventory updates, real apply/remove commands, null clearing/reconnect. Existing legacy suite separately asserts stable augment-applied/removed event IDs/counts. Physical input, renderer, LAN and source comparison not run for subscription-only repair; no visual fidelity claim. Expected negative fixtures/resource warnings remain.

## REVIEW / PR

Full runtime/test/report diff reviewed in-session, no high/medium finding. Existing slots/signals/transactions preserved and three-file scope matches approval; Agent A needs no adaptation. Parent InventoryPanel retaining an already-open child across source replacement remains a separate candidate; no fix claimed here. No independent-agent review invoked. PR-ready for develop under standing approval; main excluded. Integration receipt in shared handoff, rerun affected gates if combined tree differs.
