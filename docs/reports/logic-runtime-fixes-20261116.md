# Agent B runtime fixes — 2026-11-16

## Skill cooldowns — SCOUT

User renewed continuous work while BackSlot contract remains pending; continue independent gameplay bugs. Branch fix/th-logic-skill-cooldowns from develop@d5b7b6f86. Read coordination/status/handoffs, full SkillComponent, owner wiring, inventory augment mutations, legacy tests and recent history. Agent A equipment-detail-close feature is disjoint.

Verified code: Player connects every equipment_changed to rebuild_skills; apply_augment emits augments_changed and equipment_changed. SkillComponent clears its list and gives every rebuilt entry current_cooldown=0. Thus equipping unrelated armor or changing an augment resets a just-used skill. Duplicate same-ID entries can also show independent cooldown values. No source cooldown rule is invented: preserve the existing configured duration while repairing lifecycle resets.

## Skill cooldowns — BRAINSTORM

Choose per-skill-ID cooldown state owned by existing SkillComponent, ticking even while temporarily unequipped. Alternative preserve only entries still equipped fails rapid remove/re-equip. Global persistent service adds unnecessary save/network contracts. Existing available_skills remains presentation data; APIs/signals and configured costs/durations stay stable.

## Skill cooldowns — PLAN / HUMAN APPROVAL

Standing approval covers this isolated bug fix. Agent B files: sense/components/skill_component.gd, tests/inventory_transaction_tests.gd (regression), tests/legacy_system_tests.gd (replace direct display-field cooldown resets with elapsed-time simulation), this report. No UI/source art/scene/schema/transport changes. Reproduce with focused suite before fix; add private skill-ID timer map; activation commits one shared cooldown before signal; rebuild reads remaining timer; tick inactive timers without publishing hidden skills; emit existing cooldown signal once per active skill ID. Test unrelated rebuild, remove/re-equip with elapsed time, duplicate IDs, no repeated stamina charge and exact expiry. Run Godot 4.6 import, Inventory/Legacy/Survival; review and commit/PR to develop. Rollback private state and regression. MAIN remains separate Cinderwild history.

## Skill cooldowns — COOK / TEST entry

New Inventory regression reproduced failures before fix (exit 1), including unrelated rebuild reset, re-equip bypass, stale duplicate display and repeated stamina/activation. Evidence /tmp/th-skill-cooldowns/repro.log. Implemented private timer map; no method/signal/ID changed. Legacy fixtures now simulate configured cooldown elapsed time rather than mutating HUD-facing state. Full TEST next.

## Skill cooldowns — TEST / REVIEW

Initial implementation had an indentation parse error; import exited 0 despite it and Survival's harness printed ALL PASSED despite script errors. Those runs are invalid, retained as *-initial.log. Corrected indentation, terminated only the two inspected stuck test processes, and reran affected suites. Focused Inventory now exits 0 with ALL PASSED and no SCRIPT ERROR; full Legacy and Survival rerun follows. Review must check logs for script errors, not exit code alone.

## Skill cooldowns — TEST closeout / REVIEW

Corrected import plus InventoryTransaction, LegacySystem and Survival runners all exit 0, contain no SCRIPT ERROR/Parse Error, and report ALL PASSED. Logs: /tmp/th-skill-cooldowns/{import,inventory,legacy,survival}.log. Regression covers unrelated equipment rebuild, unequip/re-equip elapsed timers, duplicate ID bindings, stamina and activation counts. No LAN run: no transport or authority contract changed.

Review: diff is limited to SkillComponent cooldown state, existing legacy fixtures and this report. No high/medium issue, visual change, stable ID or Agent A overlap. Existing test harness's historical warnings remain; invalid initial runs with parse errors are retained separately and not counted as validation.

## Health bonus removal — SCOUT / BRAINSTORM

2026-11-17: user resumed continuous work. CharacterStats setters clamp HP, but apply/clear equipment and buff bonuses only emit health_changed after max-health changes. Removing +HP equipment or an expired buff can therefore leave current_health above max_health. Owner Player already calls these methods on equipment/buff events. Existing tests check bonus values, not HP bounds. Inspected AGENTS/copilot, current stats/owner methods, relevant tests, coordination files and recent history; Agent A equipment-close scope is disjoint.

