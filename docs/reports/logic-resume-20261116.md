# Agent B continuous gameplay — 2026-11-16

## Quest 312 — SCOUT

User renewed standing approval to continue Treasure Hunter recreation. Work uses origin/develop (bd5a5e482); Cinderwild main and PR 135 remain separate. Prior baseline: Godot 4.6 import and Inventory/Survival/Legacy suites exited 0; logs /tmp/th-agent-b-resume-20261116. Current worktrees clean; Agent A paused at q325 SCOUT. Inspected coordination records, recent shared-file histories, quest chain/state query, upgrade transaction, reward catalog, survival/save tests and authorized Quest.json.

Verified q312: previous 311, next 313, type 39, one equipment, raw level 4/display Level 5, Box 152 = 300 Gold; Vietnamese title and description available. Existing equipment_level objective counts equipped state at-or-above target. Generic upgrade balance remains provisional; activation does not claim source formula parity.

## Quest 312 — BRAINSTORM

Choose additive q312 using current-state equipment_level and Box 152. Alternative event-only upgrade counter would ignore previously upgraded current equipment and duplicate existing query logic; full source upgrade formula replacement lacks evidence. No new UI/node/art or shared interface is required.

## Quest 312 — PLAN / HUMAN APPROVAL

Standing approval applies to this bounded logic slice. Branch feature/th-logic-quest312-level5. Modify game_content.gd (shared gameplay row), quest_service.gd (legacy index shift six to seven), existing survival_tests.gd (chain, Level 4 rejection, authoritative upgrade to 5, reward once, stable ID and legacy saves), and this Agent B report. No other-agent worktree/files, asset IDs, scene/UI, save schema or LAN changes. Source disabled flags follow the existing tutorial activation policy, not proof of live availability.

Flow: q311 claim -> q312 state refresh -> equipment upgrade -> current-state refresh -> durable claim Box 152 -> q02 until q313 is separately implemented. Validate source metadata, headless import, focused Inventory/Survival and Legacy suites, generic Game Menu render and diff whitespace; review complete diff before commit/PR. Rollback is the additive row, index delta and tests. Unknown: live exact-level versus at-or-above semantics; preserve existing query behavior.

## Quest 312 — COOK / TEST entry

Implemented planned three-source-file diff and this report. Import exit 0. Source q312 assertion passed. All coordination records re-read before stage transition; Agent A still paused/disjoint. TEST runs isolated Godot 4.6 Inventory, Survival, Legacy and generic quest-menu render; no LAN/visual contract change.

## Quest 312 — TEST closeout / REVIEW

Godot 4.6 import, source metadata assertion, InventoryTransactionTests, SurvivalTests, Legacy phases 1-7 plus embedded Survival, and RenderGameMenu all exit 0. Logs: /tmp/th-q312/{import,inventory,survival,legacy,render}.log. Four generic quest captures are 360x800; outputs copied to /tmp/th-q312/menu-*.png. Known negative-save traces, missing-HUD fallback and exit resource/ObjectDB warnings remain. LAN not run: interfaces unchanged. No direct live q312 parity or upgrade-formula claim.

Reviewed full diff: only additive q312, legacy index +7, regression assertions and owned report. No high/medium finding, scene/UI/asset or Agent A edit. One existing-test convention retained: explicit state refresh after inventory commands. Stable q311 and new q312 restores are tested; old index-only save keeps q03 identity at index 9. PR target develop only; main/Cinderwild deliberately separate under current user direction.
