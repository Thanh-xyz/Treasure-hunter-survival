class_name MountVisual
extends RefCounted
## How a mount looks for a skin and evolution form (brainstorm sheet 04 §6.3). Pure.
## Forms change colour and add an aura; they never swap the species sprite (no new art is made:
## owner decision 2026-11-08).

const FORM_GLOW := [0.0, 0.12, 0.25, 0.4]
const AURA_ALPHA := [0.0, 0.35, 0.55, 0.8]


## {"art": asset id, "modulate": Color, "aura": Color (alpha 0 = none)}
static func describe(mount_id: String, skin: Dictionary, form: int) -> Dictionary:
	var m := CompanionCatalog.mount(mount_id)
	var art := str(skin.get("art", m.get("art", "")))
	var tint := Color(str(skin.get("tint", m.get("tint", "ffffff"))))
	var f := clampi(form, 0, FORM_GLOW.size() - 1)
	var element := element_color(mount_id)
	var modulate := tint.lerp(element, FORM_GLOW[f] * 0.5)
	modulate = modulate.lightened(FORM_GLOW[f] * 0.5)
	var aura := element
	aura.a = AURA_ALPHA[f]
	return {"art": art, "modulate": modulate, "aura": aura}


## Element colour from the mount's stats: fire, ice, crit/attack, defense, dodge, speed.
static func element_color(mount_id: String) -> Color:
	var stats: Dictionary = CompanionCatalog.mount(mount_id).get("stats", {})
	if stats.has("fire_damage"):
		return Color(1.0, 0.5, 0.2)
	if stats.has("ice_slow"):
		return Color(0.6, 0.85, 1.0)
	if stats.has("crit_chance"):
		return Color(0.75, 0.95, 1.0)
	if stats.has("def"):
		return Color(0.75, 0.8, 0.9)
	if stats.has("dodge"):
		return Color(0.75, 0.6, 1.0)
	if stats.has("atk"):
		return Color(1.0, 0.7, 0.4)
	return Color(0.85, 1.0, 0.85)
