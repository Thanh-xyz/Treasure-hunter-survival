class_name NpcPortraits
extends RefCounted
## Original NPC portraits (ASCII + ArtPalette). Asset IDs: "npc.<key>.portrait".

const PORTRAITS := {
	# Orla, Warden Captain of Hearthmoor: steel helm with ember plume, frost-blue tabard.
	"warden_captain": [
		"...............oo...............",
		"..............oyEo..............",
		"..............oyEo..............",
		".............oyEro..............",
		"..........oooooooooooo..........",
		".........osllllllllllSo.........",
		".........oslllllllllSso.........",
		".........osSSSSSSSSSSso.........",
		".........osooooooooooso.........",
		".........osTTTTTTTTTTso.........",
		".........osTToTTTToTTso.........",
		".........osTTTTTTTTTTso.........",
		".........osTTTTtTTTTTso.........",
		"..........oTnTTTTTTnTo..........",
		"..........onnnTrrTnnno..........",
		"..........onnnnnnnnnno..........",
		"...........onnnnnnnno...........",
		"............onnnnnno............",
		"........ooooooTTTToooooo........",
		"......ooSSSSSoTTTToSSSSSoo......",
		".....oSllllSSoFFFFoSSllllSo.....",
		"....oSlllllSSoFYYFoSSlllllSo....",
		"....oSSSSSSSSoFYYFoSSSSSSSSo....",
		"......oFFFFFFoFFFFoFFFFFFo......",
		"......oFfFFFFoFrrFoFFFFfFo......",
		"......ofFFFFFFFFFFFFFFFFFo......",
		"......offffffffffffffffffo......",
		"......oooooooooooooooooooo......",
	],
}

static var _cache: Dictionary = {}


static func keys() -> Array:
	return PORTRAITS.keys()


static func texture(key: String, scale: int = 1) -> Texture2D:
	var cache_key := "%s@%d" % [key, scale]
	if _cache.has(cache_key):
		return _cache[cache_key]
	if not PORTRAITS.has(key):
		return null
	var img := ArtPalette.image_from_rows(PORTRAITS[key])
	if scale > 1:
		img = ArtPalette.upscale(img, scale)
	var tex := ImageTexture.create_from_image(img)
	_cache[cache_key] = tex
	return tex
