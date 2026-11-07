# PLAN — P0-3 Provenance Registry + Gate, P0-4 Save Fixtures

- Stage: PLAN · 2026-11-07 · base `feature/p0-original-direction @ 2ba08b7` (PR #133)
- Roadmap: [ROADMAP.md](../design/ROADMAP.md) P0-3, P0-4. Neither task is 🔒; both are tooling
  and tests only. No gameplay behaviour, asset, scene or save format changes.
- Branch: `feature/p0-provenance-and-fixtures` from `feature/p0-original-direction`.

---

## P0-3 — Provenance registry and gate

### Objective
Every asset the game loads has a provenance record. An automated test fails when the build
references an asset that isn't allowed for the current build mode.

### Current state
- `docs/architecture/asset-manifest.json`: schema v1, 138 records. Fields include `asset_id`,
  `source_path`, `target_path`, `usage`, and `provenance{status, distribution_scope, license_status}`.
  56 Feb-era records are `unknown`; 82 are `user_supplied_extracted` / `capture_derived`.
- 88 distinct `res://assets/...` literals in `sense/` and `tests/` (10 `.tscn` files), plus
  dynamic paths built by catalogs (`MonsterVisualCatalog`, `ItemIconAtlas`).
- `docs/legal/Mega Combat Asset Usage License Agreement.pdf` was added by the owner (untracked).
  Its authenticity is **not yet verified** (see §P0-3 decisions).

### Design

**Schema v2** (additive; v1 fields kept):

```json
"provenance": {
  "status": "original | verified | licence_pending | unverified | excluded",
  "source": "url | in-repo path | vendor name",
  "creator": "string | null",
  "license": "SPDX id | licence name | null",
  "license_ref": "docs/legal/<file> | assets/<pack>/LICENSE.txt | null",
  "commercial_use": "yes | no | unknown",
  "modification": "yes | no | unknown",
  "attribution": "string | null",
  "distribution_restrictions": "string | null",
  "verified_by": "string | null", "verified_on": "YYYY-MM-DD | null"
}
```

| Status | Dev build | Release build |
| --- | --- | --- |
| `original` | ✅ | ✅ |
| `verified` | ✅ | ✅ |
| `licence_pending` (licence document on file, not yet verified) | ✅ | ❌ |
| `unverified` (no licence on file) | ✅ | ❌ |
| `excluded` | ✅ until P0-9, flagged | ❌ |

Initial classification:
- 56 Feb-era packs/fonts → `unverified`.
- 82 `assets/treasure_hunter/**` → `excluded` (owner decision 2026-11-07: not used in the game;
  replaced in P0-5…P0-8, retired in P0-9).
- `PixelArt` sprites (runtime-generated) → one `original` record per sprite ID family.
- `icon.svg` → `unverified` (Godot default icon).

### Files

| File | Change |
| --- | --- |
| `docs/architecture/asset-manifest.json` | Schema v2 migration of all 138 records (scripted, reviewed diff) |
| `tools/provenance/migrate_manifest_v2.py` | One-off migration script (stdlib only) |
| `tools/provenance/check_provenance.py` | Static gate: scans `.gd/.tscn/.tres/.cfg` for `res://` asset paths plus catalog asset IDs; resolves to manifest records; `--mode dev|release` |
| `tests/provenance_tests.gd` + `ProvenanceTests.tscn` | Runtime gate: loads every catalog (monster visuals, item icons, UI theme) and asserts each resolved path has an allowed record |
| `tools/run_tests.sh` | Add the static gate (dev mode) and ProvenanceTests |
| `CREDITS.md` | Generated section from the manifest (attribution lines; placeholder for licence-pending items) |
| `docs/design/ASSET_REPLACEMENT_PLAN.md` | Reference the gate and statuses |

### Steps
1. Write `migrate_manifest_v2.py`; run; review the diff by group; commit.
2. Write `check_provenance.py`: collect literals (`res://assets/...`, `preload`, `load`, `ExtResource path=`), map catalog IDs → `target_path`, report unknown/disallowed. Exit non-zero on violations.
3. Add records for anything the scan finds that the manifest lacks (expected: a few `.tres`, fonts, `icon.svg`).
4. Runtime test for dynamic catalogs.
5. Generate `CREDITS.md`.
6. Wire into `run_tests.sh`; full run.

### Tests and acceptance
- Dev mode: gate passes on the current tree and prints a summary per status.
- Release mode: gate **fails**, listing every `unverified` / `licence_pending` / `excluded` asset (this is the expected, documented result now).
- Negative tests: a temporary scene referencing an unrecorded asset fails both gates; an `excluded` asset fails release mode.
- All existing suites still pass.

### Risks
- Dynamic path construction missed by the static scan → covered by the runtime test.
- Manifest is large; the scripted migration must be reviewed, not trusted blindly.

---

## P0-4 — Save fixtures

### Objective
A fixture suite that pins today's save behaviour, so later migrations (v6–v10) can prove they
never lose data.

### Design
`tests/fixtures/saves/*.json`, hand-built to pass the current `_validate_snapshot`
(`save_service.gd:250+`). A new `tests/save_fixture_tests.gd` loads each through
`SaveService` with an isolated `SAVE_PATH` and asserts expected state.

| Fixture | Content | Baseline expectation (v5 code) |
| --- | --- | --- |
| `v0_legacy_minimal.json` | no version field, level/xp/gold only | migrates to v5, loads |
| `v1_minimal.json` … `v4_claim.json` | one per historic version | migrates to v5, loads |
| `v5_full_original.json` | heroes, pets, mounts, 6 plots, full bag, equipment with levels and augments | loads; round-trips identical (except `saved_at`) |
| `v5_reference_items.json` | `th_weapon_28..30` with `reference` blocks, equipped and in bag | loads with exact stats |
| `v5_quest_q306_progress.json` | `main_quest_id: q306`, progress 0 | resumes q306 |
| `v5_pending_claim_q311.json` | pending claim with `source_id: q311` | claim completes once; duplicate rejected |
| `v5_legacy_index_quest.json` | index-only quest (no stable id) | +6 shift applied |
| `corrupt_truncated.json`, `future_version.json`, `bad_types.json` | invalid | rejected; `.bak` used; good backup never overwritten |

### Files
`tests/fixtures/saves/*.json` (~13), `tests/save_fixture_tests.gd`, `tests/SaveFixtureTests.tscn`,
`tools/run_tests.sh` (add suite).

### Steps
1. Read the validators (`_validate_profile`, `_validate_quests`, `_validate_inventory`,
   `QuestService.validate_pending_claim`) and the `_migrate` chain to derive exact field rules.
2. Build fixtures from a real `build_snapshot()` output (generated once in a scratch run) and
   hand-edit per case. Original content only, except the explicitly reference-ID cases, which
   exist to test their migration.
3. Write the suite; run; record expectations.

### Tests and acceptance
- All fixtures behave as in the table on the current v5 code.
- The suite is deterministic (no wall-clock dependence) and isolated from real saves.
- All existing suites still pass.

### Risks
- Fixtures could encode current bugs as "expected". Any surprising behaviour is reported, not
  silently pinned.

---

## Owner decisions needed

Approved 2026-11-07. Reference-game assets are `excluded`; the Mega Combat document is not used
as a licence basis.
