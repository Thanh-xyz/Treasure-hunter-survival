class_name DamageNumber
extends Node2D
## Floating combat text (damage, heal, XP, crit). Classic pixel style.

const FONT := preload("res://assets/Font/Pixellari.ttf")

var _label: Label


static func spawn(tree: SceneTree, pos: Vector2, text: String, color: Color = Color.WHITE, big: bool = false) -> void:
	if not bool(Combat.setting(tree, "damage_numbers", true)):
		return
	var root := Combat.world_root(tree)
	if root == null:
		return
	var dn := DamageNumber.new()
	dn.z_index = 100
	root.add_child(dn)
	dn.global_position = pos + Vector2(randf_range(-6, 6), -14)
	dn._setup(text, color, big)


func _setup(text: String, color: Color, big: bool) -> void:
	_label = Label.new()
	_label.text = text
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 16 if big else 11)
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.1))
	_label.add_theme_constant_override("outline_size", 4)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(80, 20)
	_label.position = Vector2(-40, -10)
	_label.scale = Vector2(0.5, 0.5)
	_label.pivot_offset = Vector2(40, 10)
	add_child(_label)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", position.y - 18.0, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_label, "scale", Vector2(0.75, 0.75) if big else Vector2(0.55, 0.55), 0.12)
	tw.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tw.chain().tween_callback(queue_free)
