# Dead skill admission — 2026-11-27

## SCOUT

A real Player/SkillComponent probe reproduced three failures: dead activation returned true, stamina dropped 100 -> 65, and a six-second whirlwind cooldown started. SkillComponent consumed through its injected stamina Callable and set cooldown before Player._on_skill_activated rejected DEATH. Evidence: /tmp/th-logic-20261127/{dead-skill-probe.gd,DeadSkillProbe.tscn,dead-skill-red.log}; exit 1 without script errors.

Inspected Player component/death/reset/respawn wiring, SkillComponent admission/input/timers, SkillExecutor and database, existing dead-consumable tests, recent Player/test history, all seven coordination records and Agent A live equipment-detail diff/handoff. No overlap or dependency. This is internal gameplay evidence; no reference balance or visual behavior is inferred.

## BRAINSTORM

Select eligibility in Player's existing stamina Callable. It already rejects resource requests through false; owner state can reject before resource/cooldown/activation commits without changing generic SkillComponent. A new can-activate Callable would expand the API for no present need. A refund after rejected execution would leave transient notifications, report success and require timer rollback. General admission API is deferred to a separately justified architecture plan.

## PLAN / HUMAN APPROVAL

Standing continuous gameplay maintenance approval covers a pre-consumption eligibility guard, following the existing dead-consumable invariant. Branch fix/th-logic-dead-skill-use from develop@eeb009920. Exact scope: sense/entities/player/player.gd (shared runtime owner injection only, history/handoff/active diff inspected), tests/survival_tests.gd (owned regression), and this owned report. No Agent A file, scene, layout, public method/signal/payload, stable ID, balance/stat formula, save or LAN contract changes. Buff HUD wiring and other action states excluded. Full plan /tmp/th-logic-20261127/dead-skill-plan.md.

Guard DEATH or nonliving stats before stats.use_stamina. Verify natural death, DEATH with positive HP, zero HP before DEATH, direct admission and synthetic InputEventAction through the real input handler. Verify no stamina event, cooldown creation, activation/skill-used event, HP/state mutation or skill-effect children. Positive controls use actual respawn and all three skill executors, exact catalog cost/cooldown/events and normal insufficient-stamina rejection. Freeze physics/timer processing; await effects before cleanup and disconnect global observers. Rollback removes guard/tests/report without migration. MAIN excluded.

## COOK

Player's injected use_stamina_func returns false when is_dead() or not stats.is_alive(), otherwise calls the original stats.use_stamina. SkillComponent and its rejection behavior remain intact. Original probe now exits 0, failures=0, stamina100 -> 100 (/tmp/th-logic-20261127/dead-skill-green.log).

## TEST

Godot 4.6.stable.official.89cea1439:

- `timeout 120 godot --headless --path . --editor --import --quit`: exit 0.
- `timeout 150 godot --headless --path . tests/InventoryTransactionTests.tscn`: exit 0, ALL PASSED.
- Same command for `tests/SurvivalTests.tscn`: exit 0, ALL PASSED.
- Same command for `tests/LegacySystemTests.tscn`: exit 0, Legacy1–7 and embedded Survival ALL PASSED.
- `git diff --check`: exit 0.

Each scene uses an independent XDG_DATA_HOME below /tmp/th-logic-20261127. Logs dead-skill-{import,inventory,survival,legacy}.log contain no SCRIPT ERROR, Parse Error or Compile Error. Existing negative-fixture/HUD fallback and exit-resource warnings remain.

Regression covers three skills × three death conditions × direct/input-handler paths, plus both live routes after actual respawn, exact stamina costs, cooldowns, one activation/skill-used event, actual execution completion and insufficient-stamina control. Input-handler invocation uses a synthetic InputEventAction; no physical keyboard, renderer, LAN or reference comparison was run. No protocol/drawing or visual parity claim.

## REVIEW

In-session review of complete runtime/test/report diff found no high/medium issue. Owner eligibility runs before any consumption; dead paths cannot activate the executor. Existing live cost/cooldown policy and generic component API are preserved. Tests clean up global observers and actual timed effects. Exact three-file ownership scope, original owner AGENTS.md/loop-skill edits excluded. Agent A equipment-detail work remains disjoint. No independent-agent review was invoked. PR-ready for develop under standing approval; main excluded.

## PR / INTEGRATION

Publish only the reviewed three-file change. Final PR/merge identifiers and tested/integrated tree comparison belong in Agent B shared status/handoff. If integration content differs, run affected gates on the combined tree.
