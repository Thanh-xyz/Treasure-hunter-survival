# Equipment detail Remove action visual

Date: 2026-11-17
Stage: PLAN complete under current standing Art/UI approval
Branch: feature/th-art-detail-remove-button

## SCOUT

Direct authorized SM_A047F screenshot /tmp/th-art-back-live-detail.png
(720x1600) shows the equipped cloak detail with blue Tháo (Remove) button,
blue Upgrade and red Sell. SHA-256
6fa0cbfdc367021ff7cceaa36a5a51325446fdeef59c630595aef75ca89d4cf1.
The local EquipmentDetailPanel still draws Remove flat gray despite preloading
the selected original button_blue.png for Upgrade. Relevant recent source
history and Agent B diff inspected; no concurrent overlapping changes.

## BRAINSTORM

Compare keeping the gray provisional style or reusing the exact blue style
already used by Upgrade. Choose the existing source-texture style: direct live
capture confirms the blue Remove action. It preserves existing callback and
geometry and adds no new state/asset/contract. Full modal redesign is deferred
because that requires additional per-item layout/state evidence.

## PLAN / approval

Current user authorizes autonomous Art/UI fidelity fixes. Change only the
Remove button style call in equipment_detail_panel.gd to existing texture
helper; preserve geometry, label, enabled state and authoritative action.
Report and art handoff are owned by Agent A. No gameplay, signal, save, item
or scene contract changes. Before/after existing equipment-detail renderer
must pass; screenshot difference must stay inside Remove bounds. No full
original-to-recreation pixel parity claim. Rollback is a normal revert.

## COOK / TEST

Reused _apply_texture_button_styles for Remove; one runtime-line substitution.
Before and after: xvfb-run -a godot --path . tests/RenderEquipmentDetail.tscn,
Godot 4.6, both exit 0. Existing layout, rarity, authoritative upgrade/Gold,
locked-reference equipment, unequip and close assertions pass. No gameplay
test changed. Before /tmp/th-remove-before.png; after /tmp/th-remove-after.png.
PIL diff at 360x800: 2,168 changed pixels exclusively in (75,614)-(138,649),
the Remove action. After SHA-256
5e1d6c46388641e78f6b44dba446da55f9d9bac261d8eea006f723a713403d31.
Inspected both rendered and direct Android reference screenshots. No full
modal parity claim; hover/pressed/disabled reuse existing theme states and
were not separately observed on Android. Whitespace validation passes.

## REVIEW

No high/medium issue in three-file scope. Callback, bounds, text, authority,
input and disabled behavior are unchanged. Existing blue-button helper is
reused without introducing a new texture/resource dependency. PR next into
develop; no release into original-content main.
