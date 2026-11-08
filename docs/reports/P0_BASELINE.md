# P0 Baseline — Project Rules and Test Environment

- Stage: IMPLEMENT + TEST for roadmap tasks **P0-1** and **P0-2** · 2026-11-07
- Approval: owner confirmed the BRAINSTORM design and roadmap ("xác nhận", 2026-11-07)
- Branch: `feature/p0-original-direction` from `feat/survival-rpg @ 5a54668` (= `main`)

## P0-1 — Project rules

| Change | File |
| --- | --- |
| Rewrote the agent rules for the original-game direction: originality and asset policy, excluded sources, provenance, save-migration and authority boundaries, isolated testing | `AGENTS.md` |
| Appended a superseding decision (old entries kept for history) | `../treasure-hunter/shared/coordination/decisions.md` (outside the repo) |

Agent A / Agent B worktrees, branches and status files were **not** touched.

## P0-2 — Test environment

| Item | Value |
| --- | --- |
| Godot | `4.6.stable.official.89cea1439` (same build as CI and earlier agents) |
| Source | `github.com/godotengine/godot/releases/download/4.6-stable/Godot_v4.6-stable_linux.x86_64.zip` |
| Integrity | SHA-512 verified against the release's `SHA512-SUMS.txt` |
| Location | session scratch dir (portable; nothing installed system-wide) |
| Isolation | `XDG_DATA_HOME` / `XDG_CONFIG_HOME` / `XDG_CACHE_HOME` per run, so `user://` never touches real saves |
| Runner | `tools/run_tests.sh` (new): `GODOT=<binary> tools/run_tests.sh [workdir]` |

## Baseline results (executed)

| Step | Result | Notes |
| --- | --- | --- |
| Headless import (`--editor --quit-after 120`) | PASS | 0 errors; no tracked file modified |
| InventoryTransactionTests | PASS | "ALL PASSED" |
| SurvivalTests | PASS | "ALL PASSED" |
| LegacySystemTests | PASS | Phases 1–7 all passed, plus the embedded survival/save run |
| LanPeerRunner (host + client) | PASS | 3/3 repeats at 0.5 s stagger, plus 2/2 at 0.5 s and 1.0 s |
| LanCombatPeerRunner (host + client) | PASS | 3/3 repeats at 0.5 s; **fails at 1.0 s stagger** (see below) |
| LanPlayerPeerRunner (host + client) | PASS | 3/3 repeats at 0.5 s; **fails at 1.0 s stagger** |
| Full script run (`tools/run_tests.sh`) | **ALL PASSED** (10/10) | |

### Expected log noise (not failures)

Tests deliberately feed corrupt saves, unknown shop items and invalid snapshots, so the logs show:
`Parse JSON failed` (×3), `Corrupt save … trying backup` (×14), `Refusing to write an invalid
snapshot`, `ShopComponent: Item 'missing_item' not found`, `Player: HUD not found`, and
`ObjectDB instances leaked` / `resources still in use at exit`. These match the harness noise
earlier agents recorded.

### Not run

- The 9 `tests/render_*.tscn` screenshot scenes. They need a rendering (non-headless) run and
  manual visual review. They will be used when the UI kit replaces the reference chrome (P0-5).

## Findings

1. **The baseline is green.** The existing code on `main` passes every automated suite on this
   machine. This confirms the earlier agents' CI reports independently.
2. **LAN harnesses are timing-fragile.** Runners use fixed lifetimes (host 3.5–5.5 s, client
   2.0–4.8 s). The first attempt started the client 1.5 s after the host and all three clients
   failed. With a 1.0 s stagger, the combat and player runners still fail their late-stage checks
   (`far_hit_rejected`, `critical_hit_seen`, `profile_seen`) because the host exits before them.
   This is a test-harness limitation, not a gameplay failure. The runner script pins the stagger
   to 0.5 s. Recommended follow-up (with P9-1): replace fixed lifetimes with "wait for peer, then
   run checks, then exit" handshakes.
3. Render tests have no automated pass/fail. A screenshot diff gate is worth adding in P0-5.

## Next

P0-3 (provenance registry + gate) and P0-4 (save fixtures) need a detailed PLAN before
implementation. That PLAN is the next deliverable.
