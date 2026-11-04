# Logic Progress

Date: 2026-11-04
Current stage: REVIEW complete for the first approved gameplay feature.

## Completed workflow

- SCOUT and BRAINSTORM established the Godot 4.6 architecture, current migration coverage,
  reference evidence, shared-file risks and offline-first direction.
- PLAN selected inventory/reward integrity as the first independent vertical slice because it
  does not require the missing Agent A asset contract.
- COOK added one atomic item transaction boundary and migrated crafting, quest claim and
  homestead collection to it.
- TEST added focused headless coverage plus regression assertions in the existing runners.
- REVIEW inspected the complete diff, call sites, Agent A branch and remote state.

## Gameplay changes

- `InventoryData.transact_items()` simulates all removals/additions and commits only when every
  output fits.
- Crafting now returns failure without consuming ingredients and emits no crafted event when
  the output cannot fit.
- Quest claims now advance only after the complete reward is accepted; XP and gold are not
  partially granted on item-capacity failure.
- Building collection now preserves `last_collect` and pending production when inventory is
  full.
- No asset, scene, content-ID, save-schema, networking or Agent A-owned file changed.

## Test evidence

Executed with Godot `4.6.stable.official.89cea1439` downloaded to a temporary directory:

```text
/tmp/th-godot-ISNBhK/Godot_v4.6-stable_linux.x86_64 --headless --path . \
  res://tests/InventoryTransactionTests.tscn
```

Result: exit code 0, `[INVENTORY TRANSACTION TEST] ALL PASSED`.

The focused suite verifies rollback and success paths for raw inventory transactions,
crafting, quest rewards and building production. The complete `LegacySystemTests.tscn` run
reached all legacy phases, but the survival runner could not compile because
`sense/entities/player/player.tscn` references missing soldier PNGs. Missing item-icon imports
also produce existing warnings; neither issue was introduced by this feature.

## Integration status

- Feature branch: `feature/th-logic-inventory-transactions`, based on `origin/main` at
  `e8fc3c7`.
- No dedicated origin integration/development branch was found.
- Agent A remains clean at `e8fc3c7` with no unique commit, so no current file overlap exists.
- `gh auth status` is valid for `Thanh-xyz`; no open PR or issue was returned.
- No commit, push, PR or merge has been performed yet.

## Outstanding risks

1. Root `AGENTS.md`, `.agents/skills`, shared coordination directory and Agent A handoff are
   still absent.
2. The full gameplay test suite remains blocked by missing tracked player sprite resources.
3. Upgrading a building with pending production still ignores a failed auto-collection; the
   stored timestamp is preserved, but the later rate calculation can over-credit production.
4. The UI currently treats failed quest/building collection as a generic false/zero result and
   needs an approved UX message contract.
5. No Android device/emulator is connected for reference runtime comparison.

## Recommended next feature

Restore the executable baseline by resolving or formally stubbing the missing player sprite
resources in coordination with Agent A. After that, build the first reference-parity slice:
Mosqui/Snailu/Astromophy field combat, loot and inventory, using approved canonical IDs and
asset metadata.

## 2026-11-04 — Building upgrade integrity

- Branch: `feature/th-logic-building-upgrade-integrity`, based on `origin/develop` at
  `efc07ce`.
- Producer upgrades now require pending output to be collected successfully before cost is
  spent or level is changed.
- A full inventory preserves building level, production timestamp, gold, and material cost.
- After capacity is available, pending output is collected at the old building rate and the
  upgrade charges exactly once.
- Godot 4.6 focused transaction tests, legacy phases 1–7, and survival tests passed with exit
  code 0. The corrupt-save warning remains an intentional recovery test.
- No asset, ID, scene, save schema, networking contract, or Agent A-owned file changed.

## 2026-11-04 — Atomic economy transactions

- Branch: `feature/th-logic-atomic-economy`, based on `origin/develop` at `b7e907b`.
- `InventoryData.transact()` now commits item slots and gold as one validated mutation while
  preserving `transact_items()` as a compatible wrapper.
- `GameState.spend()` rejects unknown item IDs and rolls back the entire mixed gold/item cost
  when any requirement is invalid or insufficient.
- `GameState.grant()` now commits gold and item rewards together before applying XP.
- Focused tests verify rollback emits no signals and a successful mixed transaction emits one
  final-state signal for gold and inventory.
- Focused, legacy phases 1–7, and survival suites passed with Godot 4.6 and exit code 0.
