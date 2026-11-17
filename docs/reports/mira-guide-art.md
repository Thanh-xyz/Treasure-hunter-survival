# Mira guide icon

Date: 2026-11-17
Branch: feature/th-art-mira-guide-icon
Stage: REVIEW complete; PR next

## SCOUT

Rechecked repository instructions, coordination/handoffs and latest five commits.
The earlier Quest 325 scout verified FAQ object 93905 points to external file
218 / path ID 1: asset e04a8939bc803b34a9aa30d3add8dbc3, Sprite Mira Icon.
The selected export independently rechecks as RGBA 160x160 with SHA-256
4487785383c988d7a93529d3a353f205508836b7bb1cf1285cbdf522c74b59c7.
Original scout records centered pivot and 100 PPU. Full Mira portrait export
is transparent due an exporter collision and must not be used. Android was
reconnected by user and adb devices -l confirms SM_A047F R58W70GXK6J.

## BRAINSTORM

Compared (1) exact metadata-only guide icon, (2) icon plus recovered portrait,
(3) full world NPC integration. Select (1): exact source bytes and explicit
FAQ pointer make it independently verifiable. Portrait recovery needs atlas
reconstruction; world NPC needs a separate Agent B/shared contract. Neither
is needed to safely preserve this guide asset.

## PLAN / standing approval

Current continuous Art/UI approval covers adding this one exact asset with
local_only provenance. Agent A owns manifest, art report and art handoff.
Files: assets/treasure_hunter/npcs/mira/mira_icon.png plus Godot-generated
.import; docs/architecture/asset-manifest.json; this report;
docs/handoffs/art-to-logic.md. Use stable metadata ID actor.npc.mira.icon.
No source script/scene, gameplay ID, NPC placement, quest, save, shop or network
contract changes. No icon used as a world sprite.

Implementation: copy source bytes, append one manifest entry without reformatting
existing entries, import losslessly/no mipmaps, load texture in Godot, render
an isolated TextureRect at native dimensions and compare exact opaque pixels.
Acceptance: hash identity, RGBA 160x160, unique manifest IDs/paths, local_only,
Godot import/load, render/source comparison, five-file scope and whitespace.
No direct Quest 325 runtime parity claim. Rollback is a normal feature revert.

## COOK / TEST

Copied one PNG byte-for-byte; added metadata-only actor.npc.mira.icon and
Godot-generated lossless/no-mipmap import. Source and target SHA-256 match.
Godot 4.6 --headless --editor --import --quit exits 0. Temporary native-size
TextureRect render under Xvfb exits 0 and loads the resource successfully.
PIL comparison: all 17,559 fully opaque pixels have zero channel difference;
all 25,600 alpha samples have zero difference. Transparent RGB is not a fidelity
metric. Output: /tmp/th-mira-native-render.png, script /tmp/th-mira-render.gd.
Unique manifest IDs/paths, import settings and git diff --check pass.
No direct live Quest 325 UI placement/scale/animation parity is claimed.

## REVIEW

No high/medium finding in the five-file scope. Original transparency, canvas
and source bytes preserved, provenance local_only, no runtime consumer or
Agent B-owned file changed. The world modular Mira and the other portrait
variants remain excluded. Next PR into develop; main remains separate.
