extends Node
## Runtime provenance gate (dev mode).
##
## Complements tools/provenance/check_provenance.py: instead of scanning text, it asks Godot for
## the real dependency graph of every scene/resource under res://sense and reads the asset paths
## held by runtime catalogs. Every asset found must have a record in the schema-v2 manifest.
## Release-mode enforcement lives in the static gate (`--mode release`).

const MANIFEST_PATH := "res://docs/architecture/asset-manifest.json"
const ASSET_EXTENSIONS := ["png", "svg", "jpg", "jpeg", "webp", "ttf", "otf", "fnt", "wav", "ogg", "mp3"]
const STATUSES := ["original", "verified", "licence_pending", "unverified", "excluded"]

var _failures: Array[String] = []
var _records: Dictionary = {}          # target_path (no res://) -> status
var _found: Dictionary = {}            # target_path -> source description
var _visited: Dictionary = {}


func _ready() -> void:
	_load_manifest()
	if _failures.is_empty():
		_collect_scene_dependencies("res://sense")
		_collect_project_icon()
		_collect_monster_catalogs()
		_collect_item_icons()
		_check_found_assets()
		_check_pixel_art_sprites()
		_check_gate_detects_unrecorded()
	_finish()


func _load_manifest() -> void:
	var text := FileAccess.get_file_as_string(MANIFEST_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		_fail("manifest is missing or not valid JSON: %s" % MANIFEST_PATH)
		return
	if int(parsed.get("schema_version", 0)) != 2:
		_fail("manifest schema_version is not 2")
		return
	for record: Dictionary in parsed.get("assets", []):
		var status := str((record.get("provenance", {}) as Dictionary).get("status", ""))
		_check(status in STATUSES, "invalid status '%s' for %s" % [status, record.get("asset_id")])
		var target: Variant = record.get("target_path")
		if target is String and not (target as String).is_empty():
			_records[target] = status


func _collect_scene_dependencies(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		_fail("cannot open %s" % dir_path)
		return
	for sub in dir.get_directories():
		_collect_scene_dependencies(dir_path.path_join(sub))
	for file in dir.get_files():
		var path := dir_path.path_join(file)
		if file.ends_with(".tscn") or file.ends_with(".tres"):
			_walk_dependencies(path, path)
		elif file.ends_with(".gd"):
			_scan_script_literals(path)


func _walk_dependencies(path: String, root: String) -> void:
	if _visited.has(path):
		return
	_visited[path] = true
	for dep in ResourceLoader.get_dependencies(path):
		var dep_path := _dependency_path(dep)
		if dep_path.is_empty():
			continue
		if _is_asset(dep_path):
			_note(dep_path, "dependency of %s" % root)
		elif dep_path.ends_with(".tscn") or dep_path.ends_with(".tres"):
			_walk_dependencies(dep_path, root)


## Godot does not report `preload`/`load` targets of GDScript files as dependencies, so script
## sources are scanned for literal res:// asset paths.
func _scan_script_literals(path: String) -> void:
	var regex := RegEx.create_from_string("res://[^\"'\\s)]+\\.(%s)\\b" % "|".join(ASSET_EXTENSIONS))
	for match in regex.search_all(FileAccess.get_file_as_string(path)):
		_note(match.get_string(), "literal in %s" % path)


## Godot 4 dependency strings look like "uid://…::Type::res://path" or "res://path::Type".
func _dependency_path(dep: String) -> String:
	for part in dep.split("::"):
		if part.begins_with("res://"):
			return part
	if dep.begins_with("uid://"):
		var id := ResourceUID.text_to_id(dep.get_slice("::", 0))
		if ResourceUID.has_id(id):
			return ResourceUID.get_id_path(id)
	return ""


func _collect_project_icon() -> void:
	var icon := str(ProjectSettings.get_setting("application/config/icon", ""))
	if not icon.is_empty():
		_note(icon, "project.godot application/config/icon")


func _collect_monster_catalogs() -> void:
	for asset_id: String in MonsterVisualCatalog.DEFINITIONS:
		var definition: Dictionary = MonsterVisualCatalog.DEFINITIONS[asset_id]
		_note(str(definition.get("texture_path", "")), "MonsterVisualCatalog %s" % asset_id)
	for monster_id: String in GameContent.MONSTERS:
		var texture := str((GameContent.MONSTERS[monster_id] as Dictionary).get("texture", ""))
		if not texture.is_empty():
			_note(texture, "GameContent.MONSTERS %s" % monster_id)


func _collect_item_icons() -> void:
	for item_id: String in ItemDatabase.items:
		var item: ItemData = ItemDatabase.items[item_id]
		var icon: Texture2D = item.icon if item != null else null
		if icon == null:
			continue
		var path := icon.resource_path
		if path.is_empty() and icon is AtlasTexture and (icon as AtlasTexture).atlas != null:
			path = (icon as AtlasTexture).atlas.resource_path
		if not path.is_empty():
			_note(path, "ItemDatabase %s" % item_id)


func _note(path: String, source: String) -> void:
	if path.is_empty():
		return
	_check(not path.contains("assets-ths"), "%s loads from external assets-ths: %s" % [source, path])
	if _is_asset(path):
		_found[path.trim_prefix("res://")] = source


func _is_asset(path: String) -> bool:
	return path.get_extension().to_lower() in ASSET_EXTENSIONS


func _check_found_assets() -> void:
	_check(not _found.is_empty(), "no assets discovered; the dependency walk is broken")
	var counts := {}
	for status in STATUSES:
		counts[status] = 0
	for target: String in _missing_records(_found):
		_fail("unrecorded asset %s (%s)" % [target, _found[target]])
	for target: String in _found:
		if _records.has(target):
			counts[_records[target]] += 1
	print("[PROVENANCE TEST] %d runtime assets: %s" % [_found.size(), counts])


func _missing_records(found: Dictionary) -> Array[String]:
	var missing: Array[String] = []
	for target: String in found:
		if not _records.has(target):
			missing.append(target)
	return missing


## The gate must catch an unrecorded asset; prove it with a probe that never exists in the manifest.
func _check_gate_detects_unrecorded() -> void:
	var probe := {"assets/__provenance_probe__.png": "self-test"}
	_check(_missing_records(probe).size() == 1, "gate self-test: unrecorded probe was not detected")


func _check_pixel_art_sprites() -> void:
	_check(_records.has("sense/globals/pixel_art.gd"), "missing original record for PixelArt sprites")
	for sprite_id: String in PixelArt.SPRITES:
		_check(PixelArt.get_texture(sprite_id) != null, "PixelArt sprite %s failed to build" % sprite_id)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("[PROVENANCE TEST] " + message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PROVENANCE TEST] ALL PASSED")
		get_tree().quit(0)
		return
	print("[PROVENANCE TEST] %d FAILED" % _failures.size())
	get_tree().quit(1)
