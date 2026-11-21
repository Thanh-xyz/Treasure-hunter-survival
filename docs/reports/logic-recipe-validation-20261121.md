# Recipe catalog validation — 2026-11-21

## SCOUT

On integrated `develop@6c52e9c9`, `CraftingRecipe.validate_catalog()` trims IDs and
casts numeric recipe fields only while validating. A temporary Godot 4.6 scene confirmed
that a recipe with `" fire_shard "` and `" flame_augment_t1 "` passed validation and
registration, but was not craftable from a canonical inventory and could not resolve its
result item. A numeric string tier also passes validation even though runtime recipe
consumers expect an integer. Reproduction: `/tmp/th-recipe-validation-probe.gd` and
`/tmp/th-recipe-validation/red.log`.

Inspected the seven shared coordination records, Agent A's active branch/diff and latest
handoff, recipe definitions/consumers, validation history, and existing transaction tests.
Agent A's active edits are disjoint. A separate SCOUT of the stale crafting inventory signal
found only a panel-reuse refresh issue; it is deferred from this feature.

## BRAINSTORM

Compared strict validation, normalization during registration, and runtime coercion in every
consumer. Strict validation was selected: exact IDs and integer fields match the data shape
used by crafting, and malformed recipe resources fail at the catalog boundary without being
silently rewritten. Valid recipes and balance values remain unchanged.

## PLAN / HUMAN APPROVAL

The user's renewed continuous logic-work authorization covers this bounded, logic-only fix.
Dedicated branch `fix/th-logic-recipe-validation` starts at integrated `develop@6c52e9c9`.
The planned files are `sense/ui/crafting/crafting_recipe.gd`,
`tests/inventory_transaction_tests.gd`, and this Agent B report. No IDs, recipe balance,
assets, UI behavior, save data, or network contract change. Acceptance requires rejecting
whitespace-padded recipe/item IDs and non-integer tier/quantity values before registration,
while preserving all ten valid catalog recipes and passing gameplay suites.

## COOK

`validate_catalog()` now rejects recipe IDs and item IDs with edge whitespace, rejects IDs
that are not strings, and requires tier, ingredient quantity, and result quantity fields to be
integers before checking their positive values. Catalog registration remains the gate; no
runtime normalization or recipe mutation was added. Regression coverage verifies padded IDs
and string-valued numbers are rejected and never registered, including one-error behavior for
non-string ingredient/result IDs. Existing crafting transaction coverage remains the valid
recipe control.

## TEST

Godot `4.6.stable.official.89cea1439` on the final post-review diff:

- Headless editor import: exit `0`; no script, parse, compile, or import errors.
- `InventoryTransactionTests.tscn`: exit `0`, `ALL PASSED`.
- `SurvivalTests.tscn`: exit `0`, `ALL PASSED`.
- `LegacySystemTests.tscn`: exit `0`; legacy suite and embedded Survival report `ALL PASSED`.
  `Parse JSON failed` messages are expected corrupt-save negative fixtures; no script/parse/
  compile errors were reported.
- `git diff --check`: exit `0`.

Logs are under `/tmp/th-recipe-validation/` (`final-import.log`, `final-inventory.log`,
`final-survival.log`, and `final-legacy.log`), with isolated `XDG_DATA_HOME` directories.
No rendering or LAN test was needed for catalog prevalidation, and no source-game formula or
visual-parity claim is made.

## REVIEW

Independent read-only review found no high/medium issue. Review suggested avoiding a duplicate
message for non-string IDs; the validator was tightened and tests now verify one diagnostic for
each malformed ID type. The follow-up review confirmed the finding is resolved and found no new
issue. Final scope remains the two planned gameplay/test files plus this report. No Agent A
files or shared contracts changed.

## PR / INTEGRATION

Ready for PR to `develop` under the authenticated `Thanh-xyz` account. `main` remains outside
this feature's target. Integration receipt and final tree/test evidence will be appended after
the PR is merged.
