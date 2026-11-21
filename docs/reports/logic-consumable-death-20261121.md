# Dead consumable use — 2026-11-21

## SCOUT

User renewed continuous Agent B gameplay work. Base develop@1434eb48a includes pickup/chest fixes and Agent A presentation. Baseline Godot 4.6 import exits0, no script errors. Inspected AGENTS, seven coordination records, owned reports/handoffs, player/panel callers, InventoryData.use_item, CharacterStats, test runners, relevant runtime histories, active art branch/diff (clean feature/th-art-detail-stat-cells). No other worktree edited.

Verified isolated Godot reproduction /tmp/th-consumable-death-scout.{gd,log}: dead player through hotbar or wired inventory right-click has HP0->50, potion1->0, state remains DEATH. Existing quick_use_potion, Player.heal and LAN host reject dead use. No source-game death/revive balance inferred. Crafting audit separately found noncanonical recipe-validation mismatch and stale inventory signal binding; neither is part of this feature and neither was runtime-reproduced.

## BRAINSTORM

Choose pre-consumption guards in the two existing caller branches. Alternative guarding _on_item_used alone leaves inventory already consumed. Adding actor policy to InventoryData or a shared item-use service expands contracts without need. Keep optional panel stats behavior and equipment/shop branches unchanged. No new art/event/scene/save/network/ID contract or visual change.

## PLAN / HUMAN APPROVAL

Standing continuous bug-fix approval, renewed by current user, covers this bounded correction. Dedicated branch fix/th-logic-dead-consumables from latest develop. Files: shared sense/entities/player/player.gd (hotbar consumable branch rejects State.DEATH or nonliving stats), shared sense/ui/inventory/inventory_panel.gd (consumable branch rejects nonliving existing character_stats), Agent B tests/survival_tests.gd (real player/panel regressions), and this owned report. Shared histories/handoff/active art diff reviewed; no Agent A overlap or new contract. Preserve signatures, payloads, equipped/shop behavior, optional null panel stats, configured effects and balance.

Order: add regression first; run Survival and retain before-fix failures; add two guards; import and run InventoryTransaction, standalone Survival and Legacy phases1-7+embedded Survival using isolated XDG_DATA_HOME. Test both dead routes for potion/stamina/timed-buff conservation, no effects/mutation notifications; positive live controls and reset/respawn eligibility. Include existing quick potion policy and optional-null panel compatibility. Check script errors as well as exits/ALL PASSED. Review complete diff independently, fix findings and run affected gates. Commit/push/PR into develop with scoped Thanh-xyz auth, integrate only after review/tests and verify tree. MAIN excluded because it is the separate original-content line. No LAN or screenshot comparison required for caller precondition-only change; existing LAN authority/visual paths unchanged. Rollback guards and tests/report. Unknown source revive semantics remain outside scope.

## COOK / TEST entry

Added real-player regression first: standalone Survival before the fix exits1 with 20 intended failures and no script/parse errors; /tmp/th-logic-resume-20261121/repro.log. Tests use actual Player scene and its wired InventoryPanel, cover health/stamina/timed-buff inventory/effect/notification conservation across both dead routes, separate hotbar state/zero-HP gates, quick potion policy, living use after reset_player and optional-null panel stats compatibility. Added two guards before existing use_item calls; no effect handler/payload or item balance changed. Exact scope remains four files; full TEST next.

## TEST closeout

Godot 4.6.stable.official.89cea1439 editor import, InventoryTransaction, standalone Survival and Legacy phases1-7+embedded Survival all exit0; all gameplay runners report ALL PASSED and all logs contain no SCRIPT ERROR, Parse Error or Compile Error. Current task logs/results: /tmp/th-logic-resume-20261121/{import,inventory,survival,legacy}.log and matching *-result.json. Each runner uses independent XDG_DATA_HOME; no real user save is touched. Before-fix 20 regression failures now pass, including successful use of all three item categories after actual respawn. Existing negative-save, missing-HUD fallback and exit resource/ObjectDB warnings remain harness noise. No LAN/renderer run or source parity claim for these two preconditions. git diff --check passes. Next REVIEW of exact four-file diff.

## REVIEW closeout

Independent read-only review inspected the complete four-file diff/report, caller/setup/death/respawn/effect paths, before-fix failures and all final test result/log markers. No high/medium finding or ownership conflict; PR-ready. Both guards precede mutation and leave unrelated branches intact. The panel uses its existing optional CharacterStats contract: it rejects zero HP but cannot inspect an artificial actor DEATH-with-positive-HP state; the hotbar checks both. No new actor-reference API is added. Source revive semantics and direct low-level effect calls are outside this caller correction. Whitespace and exact four-file scope pass. PR to develop next; integration receipt will be recorded in shared Agent B status/handoff.