Recommendation: reconcile current_health through its existing clamping setter only when it exceeds the new maximum, otherwise preserve the existing health_changed notification. Alternative percentage-based rescaling or auto-heal on max increase invents new balance behavior. Central pure bound reconciliation preserves current absolute HP and existing schema/signals. No source-game parity claim beyond the already-defined HP invariant.

## Health bonus removal — PLAN / HUMAN APPROVAL

Standing continuous-work approval covers this isolated gameplay correction. Dedicated fix/th-logic-health-bonus-removal branch from integrated develop. Agent B owns CharacterStats and inventory regression tests/report. Add private helper used by four equipment/buff apply/clear methods; clamp excess HP, never heal on cap increase, never re-emit died for already-dead unchanged HP, emit health_changed exactly once per update with final valid values. Tests exercise authoritative equip/unequip, timed-buff expiry, explicit clear, wounded/dead state and notification counts. No new node/UI/layout/asset/ID/save/LAN interface. Run focused regression before/after, import, Inventory/Legacy/Survival, then review, commit, PR to develop. Rollback helper/call sites/tests only.

## Health bonus removal — COOK / TEST entry

Regression run failed before fix (exit 1, /tmp/th-health-bonus/repro.log): current HP remained above cap on unequip, equipment clear, buff expiry and buff clear. Added four call sites to one private reconciliation helper; existing setter clamps excess and emits once, unchanged HP emits directly to avoid repeated died on already-dead state. No auto-heal on cap increase. Integrated base includes Agent A PR139 close presentation and skill PR140, both preserved. Full combined-tree suites follow.

## Health bonus removal — TEST / REVIEW

Godot 4.6 import, InventoryTransaction, Legacy phases1-7 plus embedded Survival/save and standalone Survival exit 0, report ALL PASSED and contain no script/parse errors. Regression verifies all four bonus updates, real timed expiry, equip/unequip, wounded/dead HP and exact one-notification behavior. Known negative-save, missing-HUD fallback and exit-resource warnings remain. Two-process LAN player-vitals regression running because HP feeds its profile; no payload/schema changed.

Review of full three-file diff: one private helper/four call sites, focused regression and owned report. No high/medium finding, art/UI edit, unrelated balance/stat change or ownership conflict. No live reference comparison or source maximum-HP rescaling semantics claimed; this repairs the existing absolute-HP invariant.

LAN player-vitals host/client both exit 0; logs/JSON /tmp/th-health-bonus/lan-*. No script errors in either process. Full test/review gates complete before commit. Skill #140 integrated as 90c9203ac; combined base also includes disjoint Agent A #139, so exact equality to the pre-art skill tree was not claimed. Combined suites validate both.

## Scene transition failure — SCOUT / BRAINSTORM

Health fix #142 integrated after disjoint Agent A back-equipment evidence #141; that report identifies unresolved Back_0 versus Back_8/9 source icon ambiguity. No slot/icon guess is made. Continue independent gameplay work.

SceneTransitionService._load_map removes the active map and queues noncached maps for deletion before trying load/instantiate of the destination. Failure leaves a stale active-map pointer and blank play area. _change_map_with_fade also emits completion on failure. Main listens to transition completion to save. Investigated the full service, owner listeners, map cache rules, relevant history, active Agent A diff and coordination. Preserve existing fade and all map IDs, cameras, UI and signals.

Recommend prepare/validate the destination before detaching the current map, and return internal success to suppress false completion. Alternative reconstruct old maps after failure loses dungeon run state; global loading redesign is unnecessary. Existing synchronous load stays synchronous.

## Scene transition failure — PLAN / HUMAN APPROVAL

