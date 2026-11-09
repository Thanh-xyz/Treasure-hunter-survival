class_name CompanionCatalog
extends RefCounted
## Pets and mounts from res://data/companions (brainstorm sheets 03 and 04, plan phase C).
##
##   pet key        = "<species>:<quality>"  (one record per species and quality)
##   pet stats      = species stats × quality multiplier × (1 + growth × (level − 1))
##   mount stats    = mount stats × (1 + growth × (level − 1)) × (1 + form_bonus × form)
##   evolution roll = chance by stones socketed after the new stone (sheet 04 §6.5)
##
## Pure and deterministic given an RNG: shared by offline play, the LAN host and tests.

const PETS_PATH := "res://data/companions/pets.json"
const MOUNTS_PATH := "res://data/companions/mounts.json"

static var _pets: Dictionary = {}
static var _mounts: Dictionary = {}


static func pets() -> Dictionary:
	if _pets.is_empty():
		_pets = _load(PETS_PATH)
	return _pets


static func mounts() -> Dictionary:
	if _mounts.is_empty():
		_mounts = _load(MOUNTS_PATH)
	return _mounts


static func _load(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


# --- pets ---------------------------------------------------------------------

static func qualities() -> Array:
	return pets().get("qualities", [])


static func species_ids() -> Array:
	return (pets().get("species", {}) as Dictionary).keys()


static func species(species_id: String) -> Dictionary:
	return (pets().get("species", {}) as Dictionary).get(species_id, {})


static func pet_key(species_id: String, quality: String) -> String:
	return "%s:%s" % [species_id, quality]


## {"species", "quality"} or {} for an invalid key.
static func parse_pet_key(key: String) -> Dictionary:
	var parts := key.split(":")
	if parts.size() != 2 or species(parts[0]).is_empty() or not parts[1] in qualities():
		return {}
	return {"species": parts[0], "quality": parts[1]}


static func is_pet_key(key: String) -> bool:
	return not parse_pet_key(key).is_empty()


static func pet_name(key: String) -> String:
	var p := parse_pet_key(key)
	return "%s (%s)" % [species(p["species"]).get("name", p["species"]), String(p["quality"]).capitalize()] if not p.is_empty() else key


static func quality_color(quality: String) -> Color:
	return Color(String((pets().get("quality_color", {}) as Dictionary).get(quality, "ffffff")))


static func pet_max_level() -> int:
	return int(pets().get("max_level", 10))


## Diamonds to go from `level` to `level + 1`, or -1 at the cap.
static func pet_level_cost(level: int) -> int:
	var costs: Array = pets().get("level_cost_diamonds", [])
	return int(costs[level - 1]) if level >= 1 and level < pet_max_level() and level - 1 < costs.size() else -1


static func duplicate_diamonds(quality: String) -> int:
	return int((pets().get("duplicate_diamonds", {}) as Dictionary).get(quality, 0))


static func pet_stats(key: String, level: int) -> Dictionary:
	var p := parse_pet_key(key)
	if p.is_empty():
		return {}
	var mult := float((pets().get("quality_multiplier", {}) as Dictionary).get(p["quality"], 1.0))
	var growth := 1.0 + float(pets().get("growth_per_level", 0.0)) * float(clampi(level, 1, pet_max_level()) - 1)
	var unscaled: Array = pets().get("unscaled_stats", [])
	var out := {}
	var base: Dictionary = species(p["species"]).get("stats", {})
	for stat: String in base:
		out[stat] = float(base[stat]) if stat in unscaled else float(base[stat]) * mult * growth
	return out


static func egg_ids() -> Array:
	return (pets().get("eggs", {}) as Dictionary).keys()


static func egg(egg_id: String) -> Dictionary:
	return (pets().get("eggs", {}) as Dictionary).get(egg_id, {})


## {"species", "quality", "key"} for one hatch, or {} for an unknown egg.
static func roll_egg(egg_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var e := egg(egg_id)
	if e.is_empty():
		return {}
	var sp := _weighted(e.get("species", {}), rng)
	var q := _weighted(e.get("quality", {}), rng)
	if sp.is_empty() or q.is_empty():
		return {}
	return {"species": sp, "quality": q, "key": pet_key(sp, q)}


## Shown in the hatch UI: [{"label", "percent"}] for species then quality.
static func egg_odds(egg_id: String) -> Dictionary:
	var e := egg(egg_id)
	return {"species": _percentages(e.get("species", {})), "quality": _percentages(e.get("quality", {}))}


# --- mounts -------------------------------------------------------------------

static func mount_ids() -> Array:
	return (mounts().get("mounts", {}) as Dictionary).keys()


static func mount(mount_id: String) -> Dictionary:
	return (mounts().get("mounts", {}) as Dictionary).get(mount_id, {})


static func mount_max_level() -> int:
	return int(mounts().get("max_level", 10))


static func mount_max_form() -> int:
	return int(mounts().get("max_form", 3))


static func mount_level_cost(level: int) -> int:
	var costs: Array = mounts().get("level_cost_diamonds", [])
	return int(costs[level - 1]) if level >= 1 and level < mount_max_level() and level - 1 < costs.size() else -1


static func form_name(form: int) -> String:
	var names: Array = mounts().get("form_names", [])
	return str(names[form]) if form >= 0 and form < names.size() else "Form %d" % form


static func mount_stats(mount_id: String, level: int, form: int) -> Dictionary:
	var m := mount(mount_id)
	if m.is_empty():
		return {}
	var growth := 1.0 + float(mounts().get("growth_per_level", 0.0)) * float(clampi(level, 1, mount_max_level()) - 1)
	var form_mult := 1.0 + float(mounts().get("form_bonus", 0.0)) * float(clampi(form, 0, mount_max_form()))
	var out := {}
	var base: Dictionary = m.get("stats", {})
	for stat: String in base:
		out[stat] = float(base[stat]) * growth * form_mult
	return out


## Speed multiplier while riding: forms add a little on top of the mount's base.
static func mount_speed_mult(mount_id: String, form: int) -> float:
	var base := float(mount(mount_id).get("speed_mult", 1.0))
	return base + float(mounts().get("form_bonus", 0.0)) * 0.5 * float(clampi(form, 0, mount_max_form()))


## Chance that socketing a stone evolves the mount, given stones socketed after the new one.
static func evolution_chance(socketed_after: int, form: int) -> float:
	if form >= mount_max_form():
		return 0.0
	for row: Variant in mounts().get("evolution_chance", []):
		if socketed_after >= int(row[0]):
			return float(row[1])
	return 0.0


static func stomp() -> Dictionary:
	return mounts().get("stomp", {})


# --- shared -------------------------------------------------------------------

static func _weighted(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0
	for k: String in weights:
		total += maxi(int(weights[k]), 0)
	if total <= 0:
		return ""
	var roll := rng.randi_range(1, total)
	for k: String in weights:
		roll -= maxi(int(weights[k]), 0)
		if roll <= 0:
			return k
	return ""


static func _percentages(weights: Dictionary) -> Array:
	var total := 0.0
	for k: String in weights:
		total += maxf(float(weights[k]), 0.0)
	var out: Array = []
	for k: String in weights:
		if float(weights[k]) > 0.0 and total > 0.0:
			out.append({"id": k, "percent": 100.0 * float(weights[k]) / total})
	return out


static func validate() -> Array[String]:
	var errors: Array[String] = []
	if species_ids().size() != 12:
		errors.append("expected 12 pet species, got %d" % species_ids().size())
	if qualities() != ["common", "uncommon", "epic", "legendary"]:
		errors.append("pet qualities must be common/uncommon/epic/legendary")
	if (pets().get("level_cost_diamonds", []) as Array).size() != pet_max_level() - 1:
		errors.append("pet level costs must cover levels 1..%d" % (pet_max_level() - 1))
	for sp: String in species_ids():
		if not MonsterVisualCatalog.has_asset(str(species(sp).get("art", ""))):
			errors.append("pet %s art %s is not in the visual catalog" % [sp, species(sp).get("art", "")])
	for egg_id: String in egg_ids():
		for sp: String in (egg(egg_id).get("species", {}) as Dictionary):
			if species(sp).is_empty():
				errors.append("%s hatches unknown species %s" % [egg_id, sp])
		if ItemDatabase.get_item(egg_id) == null:
			errors.append("egg %s has no item" % egg_id)
	if not is_pet_key(str(pets().get("starter", ""))):
		errors.append("starter pet key is invalid")
	if mount_ids().size() != 10:
		errors.append("expected 10 mounts, got %d" % mount_ids().size())
	if (mounts().get("level_cost_diamonds", []) as Array).size() != mount_max_level() - 1:
		errors.append("mount level costs must cover levels 1..%d" % (mount_max_level() - 1))
	for m_id: String in mount_ids():
		var m := mount(m_id)
		if not MonsterVisualCatalog.has_asset(str(m.get("art", ""))):
			errors.append("mount %s art is not in the visual catalog" % m_id)
		if (m.get("skins", []) as Array).is_empty():
			errors.append("mount %s needs at least one skin" % m_id)
		for skin: Dictionary in m.get("skins", []):
			if skin.has("art") and not MonsterVisualCatalog.has_asset(str(skin["art"])):
				errors.append("mount %s skin art %s missing" % [m_id, skin["art"]])
	return errors
