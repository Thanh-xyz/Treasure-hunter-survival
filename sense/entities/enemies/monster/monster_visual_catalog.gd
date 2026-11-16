class_name MonsterVisualCatalog
extends RefCounted
## Runtime adapter from stable art IDs to data-driven monster SpriteFrames.

const DEFINITIONS := {
	"actor.monster.mosqui.atlas": {
		"texture_path": "res://assets/treasure_hunter/monsters/mosqui_atlas.png",
		"frame_size": Vector2i(64, 64),
		"animations": {
			"idle": {"row": 0, "frames": [0, 1, 2, 3, 0], "duration": 0.375, "loop": true},
			"move": {"row": 1, "frames": [0, 1, 2, 3, 4, 5, 0], "duration": 0.2916666567, "loop": true},
			"attack": {"row": 2, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.6666666865, "loop": true},
			"death": {"row": 3, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.75, "loop": false},
		},
	},
	"actor.monster.snailu.atlas": {
		"texture_path": "res://assets/treasure_hunter/monsters/snailu_atlas.png",
		"frame_size": Vector2i(64, 64),
		"animations": {
			"idle": {"row": 0, "frames": [0, 1, 2, 3, 0], "duration": 0.7083333731, "loop": true},
			"move": {
				"row": 1,
				"frames": [Vector2i(0, 1), Vector2i(1, 0), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1)],
				"duration": 0.4583333135,
				"loop": true,
			},
			"attack": {"row": 2, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.6666666865, "loop": true},
			"death": {"row": 3, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.75, "loop": false},
		},
	},
	"actor.monster.turtle.default": {
		"texture_path": "res://assets/treasure_hunter/monsters/turtle_atlas.png",
		"frame_size": Vector2i(64, 64),
		"animations": {
			"idle": {"row": 0, "frames": [0, 1, 2, 3, 0], "duration": 0.7083333731, "loop": true},
			"move": {"row": 1, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.4583333135, "loop": true},
			"attack": {"row": 2, "frames": [0, 1, 2, 4, 4, 5], "duration": 0.6666666865, "loop": true},
			"death": {"row": 3, "frames": [0, 1, 2, 3, 4, 5], "duration": 0.75, "loop": false},
		},
	},
}

static var _cache: Dictionary = {}


static func has_asset(asset_id: String) -> bool:
	return DEFINITIONS.has(asset_id)


static func get_definition(asset_id: String) -> Dictionary:
	return DEFINITIONS.get(asset_id, {}).duplicate(true)


static func get_frames(asset_id: String) -> SpriteFrames:
	if _cache.has(asset_id):
		return _cache[asset_id]
	var definition: Dictionary = DEFINITIONS.get(asset_id, {})
	if definition.is_empty():
		return null
	var texture := load(String(definition["texture_path"])) as Texture2D
	if texture == null:
		return null
	var frame_size: Vector2i = definition["frame_size"]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var animations: Dictionary = definition["animations"]
	for animation_name in animations:
		var animation: Dictionary = animations[animation_name]
		var sequence: Array = animation["frames"]
		var duration := float(animation["duration"])
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, bool(animation["loop"]))
		frames.set_animation_speed(animation_name, float(sequence.size()) / duration)
		for frame_value in sequence:
			var coordinates: Vector2i
			if frame_value is Vector2i:
				coordinates = frame_value
			else:
				coordinates = Vector2i(int(frame_value), int(animation["row"]))
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = texture
			atlas_texture.region = Rect2(
				float(coordinates.x * frame_size.x),
				float(coordinates.y * frame_size.y),
				float(frame_size.x),
				float(frame_size.y),
			)
			frames.add_frame(animation_name, atlas_texture)
	_cache[asset_id] = frames
	return frames
