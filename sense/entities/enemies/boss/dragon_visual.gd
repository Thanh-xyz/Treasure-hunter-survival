class_name DragonVisual
extends Node2D
## Segmented dragon assembled from the CC0 Ninja Adventure dragon parts (head, two wings, body
## chain, tail end) for Infernal Dragon / Frost Leviathan / Ancient Dragon (plan phase E).
## Animated in code: wings flap, the body sways. Optional hue shift recolours the parts.

const HUE_SHADER := preload("res://sense/art/shaders/hue_shift.gdshader")

var _wings: Array[Sprite2D] = []
var _body: Array[Sprite2D] = []
var _head: Sprite2D


static func build(asset_id: String, hue_degrees: float = 0.0) -> DragonVisual:
	var folder := str(MonsterVisualCatalog.DRAGON_PARTS.get(asset_id, ""))
	if folder.is_empty():
		return null
	var v := DragonVisual.new()
	var base := MonsterVisualCatalog.NINJA + folder
	if absf(hue_degrees) > 0.01:
		var mat := ShaderMaterial.new()
		mat.shader = HUE_SHADER
		mat.set_shader_parameter("hue_degrees", hue_degrees)
		mat.set_shader_parameter("saturation", 1.15)
		v.material = mat
	for side in [-1.0, 1.0]:
		var wing := v._part(base + "Wing.png", Vector2(26.0 * side, -18.0))
		wing.flip_h = side < 0.0
		v._wings.append(wing)
	var chain := ["Body1.png", "Body2.png", "Body1.png", "BodyEnd.png"]
	for i in range(chain.size()):
		v._body.append(v._part(base + chain[i], Vector2(-10.0 - 9.0 * i, 6.0 + 9.0 * i)))
	v._body.reverse()
	for seg in v._body:
		v.move_child(seg, 0)
	v._head = v._part(base + "Head.png", Vector2(0, -6))
	return v


func _part(path: String, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path) as Texture2D
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = pos
	s.use_parent_material = true
	add_child(s)
	return s


## Called by Monster each frame instead of sprite animation.
func animate(t: float, facing: Vector2, moving: bool) -> void:
	var flap := sin(t * (9.0 if moving else 5.0))
	for i in range(_wings.size()):
		_wings[i].scale = Vector2(1.0, 0.85 + 0.15 * flap)
		_wings[i].rotation = (0.12 * flap) * (-1.0 if i == 0 else 1.0)
	for i in range(_body.size()):
		_body[i].position.x = (-10.0 - 9.0 * (_body.size() - 1 - i)) + sin(t * 3.0 + i) * 2.0
	if absf(facing.x) > 0.2:
		scale.x = absf(scale.x) * (-1.0 if facing.x < 0.0 else 1.0)
