# Sale confirmation context — 2026-11-27

## SCOUT / BRAINSTORM

A real InventoryPanel plus actual ConfirmDialog Yes flow reproduced two failures: a pending confirmation sold from a replacement inventory containing the same ID, and a same-ID swap sold the wrong enhancement-level instance. Existing callback captured catalog item/index, then used whichever inventory the panel held. ConfirmDialog emits confirmed before invoking its saved callback. Probe /tmp/th-logic-continue-20261127/{sale-probe.gd,SaleProbe.tscn,sale-red.log} exits1 with failures2, no script errors.

Choose closure source/instance validation over a new transaction token API or locking inventory during dialogs. Existing InventoryData.sell_item_at remains authoritative for one-item catalog-price atomic sale. Live Resource identity suffices without persisted IDs. Inspected controller/dialog/transaction/test history, all7 coordination records and Agent A active detail diff/handoff; disjoint. No source visual behavior inferred.

## PLAN / HUMAN APPROVAL / COOK

Standing continuous gameplay correctness approval covers preventing unconfirmed deferred sales. Dedicated fix/th-logic-sale-confirmation-context from develop@a7ad40faa. Exact3 files: shared inventory_panel.gd request closure, owned inventory_transaction_tests.gd and this report. Plan /tmp/th-logic-continue-20261127/sale-plan.md. No ConfirmDialog/InventoryData API, prompt copy/quantity policy, scene/art, asset/ID, save/LAN or disabled equipped-Sell changes. Capture InventoryData and actual slot ItemData; reject mismatched initial item/index, then compare current source/slot identity at callback execution before existing transaction. Rollback3 files, no migration.

## TEST

Godot4.6.stable.official.89cea1439 editor import (`timeout 120 godot --headless --path . --editor --import --quit`), InventoryTransaction, standalone Survival, Legacy1–7+embedded Survival (`timeout 150 godot --headless --path . tests/<scene>.tscn`, isolated XDG_DATA_HOME) all exit0/ALL PASSED/no script/parse/compile errors. Direct probe now failures0, exit0. git diff --check passes. Evidence /tmp/th-logic-continue-20261127/sale-{green,import,inventory,survival,legacy}.log.

Regression drives real modal Yes/No behavior: source replacement, same-ID distinct instance swap, removed/moved/different-ID slots, stale initial request, cancellation and source replacement by a confirmed signal listener all reject with no transaction events. Matching instance sells exactly once at catalog price even with spoofed instance price; both notifications see final item/gold state. Renderer/physical input/LAN/reference comparison not run for closure admission; no presentation change or visual parity claim. Existing negative fixtures/resource warnings remain.

## REVIEW / PR

Full runtime/test/report diff reviewed in-session, no high/medium issue. Checks occur after modal confirmed listeners, immediately before synchronous transaction; Resources/IDs and atomic sale policy remain intact. Exact3-file scope, no Agent A adaptation or contract expansion. Rebinding away then back to the exact same source/instance retains original live intent; fungible stack quantity changes remain allowed. No independent-agent review invoked. PR-ready for develop under standing approval; MAIN excluded. PR/merge/tested-tree evidence in Agent B shared handoff.
