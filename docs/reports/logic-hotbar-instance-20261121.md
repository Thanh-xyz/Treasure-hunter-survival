# Hotbar equipment instance binding — 2026-11-21

## SCOUT

On `develop@b9ae3f526`, hotbar refresh and activation validated only `ItemData.id`.
Two materialized card-28 weapons can have that same ID and different exact stats.
Swapping their inventory positions left the hotbar bound to the old index: a Godot 4.6
probe selected damage `29.8` but emitted the inventory position of damage `49.0`.
The player uses that position for equipment activation, so it would equip the other
weapon. `/tmp/th-logic-loop-session/hotbar-red.log` records this failure (exit `1`).

Inspected hotbar/slot/player/inventory code, recent hotbar history, the seven coordination
records, Agent A's handoff and its active equipment-detail diff. Agent A files are disjoint.
No reference-game asset or visual behavior is inferred from this local logic reproduction.

## BRAINSTORM

Selected live Resource identity for nonstackable items, retaining catalog-ID matching for
stackable items. Inventory swap/sort retain Resource references, so this preserves the
existing assign-by-reference behavior and distinguishes even identical-stat instances.
Comparing serialized stats conflates distinct items; persistent UUIDs would require a save/
network migration. Neither is necessary for live bindings. Equip-swap replacement continues
through the existing explicit `update_slot_after_equip_swap()` callback.

## PLAN / HUMAN APPROVAL

Standing continuous logic approval covers the bounded repair. Dedicated branch:
`fix/th-logic-hotbar-instance-binding` from integrated `develop@b9ae3f526`. Exact files:
`sense/ui/hud/hotbar.gd` (private matching only), `tests/inventory_transaction_tests.gd`
(binding/activation regression), and this report. No public callback, event/payload, scene,
layout, asset, ID, save or LAN contract changes. Plan: `/tmp/th-logic-loop-session/hotbar/plan.md`.

Acceptance: preserve selected equipment through swap/sort, multiple same-ID bindings and
activation-time relocation; clear a removed instance instead of selecting another same-ID
item; preserve stackable relocation/quantity and explicit equip-swap handoff behavior.
Rollback is confined to the three files; `main` is excluded from integration.

## COOK

One private predicate now supplies consistent matching to both refresh passes, activation
validation and the reservation checks for other hotbar slots. Nonstackable items require
the same Resource; stackable items can still match their catalog ID. Presentation, balance
and the explicit equip-swap callback are untouched.

## TEST

The original reproduction now emits damage `29.8` at the inventory position of the selected
`29.8` weapon (exit `0`; `/tmp/th-logic-loop-session/hotbar-green.log`). Fresh final-code Godot 4.6 editor import, InventoryTransaction, standalone Survival,
Legacy phases 1–7 plus embedded Survival, and whitespace checks all pass (exit `0`).
Logs: `/tmp/th-logic-loop-session/hotbar-{import,inventory,survival,legacy}.log`.
Known negative-fixture/exit-resource warnings remain; no script/parse/compile errors.
Focused regression covers live same-ID swaps, two simultaneous bindings, missed-signal
activation repair, sorting, removal, stackable quantity/relocation and explicit equip-swap
replacement. Rendering/LAN were not run for this identity lookup change; no pixel parity
claim is made.

## REVIEW

Independent read-only review found no blocking findings in final runtime and regression
diff. All five matching sites use the same predicate; no visual/public contract change
or Agent A dependency. Exact three-file scope and `git diff --check` pass.

## PR / INTEGRATION

Target `develop` only; receipt will be recorded in Agent B shared status/handoff after
merge. No checks are claimed until actually observed.

Residual limitation: binding identity is in memory. Save hydration that replaces ItemData
resources can clear nonstackable bindings; no persistent hotbar identity or migration is
added. Identical references used in multiple inventory slots remain indistinguishable,
consistent with existing InventoryData storage.
