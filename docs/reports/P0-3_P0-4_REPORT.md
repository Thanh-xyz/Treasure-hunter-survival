# P0-3 / P0-4 — Implementation, Test and Review Report

- Stages: IMPLEMENT → TEST → REVIEW · 2026-11-07/08
- Plan: [P0-3_P0-4_PLAN.md](../plans/P0-3_P0-4_PLAN.md) (approved 2026-11-07)
- Branch: `feature/p0-provenance-and-fixtures` (from `feature/p0-original-direction`, PR #133)

## P0-3 — Provenance registry and gates

| Deliverable | File(s) |
| --- | --- |
| Manifest schema v2 (140 records: 1 original, 57 unverified, 82 excluded) | `docs/architecture/asset-manifest.json` |
| One-off, idempotent migration | `tools/provenance/migrate_manifest_v2.py` |
| Static gate (`--mode dev/release`) + CREDITS generation | `tools/provenance/check_provenance.py` |
| Gate unit tests (12) | `tools/provenance/test_check_provenance.py` |
| Runtime gate (scene dependency graph, script literals, monster/item catalogs, self-test probe) | `tests/provenance_tests.gd`, `tests/ProvenanceTests.tscn` |
| Credits | `CREDITS.md` |

Findings:
- Godot's `ResourceLoader.get_dependencies()` does **not** report `preload`/`load` targets in
  GDScript files (verified with a probe). The runtime gate therefore also scans script literals.
  With that it finds 88 runtime assets, consistent with the static scan.
- Release mode currently fails with 86 errors (29 unverified, 55 excluded references). This is
  the expected state until P0-5…P0-9 replace and retire them. `run_tests.sh` reports it as INFO.
- The forbidden-source rule (`assets-ths`, absolute `/home/` paths) applies to shipped files only;
  tests may name these sources in assertions.

## P0-4 — Save fixtures

| Deliverable | File(s) |
| --- | --- |
| 13 fixtures: v0–v5 historic copies of one full profile, reference items, q306 progress, q311 pending claim, legacy index-only quest, and 3 invalid files | `tests/fixtures/saves/*.json` |
| Deterministic generator (uses the live save code and validates every output) | `tests/fixtures/generate_save_fixtures.gd`, `GenerateSaveFixtures.tscn` |
| Fixture suite | `tests/save_fixture_tests.gd`, `tests/SaveFixtureTests.tscn` |

The generator pins `saved_at` and `daily_date`, so regenerating produces byte-identical files
(checked with md5).

### Bug found and fixed: saves stop working after the player gets a mount

- **Symptom**: as soon as a profile owns a mount, every save is refused
  (`Temporary save validation failed`) and such a save can't be loaded either.
- **Cause**: JSON parses numbers as floats. `_validate_profile` checked
  `owned_skins.has(int(skin))`, and `Array.has()` compares types strictly in Godot 4, so
  `[0.0].has(0)` is `false` (confirmed with a probe). The in-memory snapshot passes, but the
  re-read temp file fails, so the write is aborted.
- **Impact**: the free Dust Pony unlocks at level 3 (quest q06 "Saddle Up"). From then on no
  progress was ever saved. Save files with a mount written by older code were rejected on load,
  and the next save would replace them.
- **Fix**: `SaveService._has_integer()` compares numerically
  (`sense/globals/save_service.gd`). No save format change.
- **Regression test**: `_test_mount_owner_can_save_and_reload` (failed before the fix with exactly
  the three expected errors; passes after).
- The fix is outside the "tests only" scope of the approved plan. It was made because it is a
  data-loss bug with a minimal, format-neutral fix, and is in its own commit so it can be
  reviewed or reverted separately.

## Test evidence

`tools/run_tests.sh` on Godot `4.6.stable.official.89cea1439`, `user://` isolated:

| Step | Result |
| --- | --- |
| import | PASS |
| provenance gate unit tests (12) | PASS |
| provenance gate (dev) | PASS |
| provenance gate (release) | expected FAIL (INFO): 86 non-shippable references |
| InventoryTransactionTests, SurvivalTests, LegacySystemTests | PASS |
| ProvenanceTests (new) | PASS — 88 runtime assets: unverified 36, excluded 52 |
| SaveFixtureTests (new) | PASS |
| LAN harnesses ×3 (host + client) | PASS |

Total: **15/15 PASS**.

## Review notes

- `run_tests.sh` now bounds each suite with `timeout -s INT 300`: a GDScript parse error makes
  headless Godot hang rather than exit, and SIGINT flushes the log.
- The portable Godot binary lives in the session scratch directory and disappears with it.
  Downloading it from `github.com/.../releases/download` returned HTTP 504 repeatedly on
  2026-11-08; `gh release download` worked. A stable local location (owner choice) would avoid
  re-downloading.
- Fixtures intentionally include reference IDs (`th_weapon_28/29`, `q306`, `q311`): they exist
  so the v6 migration can prove these are carried forward without loss.

## Risks / open items

- The runtime gate can't see paths built from string concatenation. None exist today; the
  static gate's unit tests document the supported patterns.
- `docs/legal/` (owner's PDF) remains untracked by decision.

## Next

P0-5 (original UI kit), P0-6 (Normal-zone monster replacements), P0-7 (props/portrait) need a
PLAN with an art bible first. P0-8 (save v6 migration 🔒) can start its PLAN in parallel, now that
fixtures exist.
