# HUD stats subscription lifecycle — 2026-11-27

SCOUT verified hud.gd setup replaces stats without detaching either callback; four assertions fail in stats-red.log (exit 1, no script errors). Existing bars show old source values after replacement. Inspected CharacterStats setters, PixelBar.set_values, Player HUD wiring, recent HUD/test history, Agent A current diff/handoff and all seven coordination records. Agent A equipment-detail stat cells and tests are disjoint; owner AGENTS.md/loop skill left intact.

BRAINSTORM: (1) Repair disconnect/connect/refresh in HUD.setup: uses existing Resource/signal/bar contract, constant work, preserves layout and current caller order. (2) Recreate HUD on source change: resets unrelated minimap/feed/hotbar state and requires scene ownership. (3) Poll CharacterStats every frame: extra work and leaves obsolete event subscriptions. Choose approach 1; alternatives only if HUD becomes immutable per-player or event model changes under a future architecture plan. Evidence proves internal Emberfield defect, no source game parity is inferred.

PLAN / HUMAN APPROVAL: Standing continuous gameplay maintenance authorization covers bounded subscription correctness with unchanged public signature/events/payload, layout, scene, art/stable IDs, save and LAN. Dedicated branch fix/th-logic-hud-stats-lifecycle from origin/develop@47d9ca00b. Exact files: sense/ui/hud/hud.gd (shared runtime, gameplay subscription only; recent history/handoff/diff inspected, no overlap), tests/inventory_transaction_tests.gd (Agent B regression), docs/reports/logic-hud-stats-lifecycle-20261127.md (Agent B report). No Agent A file edit or contract change. Buff wiring excluded.

Implement guarded detachment of old health/stamina callbacks, assign stats, idempotently connect current signals, synchronously refresh bars. Null source detaches and displays zero with minimum maximum 1 already enforced by PixelBar. Preserve same-source refresh and repair disconnected callbacks. No resource mutation or automatic heal. Rollback removes this repair and regressions, no migration.

Acceptance: new current/max values on both bars, old source inert, replacement updates live, old unrelated listeners preserved, same-source setup idempotent and repairs signals, null setup safe and clears both bars, null twice safe, reconnection works; real CharacterStats and PixelBar values, notification counts. Original four-failure probe goes green. TEST: headless editor import, InventoryTransaction, standalone Survival, Legacy1-7+Survival with separate XDG_DATA_HOME and timeouts; require exit 0/ALL PASSED/no script errors; git diff --check. No renderer/LAN/visual parity claim because display contract and drawing unchanged. REVIEW full final diff before commit/push/PR, explicit -R Thanh-xyz/Treasure-hunter-survival and scoped Thanh-xyz credentials, develop only. Verify integrated tree; rerun tests if content differs. MAIN excluded.

Risks: retained public stats reference can be assigned by unsupported callers without setup; not expanded here. Unknown live source swap UX remains unknown. COOK entry was authorized under standing approval.

## COOK

HUD.setup now detaches its own health/stamina listeners from a different old Resource, guarded-connects the new source, and refreshes current/max values synchronously. Null setup detaches and empties both bars using their existing minimum maximum 1. Same-source calls refresh and repair missing listeners. Other observers are preserved. Regression uses real CharacterStats and PixelBar objects, with bar notification counts. Original four-failure probe now exits0 with failures=0 (/tmp/th-logic-20261127/stats-green.log). No shared contract or Agent A file changed.

## TEST

Godot `4.6.stable.official.89cea1439`: `timeout 120 godot --headless --path . --editor --import --quit` exits 0. `timeout 150 godot --headless --path . tests/InventoryTransactionTests.tscn`, `tests/SurvivalTests.tscn`, and `tests/LegacySystemTests.tscn` each exit 0 and report ALL PASSED (Legacy phases 1–7 plus embedded Survival). Each scene uses its own `XDG_DATA_HOME` under `/tmp/th-logic-20261127`. No SCRIPT ERROR, Parse Error or Compile Error. Whitespace check passes.

Logs: `/tmp/th-logic-20261127/stats-import.log`, `stats-final-inventory.log`, `stats-survival.log`, `stats-legacy.log`, `stats-green.log`. Earlier `stats-inventory.log` failed two test-only expectations: PixelBar emits on both max-value clamping and current assignment. The regression now measures the unmodified PixelBar notification policy independently before comparing HUD refresh counts; final Inventory passes. Runtime code did not change after the passing import/Survival/Legacy runs. Earlier failure retained. Known negative-fixture and exit-resource warnings remain.

Not run: renderer, physical gestures, LAN or direct reference comparison. No drawing/layout/protocol changed; no visual parity claim.

## REVIEW

Full runtime/test/report diff checked against the three-file approved plan. No high/medium finding remains. HUD detaches only its own listeners, preserves unrelated listeners, repairs same-source connections and keeps Resource state immutable. Real objects verify old-source inactivity, replacement current/max values, current updates, null clearing/reconnect and original bar notification policy. No asset, art-owned file, scene, public method/signal/payload, stable ID, save or LAN contract change. Agent A's live equipment-detail diff remains disjoint. This is an in-session review, not an independent-agent review. PR-ready for develop under standing approval; main excluded.

## PR / INTEGRATION

Publish only the exact reviewed three-file change. PR and merge identifiers, base/tree comparison and final recovery point are recorded in Agent B shared status/handoff. Revalidate if the integration content differs from this tested tree.
