# Hotbar source lifecycle — 2026-11-21

## SCOUT

`Hotbar.setup()` replaced its source fields without disconnecting old inventory/skill
signals, refreshing item bindings or clearing null skill sources. A Godot 4.6 reproduction
with real SkillComponents and slots failed twelve assertions: replacement potion quantity
remained `5` instead of `2`, an old whirlwind timer changed a ready replacement's display
to `0.75`, and null setup retained items, skills, cooldown and old subscriptions.

Evidence: `/tmp/th-logic-loop-session/hotbar-setup/{repro.gd,Repro.tscn,repro.log,scout-plan.md}`.
The scene ran off-tree UI logic and real component timers, not physical gestures or rendering.
Additional code inspection found HUD's independent forwarding connections to the same
skill sources. Both routes must detach for old components to become inert. Inspected HUD/
hotbar/player/component history and code, tests, seven coordination records, Agent A handoff
and active diff; its equipment-detail work is disjoint and untouched.

## BRAINSTORM

Select lifecycle repair at each existing subscription owner. Disconnect previous sources,
connect current sources idempotently, and refresh or clear state synchronously. Recreating
the bar would discard assignments and change scene lifecycle; filtering events would
require source identity in existing signal payloads. Keep the current HUD forwarding route
and Player's existing `connect_skill_component()` then `setup_hotbar()` call sequence.

## PLAN / HUMAN APPROVAL

Standing continuous logic approval covers this bounded repair of existing wiring. Branch
`fix/th-logic-hotbar-source-lifecycle` starts from integrated `develop@a20d20327`. Exact
files: `sense/ui/hud/hotbar.gd` (direct source lifecycle and authoritative cooldown refresh),
`sense/ui/hud/hud.gd` (existing forwarding lifecycle),
`tests/inventory_transaction_tests.gd` (direct and HUD-path regressions), and this report.
No architecture, draw/layout, public signature, event/payload, asset/ID, save or LAN
contract changes. Approved plan: `/tmp/th-logic-loop-session/hotbar-setup/approved-plan.md`.

Acceptance: old inventory/skill signals detach; replacement quantities refresh; ready/new
cooldowns reflect current source; same-source setup repairs connections without duplicates;
null clears bindings; detached timers are inert; current timers still work; replacing an
already-freed component is safe. Verify both direct and HUD forwarding routes. No hotbar
persistence or HUD buff/stat lifecycle change is included. Rollback needs no migration.

## COOK

Hotbar disconnects a different previous inventory and valid old SkillComponent before
replacement, guarded-connects the current sources, then refreshes item and skill state.
Null item refresh clears slots; skill refresh already clears null sources and now restores
current cooldown values immediately. HUD tracks its forwarding source privately and detaches
its previous callbacks before guarded reconnection. Freed old Node references are checked
with `is_instance_valid()` before access. Existing callbacks and slot identity rules remain.

## TEST

Original direct reproduction now passes all twelve assertions (exit `0`;
`/tmp/th-logic-loop-session/hotbar-setup-green.log`). Replacement quantity is `2`, old
cooldown ticks leave the ready replacement at `0`, and null clears item/skill/cooldown.
Fresh final-code Godot `4.6.stable.official.89cea1439` headless editor import,
InventoryTransaction, standalone Survival, Legacy phases 1–7 plus embedded Survival,
and whitespace checks all pass (exit `0`). Logs:
`/tmp/th-logic-loop-session/hotbar-setup-{import,inventory,survival,legacy}.log`.
Known negative-fixture/exit-resource warnings remain; no script/parse/compile errors.

Regression uses real components/timers through direct and HUD forwarding paths, checks
quantity refresh and nonstackable identity clearing, same-source repair/idempotence,
null clearing, detached-source inactivity, current-source updates and freed-source
replacement. Shared whirlwind on weapon/Q and armor/E is verified immediately after
setup, timer ticks and skill-list rebuild. Rendering, physical gestures and LAN were
not run for subscription/state repair; no visual parity claim.

## REVIEW

Independent review caught an existing first-match break in cooldown updates: the same
skill bound to two inputs only updated its first display. Removing the break updates
all matching slots; the shared-skill regression proves both restoration and live ticks.
This is within the planned authoritative cooldown scope. Follow-up review of final runtime,
tests and worker evidence found no blocking findings. Exact four-file scope is intact;
no Agent A adaptation or contract expansion.

## PR / INTEGRATION

Target `develop` only. Integration receipt will be saved in Agent B shared status/handoff;
no `main` merge is authorized by this feature. HUD buff/stat subscriptions and persistent
hotbar identity remain independent future scopes.
