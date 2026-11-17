# Equipment detail red button source

Date: 2026-11-17
Branch: feature/th-art-detail-sell-button
Stage: PLAN, followed by COOK under standing Art/UI approval

SCOUT: read coordination/status/handoffs, source history and Agent B diff.
Live cloak capture /tmp/th-art-back-live-detail.png shows a beveled red Sell
button. Current normal/hover/pressed styles are flat. Sale is disabled by
existing gameplay integration; this feature must not enable it.

BRAINSTORM: keep flat artwork, select compact Button_Red, or select wide
Button_Red 1. Both source variants share the same corner artwork (20x20
opaque top-left comparison at 2x, mean channel error 3.558 against the live
version-4.3.9 capture). Choose compact 32x32 source for nine-slice rendering.
This is visual matching, not proof of a Unity pointer or complete pixel parity.

PLAN: copy exact Button_Red__5904.png to ui/reference/button_red.png; record
local_only manifest/provenance; change normal/hover/pressed Sell styles only
using the existing helper with an optional texture. Keep disabled flat styling,
state, price, bounds and all gameplay behavior. Files: PNG/import, manifest,
equipment_detail_panel.gd, this report, owned handoff (six files).
Validate existing equipment-detail action renderer and disabled-state equality;
use isolated enabled visual preview without triggering a sale; check source
hash, imports, scene loads, scope and whitespace. No new dependency.

TEST: Godot 4.6 import and existing equipment-detail render/actions exit 0.
Before/after disabled screenshot has zero changed pixels. Temporary isolated
/tmp/th-sell-preview.gd renders normal artwork at 126x70 without any sale
callback; checks runtime Sell remains disabled; exit 0. Source bytes match,
manifest IDs are unique and local_only; lossless import/no mipmaps confirmed.
Preview visually inspected alongside direct live crop. No full pixel parity.

REVIEW: six-file diff only; no high/medium finding. The existing blue texture
helper delegates normal/hover/pressed states while retaining its prior disabled
style. Red Sell retains original disabled style. No gameplay, save, price,
node geometry, action or signal change. PR next into develop only.