Standing continuous bug-fix approval applies. Branch fix/th-logic-map-load-recovery from latest develop. Scope: shared runtime scene_transition_service.gd logic only, owned tests/inventory_transaction_tests.gd and this report. No visual field, layer, timing, map scene, ownership or public interface changes. _load_map returns bool internally; check initialized root/player, destination registration, PackedScene type, instantiated Node2D and usable cache before mutating old map; failed transition fades back, releases transition lock and does not signal completion. Tests create temporary PackedScene resources with Node2D/Marker2D only, use an isolated service instance, verify failed path/non-map resource leaves old cached/noncached map and player position intact; verify success spawns, caches/uncaches and emits completion once. Missing/corrupt cache should reload. Regression before fix then import/Inventory/Legacy/Survival and review. No real player save or gameplay scene is modified by test. Rollback service and test/report.

## Scene transition failure — COOK / TEST entry

Before-fix Inventory regression exits 1: missing load detaches/frees active dungeon and signals completion; Resource instead of PackedScene triggers nonexistent instantiate script error. /tmp/th-map-recovery/repro.log retains evidence. Destination now prepared/type-checked before source mutation; internal success gates completion while preserving fade behavior. Active cache and current-map IDs remain unchanged on failure. TEST follows on isolated user storage.

TEST added real fade, wrong-root scene and freed-cache recovery checks. Freed cache exposed a cast-on-freed-object script error despite suite success output; added is_instance_valid before the typed cast and reran the focused suite. The earlier log is invalid as a full pass and retained as inventory-cache-initial.log. No generic ALL PASSED marker is trusted without log inspection.

## Scene transition recovery — TEST / REVIEW closeout

Godot 4.6 import, Inventory, Legacy phases1-7 plus Survival/save and standalone Survival pass with no script/parse errors. Final Inventory includes missing-path, non-scene resource, wrong-root scene, preserving live noncached dungeon, correct spawn, cached identity, freed-cache reload, real fade restore and transition-lock/completion assertions. /tmp/th-map-recovery contains final logs. Known invalid-save/HUD/exit-resource warnings remain; destination warnings are intentional negative fixtures. No LAN change or visual-parity assertion.

Review: prepared destination before mutation, current run/player preserved on preparation failure, successful transitions retain caching/spawn/fade behavior. Three-file scope matches plan; no high/medium finding or concurrent Agent A edit remains. Private _load_map now returns bool, public signal signatures stay unchanged. Main's transition_started loot collection still runs on transition attempts; this feature does not claim all external start-listener side effects roll back. MAIN stays excluded.

## Hurtbox reset race — SCOUT / BRAINSTORM / PLAN

Map recovery #145 passed tests/review and integrates to develop. Next independent component defect: HurtboxComponent starts deferred release coroutines after each accepted hit; reset only sets can_take_damage=true. An old timer can release a newer post-reset hit's invincibility early. No exact source iframe duration is claimed or changed.

Choose a private generation token: reset invalidates pending releases, each accepted raw/resolved hit records a new generation before emitting signals, only matching release can unlock the hurtbox. Alternative stop-and-recreate Timer child changes node contracts; serializing hits unnecessarily affects gameplay. Standing continuous approval covers this isolated fix.

Exact files: sense/components/hurtbox_component.gd, tests/inventory_transaction_tests.gd, this report. Existing signals/method signatures, scene nodes, collision layers and configured durations remain unchanged. Reproduce with old long-running raw hit -> reset -> new resolved hit; wait past old deadline but before new deadline and verify rejection, then permit at new expiry. Repeat with reset inside synchronous damage callback to catch invalid token capture order. Run Inventory/Legacy/Survival and LAN combat because both damage entry points feed existing combat authority. Review full diff before commit/PR. Rollback token and tests. No Agent A dependency.

## Hurtbox reset race — COOK / TEST

Initial scratch invocation appended a test function before its caller existed on the pre-map branch, so it was not a valid reproduction. Synced integrated map #145 preserving local additions, wired awaited test, reran; /tmp/th-hurtbox-race/repro.log records actual pre-reset timer release failures. GitHub default identity changed during collaboration; scoped GH_TOKEN loaded in process for Thanh-xyz (never printed) successfully merged #145. Agent A #143/#144 are disjoint already in the base.

