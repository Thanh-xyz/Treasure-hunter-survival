# InventoryPanel source lifecycle — 2026-11-27

## SCOUT

Real InventoryPanel scene probe failed nine assertions: old gold999 overwrote current20, old inventory/equipment/gold listeners and stats closure remained, repeated setup duplicated stats callbacks, optional null stats retained callbacks, and source replacement left tooltip/equipment detail open. Repeated setup also logged duplicate-connection engine errors. Evidence /tmp/th-logic-continue-20261127/{panel-probe.gd,PanelProbe.tscn,panel-red.log}, exit1. Inspected controller/scene/detail setup-close API, Resource signals, tests/history, all seven coordination records and Agent A equipment-detail diff/handoff; disjoint. No reference visual behavior is inferred.

## BRAINSTORM / PLAN / HUMAN APPROVAL

Select existing subscription-owner repair over full panel recreation (caller/scene/state changes) or polling/event filtering (retains old closures; gold lacks source identity). Standing continuous gameplay maintenance approval covers exact three files: sense/ui/inventory/inventory_panel.gd (shared runtime controller only), tests/inventory_transaction_tests.gd and this owned report. Dedicated fix/th-logic-inventory-panel-lifecycle from develop@efc0509c0. Detailed plan /tmp/th-logic-continue-20261127/panel-plan.md. No Agent A file, scene/drawing, public method/signal/payload, stable ID, asset, save or LAN contract change. Null inventory remains outside required-data contract; optional null stats and same-source context retained. Pending external sale/augment dialog context is a separate audit.

## COOK

Setup detaches its listeners from differing old sources, guarded-connects current sources, and uses one named private health listener. It refreshes current labels/slots and repairs same-source missing callbacks. On inventory replacement it clears selection and closes stale tooltip/detail via existing public close_panel. Same-source setup preserves valid detail/tooltip/selection. Only its own listeners detach; Resources are not mutated. Rollback removes three-file fix without migration.

## TEST

Godot4.6.stable.official.89cea1439 headless editor import (timeout120) and InventoryTransaction, standalone Survival, Legacy1–7+embedded Survival (timeout150, independent XDG_DATA_HOME) all exit0 and gameplay suites report ALL PASSED. No script/parse/compile errors. Direct reproduction now failures=0, exit0, no duplicate-connection errors. git diff --check passes. Logs /tmp/th-logic-continue-20261127/panel-{import,inventory,survival,legacy,green}.log.

Real-panel regression verifies current labels/slots/equipment, old-source detachment/inactivity, unrelated listeners, current updates, same-source uniqueness/repair, optional null-stats fallback and replacement-only transient dismissal. Existing RenderEquipmentDetail actions/render ran before and after with xvfb-run Godot gl_compatibility at360x800; both exit0. Isolated /tmp harness changed only output paths. PNGs panel-baseline.png/panel-after.png are pixel-identical, SHA256 e95e68b88b535c8a6212736b1e53742eb9c37e9c4832154b0b5b2320d4909cb4; zero changed pixels. Evidence panel-render-{before,after}.log and panel-visual.json. This is a regression comparison, not source parity. Physical input/LAN not run. Expected negative fixtures/HUD fallback/resource warnings remain.

## REVIEW / PR

Complete runtime/test/report diff reviewed in-session, no high/medium finding. Three-file scope matches plan; existing callers and detail close API compatible; Agent A presentation/test edits untouched. No independent-agent review was invoked. Remaining limits: callers bypassing setup by assigning public fields, unsupported null inventory, existing hidden detail private listener lifetime and external pending dialogs. PR-ready for develop under standing approval, MAIN excluded. PR/merge/tree receipt in Agent B shared handoff; rerun affected gates if integration tree differs.
