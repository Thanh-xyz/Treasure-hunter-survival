# Back equipment art scout

Date: 2026-11-16
Stage: SCOUT complete; no art implementation
Base: origin/develop@902541b1f

## Verified source evidence

- Agent B proposal in `docs/handoffs/logic-to-art.md` requests a future BackSlot
  and stable art IDs for Card 161 (`Back_8`) and Card 162 (`Back_9`).
- `Card.json` Card 161 and 162 both have `equipmentType: 5`, are equippable,
  craftable, upgradeable, and name themselves Back_8/Back_9. Their exact
  `iconUrl` is `Icons/Items/5_Back/Back_0` for both; this is a source-backed
  mismatch with the display names and must not be resolved by guessing.
- Unity metadata exports: Back_8 Sprite path ID 2 on asset file
  `00ee49df9d4664a1bb8b9db6d0dd2d64`, rect `29x18`, offset `(-2.7702,-5.5840)`,
  pivot `(0.4045,0.1898)`, `32 PPU`; Back_9 Sprite path ID 2 on asset file
  `3318470ca44524816a907b63b194ab3d`, rect `30x13`, offset `(0,0.0160)`,
  pivot `(0.5,0.5012)`, `32 PPU`.
- Addressable exports are separate variants: Back_8 `32x23` with alpha bbox
  `(1,2)-(31,21)`, SHA-256 `39c1881c563401c28791b497d6a497aca437e1a8845383b80d08bf6af31ff034`;
  Back_9 `32x17` bbox `(1,2)-(31,15)`, SHA-256
  `229e02b398da9bbd65591c219ba38b8b197a7f968151abde318ab1e5d4ba858b`.
- Unity-data standalone exports are `29x18` SHA `b55b78120b003106edeac66242e43d1f04307d2fb740c4077f12f9904d68b4b6`
  and `30x13` SHA `e02eb675640b0844fad4428ef4dd14fd7b7b0f6f6cc9130943f544ca2289e2aa`.
- The visually observed exports show Back_8 as a gray wing/cape-like item,
  Back_9 as a white wing-like item, and Back_0 as a gray armor/cape item.
  This inspection is asset evidence only; it does not prove which one the
  runtime equipment detail displays.
- Direct Android is connected as `R58W70GXK6J` / SM_A047F, but the current
  captured account is at login after the latest relaunch. No source Card 161/162
  item was obtained or equipped, and no equipment mutation was invoked during this investigation.

## BRAINSTORM / decision

Do not add `BackSlot`, modify `inventory_panel.tscn`, or register stable art IDs
until Agent B and the shared contract resolve the `iconUrl Back_0` versus
Back_8/Back_9 discrepancy and specify which source variant is authoritative.
When approved, the art plan must choose one logical canvas per card, preserve
metadata/pivot/PPU, use nearest filtering, record `local_only` provenance, and
validate the new slot against a direct character-panel capture.

## PLAN / standing approval / COOK

User authorized continued independent Art/UI work and pushing as Thanh-xyz.
This documentation-only slice records the ambiguity in this report and the owned
art-to-logic handoff; it does not implement the proposed shared BackSlot contract.

## TEST / REVIEW

Rechecked source image dimensions/hashes and Card.json fields. Reviewed the
complete two-file diff and git diff --check; no runtime file or manifest changed.
Godot/render tests are not applicable to this documentation-only feature.
ADB is currently disconnected (2026-11-17); historical captures were ephemeral.
No claim is made about whether the saved account owns either card.

## Files and validation

Read: AGENTS.md, stage skills, coordination records, Agent B handoff,
`inventory_panel.gd/.tscn`, Card.json, Unity Sprite metadata and all six Back
variant exports. No repository file changed in SCOUT. Unknown: actual source UI
slot location, runtime icon resolver, detail layout for back items, and exact
Card 161/162 stat generation.
