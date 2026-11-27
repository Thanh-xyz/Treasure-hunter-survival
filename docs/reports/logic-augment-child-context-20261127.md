# InventoryPanel augment child context — 2026-11-27

## SCOUT / BRAINSTORM

Real InventoryPanel._open_augment_panel followed by source replacement left its old child visible/alive; a real child apply command after one frame consumed and applied an augment in the old inventory. Probe child-red.log failed3 assertions, exit1. Parent source setup already dismisses selection/tooltip/detail, but omitted augment child. Opening waits a frame before position assignment, requiring lifetime validation if source replacement closes that child during the wait. Evidence /tmp/th-logic-continue-20261127/{child-probe.gd,ChildProbe.tscn,child-red.log}.

Select parent-owned invalidation using existing child null setup/close routes over silently retargeting old intent or a new dialog service. Inspected current parent/child setup-open-close code and histories, seven coordination records and Agent A active detail diff/handoff; disjoint. No reference visual behavior inferred.

## PLAN / HUMAN APPROVAL / COOK

Standing continuous gameplay context maintenance approval covers exact3 files: shared InventoryPanel runtime, owned InventoryTransaction async regression and this report. Dedicated fix/th-logic-augment-child-context from develop@f692e615c after PR162. Full plan /tmp/th-logic-continue-20261127/child-plan.md. On inventory replacement, existing child.setup(null,slot) synchronously disconnects/hides/clears its command source, then existing close handler emits panel_closed once and queues deletion. Same-source parent setup preserves valid child. Positioning after await returns when child is invalid/queued. No child runtime/scene, public method/event/payload, art/ID, save or LAN changes. Rollback3 files, no migration.

## TEST

Godot4.6.stable.official.89cea1439 headless editor import (timeout120), InventoryTransaction, standalone Survival and Legacy1–7+embedded Survival (timeout150, isolated XDG_DATA_HOME) all exit0/ALL PASSED, no script/parse/compile errors. Original probe now failures0, exit0. Whitespace passes. Evidence /tmp/th-logic-continue-20261127/child-{green,import,inventory,survival,legacy}.log.

Async real-scene regression verifies same-source child preserved, replacement clears immediately and emits close once, a forced action during queued deletion cannot mutate old inventory, child frees next frame, current source opens/applies exactly one augment, and source replacement during pending opening retires child without a stale positioning error. Renderer/physical input/LAN/source comparison not run for lifecycle-only repair; no visual fidelity claim. Expected negative fixtures/resource warnings remain.

## REVIEW / PR

Full runtime/test/report diff reviewed in-session; no high/medium finding. Exact3-file scope, existing synchronous null setup makes deferred deletion safe, await guard preserves normal positioning. No Agent A adaptation or shared API/event contract change. Independent-agent review not invoked. PR-ready for develop under standing approval; main excluded. Rapid repeated opens/name reservation remains a pre-existing separate candidate, not claimed fixed. Tested/integrated tree and PR IDs recorded in shared Agent B handoff.
