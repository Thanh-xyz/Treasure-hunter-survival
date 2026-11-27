# Repeated augment opening ownership — 2026-11-27

## SCOUT / BRAINSTORM

Opening the actual augment child twice in one frame left the retiring child holding canonical name AugmentPanel until queued deletion. The replacement was auto-renamed, became unreachable through the parent's normal lookup after deletion, and escaped later source-change retirement. ReopenProbe failed3 assertions, exit1; evidence /tmp/th-logic-continue-20261127/{reopen-probe.gd,ReopenProbe.tscn,reopen-red.log}. Existing PR163 lifetime guard prevented invalid positioning but could not preserve name ownership.

Select immediate parent detachment through one private retirement helper over a second reference/ID registry or a frame-delayed opener. Read parent-child name/setup/null/close logic and histories, all7 coordination records and Agent A active diff/handoff; disjoint. No reference visual behavior inferred.

## PLAN / HUMAN APPROVAL / COOK

Standing gameplay context/lifecycle approval covers exact3 files: shared InventoryPanel private retirement/opener logic, owned InventoryTransaction async regression and this report. Dedicated fix/th-logic-augment-reopen from develop@a393550a0. Plan /tmp/th-logic-continue-20261127/reopen-plan.md. Helper clears child source using existing setup(null,slot), removes child from parent synchronously to release its canonical name, then uses existing close handler/event and queued deletion. Used both on source replacement and repeated opening; existing awaited positioning guard retained. No child runtime/scene, public method/event/payload, art/ID, save/LAN change. Rollback3 files, no migration.

## TEST

Godot4.6.stable.official.89cea1439 headless import (timeout120), InventoryTransaction, standalone Survival, Legacy1–7+embedded Survival (timeout150, independent XDG_DATA_HOME) all exit0/ALL PASSED and contain no script/parse/compile errors. Probe now failures0, exit0. Whitespace passes. Logs /tmp/th-logic-continue-20261127/reopen-{green,import,inventory,survival,legacy}.log.

Async real-scene regression verifies exactly one canonical replacement immediately/after frames, retired source cleared and detached/inert, one close event, old node deletion, current replacement applies exactly one augment and later source change retires it. Previous parent-child and AugmentPanel lifecycle cases also pass in final suite. Physical input/renderer/LAN/source comparison not run for ownership repair; no drawing or visual fidelity claim. Expected negative fixtures/resource warnings remain.

## REVIEW / PR

Complete runtime/test/report diff reviewed in-session; no high/medium finding. Source clearing precedes detachment/deferred deletion; only one parented canonical child remains, preserving future lifecycle lookup and normal async positioning. Exact3-file scope, no Agent A adaptation or public contract expansion. No independent-agent review invoked. PR-ready for develop under standing approval; main excluded. Final PR/merge/tested-tree receipt in shared Agent B handoff.
