# Equipment drag destination — 2026-11-21

## SCOUT

The inventory-slot UI already validates a drop and emits its actual equipment slot.
`InventoryPanel._on_inventory_to_equipment_dropped(from_index, to_slot_type)` ignored
that destination and called automatic `InventoryData.equip_item(from_index)`.
Dragging a native `silver_ring` onto `accessory_2` therefore equipped `accessory_1`
when both slots were empty; when both were occupied, it replaced the unrelated first
slot and returned the wrong displaced item to the source inventory position.

A Godot 4.6 controller/transaction reproduction using native catalog accessories failed
seven assertions, including destination signals. Evidence:
`/tmp/th-logic-loop-session/accessory/{repro.gd,Repro.tscn,repro.log,scout-plan.md}`.
No script/parse errors. This exercises the real callback and inventory mutation, not
physical mouse gestures. Reviewed inventory/drop code, recent histories, tests, the seven
coordination records, Agent A handoff/diff; its equipment-detail work is disjoint.

## BRAINSTORM

Select an optional target on the existing equip transaction, forwarded from the existing
drop callback. This fixes both empty and occupied destinations with one final-state
notification. A separate public method is unnecessary. Automatic equip followed by slot
swap exposes transient wrong-slot state to quest/stats listeners and was rejected.

## PLAN / HUMAN APPROVAL

Standing continuous gameplay approval covers repairing the established drop destination
behavior. The optional parameter is inside Agent B-owned gameplay; one-argument callers
retain automatic slot selection, and no mandatory consumer or shared art/scene/save/LAN
contract expands. Signals/payloads, seven slot IDs and all public UI callbacks stay stable.
Branch `fix/th-logic-equipment-drop-target` starts from integrated `develop@d60ba40c2`.

Exact files: `sense/ui/inventory/inventory_data.gd` (target validation and transaction),
`sense/ui/inventory/inventory_panel.gd` (existing routing),
`tests/inventory_transaction_tests.gd` (gameplay regression), and this Agent B report.
No layout, asset, balance, save or network fields change. Acceptance: both accessory
destinations empty/occupied, exact displaced/source identity, unrelated slot conservation,
final-state single notifications, invalid targets rejected and default callers preserved.
Rollback is confined to this feature; PR target is `develop`, separate `main` excluded.

## COOK

`equip_item(index, target_slot="")` resolves the existing automatic policy when target
is omitted, otherwise validates the explicit target before any mutation. It commits only
the chosen equipment slot and original inventory index, preserving exact item instances,
then emits the existing equipment/inventory notifications. The existing drop handler now
forwards its received destination; right-click/hotbar callers retain automatic behavior.

## TEST

Original external reproduction now passes all seven assertions (exit `0`): empty and
occupied drops reach `accessory_2`, first slot remains unchanged, displaced second-slot
item returns to the source index, and notification names the correct destination.
Log: `/tmp/th-logic-loop-session/accessory-green.log`.
Godot `4.6.stable.official.89cea1439` headless import, standalone Survival, Legacy
phases 1–7 plus embedded Survival pass (exit `0`). Initial Inventory regression run
found a fixture-only counter error: adding the control weapon after attaching signal
observers incremented the count before equip. Resetting counters after fixture setup
corrected the test; final root Inventory run passes (exit `0`, `ALL PASSED`).

Logs: `/tmp/th-logic-loop-session/accessory-{import,survival,legacy,final-inventory}.log`.
Earlier failing inventory logs are retained. Regression covers each accessory target
across all four occupancy combinations, identity preservation and final-state signals,
unknown/incompatible-target rollback, explicit weapon target and default callers.
`git diff --check` passes. Known negative-fixture/exit-resource warnings remain; no
script/parse/compile errors. Rendering, physical mouse gestures and LAN were not run;
no visual or protocol parity claim.

## REVIEW

Independent read-only review found no blocking findings in final runtime/tests; it caught
the fixture counter before PR. Optional targeting preserves automatic policy, exact
source/displaced items and notification ordering. Final four-file scope matches plan;
no Agent A changes or adaptation. Target `develop`; integration receipt will be recorded
in Agent B shared status/handoff. Separate `main` remains excluded.
