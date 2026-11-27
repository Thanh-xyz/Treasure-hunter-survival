# HUD buff lifecycle — 2026-11-27

## SCOUT

A real BuffComponent/Control reproduction failed three checks: an old source still changed current HUD icons, its applied/expired listeners remained connected, and expiry of vitality_tonic_t1 hid the heal icon while vitality_tonic_t2 was still active. The source appends before buff_applied, removes before buff_expired, and clears its array before clear-all expiry events. HUD had no retained source or binding synchronization.

Evidence: /tmp/th-logic-20261127/{buff-probe.gd,BuffProbe.tscn,buff-red.log}; exit 1 without script errors. Inspected HUD/BuffComponent/Player/catalog, recent shared HUD/test history, all seven coordination files and Agent A live equipment-detail handoff/diff. No overlap or dependency. Existing mapping is speed / vitality-or-health / defense -> speed/heal/shield, in that priority. No reference icon mapping or source visual parity is inferred.

## BRAINSTORM

Choose retained current source plus a snapshot of its active_buffs to derive the three existing flags on binding and notifications. Event counters would miss already-active state and need reset/recovery bookkeeping; per-frame polling adds redundant work. Current arrays are small and the source already exposes authoritative state before each existing notification. No new icon family or generalized status architecture is needed.

## PLAN / HUMAN APPROVAL

Standing continuous gameplay-state maintenance approval covers current-source subscription/state repair. Branch fix/th-logic-hud-buff-lifecycle from develop@0e52be734. Exact files: sense/ui/hud/hud.gd (shared runtime lifecycle/state only, history and Agent A handoff/diff read), tests/inventory_transaction_tests.gd (owned regression), this owned report. No scene, drawing/style/layout, asset/stable ID, public method/signal/payload, stat/item formula, save or LAN contract change. Existing mapping/priority, other status icons/manual setter methods and new-defense info-feed behavior are retained. Full plan /tmp/th-logic-20261127/buff-plan.md.

Retain a private BuffComponent, detach the differing valid old source, guarded-connect the existing applied/expired listeners, and refresh on binding/null/application/expiry from current active_buffs. Preserve same-source repair and handle freed-old source. Null clears only the three buff-managed flags. Do not mutate buffs or emit new effects/events. Rollback removes repair/tests/report, no migration. MAIN excluded.

## COOK

HUD stores _buff_component, detaches only its callbacks, repairs/idempotently connects and synchronizes managed icons immediately. Applied and expired events refresh from the full active set, so one tier expiring cannot hide another. Feed hiding remains limited to new defense applications under the existing mapping priority; binding/expiry does not alter feed state. Original reproduction now exits 0, failures=0 (/tmp/th-logic-20261127/buff-green.log).

## TEST

Godot 4.6.stable.official.89cea1439:

- `timeout 120 godot --headless --path . --editor --import --quit`: exit 0.
- `timeout 150 godot --headless --path . tests/InventoryTransactionTests.tscn`: exit 0, ALL PASSED.
- Same command for `tests/SurvivalTests.tscn`: exit 0, ALL PASSED.
- Same command for `tests/LegacySystemTests.tscn`: exit 0, Legacy1–7 and embedded Survival ALL PASSED.
- `git diff --check`: exit 0.

Each suite has an independent XDG_DATA_HOME under /tmp/th-logic-20261127. Logs buff-{import,inventory,survival,legacy}.log contain no SCRIPT ERROR, Parse Error or Compile Error. Existing negative-fixture/HUD fallback and exit-resource warnings remain.

Regression uses real BuffComponents, catalog item copies and Controls off-tree. It verifies active replacement, old-source inactivity, same-source repair/idempotence, null clear/reconnect, freed-old replacement, both tiers for all three mapped families, expiry via controlled _process ticks, duration refresh, last removal/clear-all, unrelated status flags and feed behavior. Not run: renderer, physical input, LAN or reference comparison. This validates state/signal correctness, not visual fidelity.

## REVIEW

Full runtime/test/report diff reviewed in-session. No high/medium finding remains. All three planned files are in scope; source listeners are detached individually, state derives from the current source after mutation, mapping/priority and existing feed side effect remain compatible. No Agent A adaptation, asset/schema or public event/API changes. Off-tree controls and manual timer ticks are explicit validation limits. Independent-agent review was not invoked. PR-ready for develop under standing approval; main excluded.

## PR / INTEGRATION

Exact reviewed three-file change only. Final PR/merge IDs and tested/integrated tree comparison are recorded in Agent B shared status/handoff. Revalidate if integration contents differ.
