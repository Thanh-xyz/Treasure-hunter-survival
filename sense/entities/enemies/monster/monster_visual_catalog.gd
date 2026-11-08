class_name MonsterVisualCatalog
extends RefCounted
## Runtime adapter from stable art IDs to data-driven monster SpriteFrames.

## Atlas-based monster art by stable asset ID. The reference-game atlases (snailu, turtle) were
## retired in save v6; current monsters use PixelArt sprites. New original atlases register here.
const DEFINITIONS := {}

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
