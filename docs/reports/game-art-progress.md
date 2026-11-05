# Game Art Progress

Date: 2026-11-05
Current feature: verified fixed HUD rail frames and attack icon.

## Completed Before This Feature

- Curated four Treasure Hunter field props.
- Integrated Mosqui, Snailu, and Astromophy static sprites.
- Added field visual-pass specification and device-capture workflow.
- Collected extensive `720x1600` runtime screenshots and recordings.
- Exported and validated 23,505 reference images from the supplied Unity build.

## Completed In This Feature

- Defined repository-wide multi-agent and stage rules.
- Added reusable workflow stage Skills.
- Established the initial Game Art Bible.
- Established the initial asset manifest and local-only provenance policy.
- Documented the Agent A scout findings and art-to-logic contract.
- Created external coordination records for Agent A and shared decisions.

## Reference UI Kit Feature

- Captured and classified 14 authorized runtime states at `720x1600`.
- Documented the observed navigation graph, dynamic exclusion regions, and visual
  system in `docs/reports/reference-screen-inventory.md`.
- Curated 26 exact exported UI images into
  `assets/treasure_hunter/ui/reference/` with stable names.
- Matched the exact `1024x1024` castle/village background used by the observed
  login and registration states.
- Matched the exact `683x1024` Halloween illustration used by the observed startup
  loading states.
- Added manifest provenance and evidence metadata for all selected UI sprites.
- Kept the feature additive: no gameplay, scene, script, or test file changed.

## Startup And Authentication Runtime Feature

- Rebuilt `StartupGate` with the exact Halloween loading illustration, server
  background, Treasure Hunter logo, age notice, panel, tab, line, and button assets.
- Added deterministic loading, register, login, and LAN-overlay captures at
  `720x1600` through `tests/RenderStartupGate.tscn`.
- Preserved the existing local, host, join, LAN status, and mode-selected methods;
  the change replaces presentation rather than authentication or networking logic.
- Corrected the active/inactive tab source mapping after runtime visual comparison.
- Kept LAN controls behind the observed `Xem thêm` affordance so the primary
  authentication state remains faithful to the reference capture.

## Fixed HUD And Hotbar Runtime Feature

- Replaced the drawn hotbar borders with the exact sliced `Panel_Stats` source.
- Added the contiguous outer hotbar frame and aligned eight existing action slots
  to the verified live/dead HUD captures without changing their input actions.
- Replaced the inferred joystick ring drawing with the exact
  `Icon_Joystick__5652.png` source after render comparison showed that
  `Joystick_1__6234.png` is a different orange gamepad-style control.
- Extended the deterministic HUD render to capture both live and dead states.

## Fixed HUD Chrome Feature

- Replaced the inferred top-right menu control with the exact `Button_Menu` source.
- Replaced the generic collapse icon with the verified dot-and-chevron
  `Icon_Arrow__5990.png` source while preserving the compact-HUD callback.
- Rejected `Button_MinimizeMode 2__6229.png` and the selected crossed-sword attack
  icon after direct comparison showed that they do not match those captured states.

## Fixed HUD Rail Feature

- Reused the exact sliced `Panel_Stats` source for the existing navigation rail
  buttons instead of the generic Godot button frame.
- Replaced the inferred item-atlas sword with the bit-exact
  `IconSlot_Weapon__1.png` single-sword source on the existing
  `character_attack` control.
- Kept hero, pet, mount, village, and bag fallback icons because current export
  candidates are not yet proven against a clean runtime crop.
- Preserved every existing rail callback, action ID, position, compact-HUD rule,
  and death-state rule.

## Validation Evidence

- Parsed `docs/architecture/asset-manifest.json` successfully with `jq`.
- Verified 92 assets, 92 unique asset IDs, and 92 unique target paths.
- Verified every non-null source and target path exists.
- Verified all 36 supplied Treasure Hunter entries use
  `distribution_scope: local_only`.
- Verified all 29 curated UI reference targets match their recorded sources
  bit-for-bit and have the manifest dimensions.
- Verified the player scene slices its `768x80` sheets into eight `96x80`
  AtlasTexture regions; manifest frame metadata matches the scene.
- Validated all ten project Skills with the Codex `quick_validate.py` script.
- Imported the project with Godot `4.6.stable.official.89cea1439`.
- Rendered loading, register, login, and LAN-overlay states at `720x1600` with
  Xvfb/OpenGL software rendering.
- Visually compared the fixed startup/authentication regions with the authorized
  ADB captures; exact background, logo, age notice, panels, tabs, line, and button
  sources are used. Pixel parity is not claimed because the original font metrics
  and quantitative dynamic-region mask are not yet available.
- Recorded masked full-frame RMSE baselines after excluding Game Booster and system
  navigation: loading `0.240604`, register `0.156490`, login `0.155654`. These are
  diagnostic baselines, not acceptance thresholds.
- Godot suites passed with exit code `0`: inventory transactions, legacy systems,
  survival systems, startup render, and mobile-HUD render.
- The HUD render produced `/tmp/emberfield-mobile-hud.png` and
  `/tmp/emberfield-mobile-hud-dead.png` at `720x1600` for direct comparison with
  the verified live and dead ADB captures.

## Not Yet Implemented

- Runtime asset registry.
- Character assembly and directional Treasure Hunter animation.
- Complete monster, pet, mount, item, equipment, UI, VFX, and audio migration.
- Quantitative visual-diff thresholds.

## Fidelity Rule

Use the exact reference asset and layout when verified. Do not redesign missing
states. Record unknown evidence and defer it until capture or metadata is available.