Implementation captures generation and configured duration before synchronous callbacks, invalidates on reset, checks token before deferred scheduling and timer completion. No signature change except private release helper. Tests cover raw -> reset -> resolved and synchronous reset with different durations. Full suites and LAN combat follow.

## Hurtbox reset race — TEST / REVIEW closeout

Godot 4.6 import, Inventory regression, Legacy phases1-7 plus Survival/save, standalone Survival and two-process LAN combat all exit 0 and contain no script/parse errors. Both timer races reproduced before correction and pass after it. Tests intentionally wait across old/new timer deadlines, not one frame; no configured invincibility duration changes. Logs/JSON /tmp/th-hurtbox-race.

Review confirms generation captured before callbacks in both raw/resolved entry points, reset invalidates old release and completion checks identity. Three-file scope, stable signals and damage rules, no visual/asset/schema change. Existing harness negative-save/HUD/resource warnings remain. Agent A's active equipment-detail-sell art files are disjoint and preserved. No high/medium finding remains; PR to develop next.

## Ground item capacity — SCOUT / BRAINSTORM / PLAN (2026-11-17)

Current GameItem marks collected before checking inventory or item validity. Full/partial item pickups destroy the original and create a replacement, losing pickup mode/lock/network-related instance properties and emitting requested rather than received quantity. Invalid collector loses the pickup entirely. Inspected full collection/helper paths, survival StubPlayer and tests, recent GameItem history and coordination. Agent A #147 sell presentation is integrated and disjoint.

Choose retaining the original item with its remaining quantity; alternatives spawning overflow requires copying instance settings and allows churn on full bags, while all-or-nothing grants would change existing partial acceptance. Standing approval covers this logic fix on fix/th-logic-ground-pickup-capacity from develop. Files: GameItem collection logic, existing Survival tests, owned report. Preserve visual methods/scene/IDs and network-replica authority path. Item branch returns actual accepted count; emit only accepted quantity, retain unreceived items, clean up only fully received pickup. Reject invalid collectors/inventory and invalid item/quantity before unlock or mutation. Recheck collected state after async unlock; reserve collection during synchronous inventory callbacks. Tests full bag, partial stack, exact retry, invalid collector and reentrant callback. Run before/after regression, import, Inventory/Legacy/Survival and LAN loot regression. Multi-item chest atomicity remains separate; no source parity claim.

PLAN refinement before implementation: magnet_collect has already animated the original pickup before delivery; retaining that invisible/shrunken node requires visual restoration outside this slice. Preserve existing partial-overflow spawning. Instead validate item and collector before collection, suppress collection on invalid inventory, and report actual quantity. Zero-capacity and partial overflow remain existing behavior for now; do not introduce visual-state changes. Focus first on invalid collector/item loss and accepted-quantity signals, with overflow count conservation tests. No full-bag behavior change claimed.

## Pickup delivery — COOK / TEST

Pre-fix Survival reproduced both loss on missing inventory and requested-versus-delivered signal mismatch. Initial run also lacked newly integrated red-button import cache; editor import fixed that environment issue before further validation. No art source changed. Item delivery now validates collector/inventory/item identity before unlock/consume and after await; _is_collected reserves the transaction during synchronous inventory signals. _collect_item returns accepted count; overflow spawning and existing visuals/network paths remain unchanged. Magnet collection rejects unsupported delivery before starting animation. Regression verifies partial quantity, overflow conservation, invalid inventory/item and reentrant inventory callback. Gold/chest get inventory validation too; multi-item payload validation is not included.

## Pickup delivery — TEST / REVIEW

Godot4.6 import, Inventory, Legacy+Survival and standalone Survival all exit0 with no script errors; LAN combat/loot host+client exit0. Expanded reentrant/invalid-ID checks rerun in survival-final.log. Logs /tmp/th-pickup. Full diff review found no high/medium issue in the bounded delivery change: validation before key use, after async unlock, reservation before inventory callbacks and actual delivery signal. Existing overflow respawn and host loot-consumption listener are preserved (including a zero-delivered lifecycle event when a valid full-bag pickup spills all items). No new visual or save/network contract. Known harness warnings retained; missing red asset cache in initial reproduction fixed by import, not source edits.
