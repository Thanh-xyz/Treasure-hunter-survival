extends Node
## GameState — the local player profile (autoload).
##
## Owns progression (level/XP), hero collection, pets, mounts, homestead
## buildings and counters. Gold and items live in the player's InventoryData;
## helpers here (can_afford / spend / grant) operate on it.
##
## Everything here is plain data so SaveService can serialize it as JSON.

signal xp_changed(level: int, xp: int, xp_needed: int)
signal leveled_up(new_level: int)
signal hero_changed(hero_id: String)
signal collection_changed
signal pet_changed(pet_id: String)
signal mount_changed(mount_id: String, mounted: bool)
signal buildings_changed
signal stats_dirty   ## Something that affects player stats changed

const PLOT_COUNT := 6

var level: int = 1
var xp: int = 0
var hero_id: String = "warden"
var heroes: Dictionary = {}        ## hero_id -> {"stars": int}
var pets: Dictionary = {}          ## pet_id -> {"level": int}
var active_pet: String = ""
var mounts: Dictionary = {}        ## mount_id -> {"skin": int, "skins": Array[int]}
var active_mount: String = ""
var mounted: bool = false          ## runtime only (not saved)
var plots: Array = []              ## index -> {} or {"id","level","last_collect"}
var boss_kills: Dictionary = {}
var kills_total: int = 0
var current_zone: String = "town"
var settings: Dictionary = {
	"joystick_opacity": 0.7,
	"left_handed": false,
	"damage_numbers": true,
	"compact_hud": false,
	"max_fps": 60,
}


func _ready() -> void:
	reset_profile()


## Fresh profile (new game)
func reset_profile() -> void:
	level = 1
	xp = 0
	hero_id = "warden"
	heroes = {"warden": {"stars": 1}}
	pets = {"ember_fox": {"level": 1}}
	active_pet = ""
	mounts = {}
	active_mount = ""
	mounted = false
	plots = []
	for i in range(PLOT_COUNT):
		plots.append({})
	boss_kills = {}
	kills_total = 0
	current_zone = "town"
	_apply_runtime_settings()


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"level": level, "xp": xp, "hero_id": hero_id, "heroes": heroes,
		"pets": pets, "active_pet": active_pet,
		"mounts": mounts, "active_mount": active_mount,
		"plots": plots, "boss_kills": boss_kills, "kills_total": kills_total,
		"current_zone": current_zone, "settings": settings,
	}


func from_dict(d: Dictionary) -> void:
	reset_profile()
	level = int(d.get("level", 1))
	xp = int(d.get("xp", 0))
	hero_id = str(d.get("hero_id", "warden"))
	heroes = _int_values(d.get("heroes", heroes))
	if not GameContent.HEROES.has(hero_id) or not heroes.has(hero_id):
		hero_id = "warden"
	pets = _int_values(d.get("pets", pets))
	active_pet = str(d.get("active_pet", ""))
	if active_pet != "" and not pets.has(active_pet):
		active_pet = ""
	mounts = {}
	var raw_mounts: Dictionary = d.get("mounts", {})
	for m_id in raw_mounts:
		if not GameContent.MOUNTS.has(m_id):
			continue
		var entry: Dictionary = raw_mounts[m_id]
		var skins: Array = []
		for s in entry.get("skins", [0]):
			skins.append(int(s))
		mounts[m_id] = {"skin": int(entry.get("skin", 0)), "skins": skins}
	active_mount = str(d.get("active_mount", ""))
	if active_mount != "" and not mounts.has(active_mount):
		active_mount = ""
	var raw_plots: Array = d.get("plots", [])
	for i in range(mini(raw_plots.size(), PLOT_COUNT)):
		var p: Dictionary = raw_plots[i]
		if p.is_empty() or not GameContent.BUILDINGS.has(p.get("id", "")):
			plots[i] = {}
		else:
			plots[i] = {"id": p["id"], "level": int(p.get("level", 1)), "last_collect": float(p.get("last_collect", _now()))}
	boss_kills = _int_values(d.get("boss_kills", {}))
	kills_total = int(d.get("kills_total", 0))
	current_zone = str(d.get("current_zone", "town"))
	var s: Dictionary = d.get("settings", {})
	for k in s:
		settings[k] = s[k]
	_apply_runtime_settings()
	_emit_all()


func _apply_runtime_settings() -> void:
	Engine.max_fps = clampi(int(settings.get("max_fps", 60)), 30, 120)


## JSON turns ints into floats; normalize nested numeric dictionaries.
func _int_values(src: Variant) -> Dictionary:
	var out := {}
	if not src is Dictionary:
		return out
	for k in src:
		var v: Variant = src[k]
		if v is Dictionary:
			var inner := {}
			for ik in v:
				var iv: Variant = v[ik]
				inner[ik] = int(iv) if (iv is float or iv is int) else iv
			out[k] = inner
		elif v is float:
			out[k] = int(v)
		else:
			out[k] = v
	return out


func _emit_all() -> void:
	xp_changed.emit(level, xp, xp_needed())
	hero_changed.emit(hero_id)
	pet_changed.emit(active_pet)
	mount_changed.emit(active_mount, mounted)
	collection_changed.emit()
	buildings_changed.emit()
	stats_dirty.emit()


# =============================================================================
# PROGRESSION
# =============================================================================

func xp_needed() -> int:
	return GameContent.xp_to_next(level)


func add_xp(amount: int) -> void:
	if amount <= 0 or level >= GameContent.MAX_LEVEL:
		return
	xp += amount
	var leveled := false
	while level < GameContent.MAX_LEVEL and xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		leveled = true
		leveled_up.emit(level)
	xp_changed.emit(level, xp, xp_needed())
	if leveled:
		stats_dirty.emit()


# =============================================================================
# STATS AGGREGATION
# =============================================================================

## Combined base stats from hero + level + stars + pet + mount + buildings.
## Equipment and timed buffs are layered on top by CharacterStats itself.
func compute_base_stats() -> Dictionary:
	var hero: Dictionary = GameContent.HEROES.get(hero_id, GameContent.HEROES["warden"])
	var base: Dictionary = hero["base"]
	var growth: Dictionary = hero["growth"]
	var lv := level - 1
	var stars: int = heroes.get(hero_id, {}).get("stars", 1)
	var star_mult: float = 1.0 + GameContent.HERO_STAR_BONUS * float(stars - 1)
	var hp: float = (float(base["hp"]) + growth["hp"] * lv) * star_mult
	var atk: float = (float(base["atk"]) + growth["atk"] * lv) * star_mult
	var def: float = (float(base["def"]) + growth["def"] * lv) * star_mult
	var spd: float = base["spd"]
	var gold_pct := 0.0
	var magnet := 0.0

	# Pet passive (scales +15% per pet level)
	if active_pet != "" and GameContent.PETS.has(active_pet):
		var pdef: Dictionary = GameContent.PETS[active_pet]
		var plv: int = pets.get(active_pet, {}).get("level", 1)
		var pscale := 1.0 + 0.15 * float(plv - 1)
		var passive: Dictionary = pdef.get("passive", {})
		hp += passive.get("hp", 0) * pscale
		atk += passive.get("atk", 0) * pscale
		def += passive.get("def", 0) * pscale
		spd += passive.get("spd", 0.0) * pscale
		gold_pct += passive.get("gold_pct", 0.0) * pscale
		magnet += passive.get("magnet", 0.0)

	# Buildings
	var mount_pct := 0.0
	for p in plots:
		if p.is_empty():
			continue
		var bdef: Dictionary = GameContent.BUILDINGS[p["id"]]
		var stat: Dictionary = bdef.get("stat", {})
		var blv: int = p["level"]
		if stat.has("atk"):
			atk += stat["atk"][blv]
		if stat.has("def"):
			def += stat["def"][blv]
		if stat.has("hp"):
			hp += stat["hp"][blv]
		if stat.has("mount_pct"):
			mount_pct += stat["mount_pct"][blv]

	# Mount
	var speed_mult := 1.0
	if mounted and active_mount != "" and GameContent.MOUNTS.has(active_mount):
		var mdef: Dictionary = GameContent.MOUNTS[active_mount]
		speed_mult = float(mdef["speed_mult"]) + mount_pct
		var bonus: Dictionary = mdef.get("bonus", {})
		atk += bonus.get("atk", 0)
		def += bonus.get("def", 0)
		hp += bonus.get("hp", 0)

	return {
		"hp": int(round(hp)), "atk": int(round(atk)), "def": int(round(def)),
		"spd": spd, "speed_mult": speed_mult, "gold_pct": gold_pct, "magnet": magnet,
	}


## Push computed stats into a CharacterStats resource
func apply_to_stats(stats: CharacterStats) -> void:
	if stats == null:
		return
	var s := compute_base_stats()
	var was_full := stats.current_health >= stats.max_health
	var ratio := float(stats.current_health) / float(maxi(stats.max_health, 1))
	stats.base_max_health = s["hp"]
	stats.base_attack_damage = s["atk"]
	stats.base_defense = s["def"]
	stats.base_move_speed = s["spd"]
	stats.speed_multiplier = s["speed_mult"]
	# Keep HP ratio when max HP changes (full stays full, dead stays dead)
	if stats.current_health <= 0:
		return
	stats.current_health = stats.max_health if was_full else int(round(ratio * stats.max_health))


# =============================================================================
# ECONOMY HELPERS (gold + items live in player's inventory)
# =============================================================================

func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func get_inventory() -> InventoryData:
	var p := get_player()
	if p != null and p.has_method("get_inventory"):
		return p.get_inventory()
	return null


func get_gold() -> int:
	var inv := get_inventory()
	return inv.gold if inv else 0


## cost: {"gold": int, "<item_id>": int, ...}
func can_afford(cost: Dictionary) -> bool:
	var inv := get_inventory()
	if inv == null:
		return false
	for key in cost:
		var amount: int = cost[key]
		if amount <= 0:
			continue
		if key == "gold":
			if inv.gold < amount:
				return false
		elif inv.get_item_count(key) < amount:
			return false
	return true


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	var inv := get_inventory()
	for key in cost:
		var amount: int = cost[key]
		if amount <= 0:
			continue
		if key == "gold":
			inv.gold -= amount
		else:
			var item: ItemData = ItemDatabase.get_item(key)
			if item:
				inv.remove_item(item, amount)
	return true


## rewards: {"xp": int, "gold": int, "items": {id: qty}}
## Item rewards are all-or-nothing so progression cannot consume a claim silently.
func grant(rewards: Dictionary) -> bool:
	var inv := get_inventory()
	var items: Dictionary = rewards.get("items", {})
	if inv == null and (not items.is_empty() or rewards.has("gold")):
		return false
	var additions: Array[Dictionary] = []
	for item_id in items:
		var item: ItemData = ItemDatabase.get_item(item_id)
		var quantity := int(items[item_id])
		if item == null or quantity <= 0:
			return false
		additions.append({"item": item, "quantity": quantity})
	if inv != null and not additions.is_empty() and not inv.transact_items([], additions):
		return false
	if rewards.has("xp"):
		add_xp(int(rewards["xp"]))
	if inv != null and rewards.has("gold"):
		inv.gold += int(rewards["gold"])
	return true


func format_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in cost:
		var amount: int = cost[key]
		if amount <= 0:
			continue
		if key == "gold":
			parts.append("%d gold" % amount)
		else:
			var item: ItemData = ItemDatabase.get_item(key)
			parts.append("%d %s" % [amount, item.name if item else key])
	return ", ".join(parts) if not parts.is_empty() else "free"


# =============================================================================
# HEROES
# =============================================================================

func is_hero_owned(id: String) -> bool:
	return heroes.has(id)


func unlock_hero(id: String) -> bool:
	if is_hero_owned(id) or not GameContent.HEROES.has(id):
		return false
	var unlock: Dictionary = GameContent.HEROES[id]["unlock"]
	if level < int(unlock.get("level", 1)):
		return false
	if not spend({"gold": int(unlock.get("gold", 0))}):
		return false
	heroes[id] = {"stars": 1}
	collection_changed.emit()
	return true


func select_hero(id: String) -> bool:
	if not is_hero_owned(id):
		return false
	hero_id = id
	hero_changed.emit(id)
	stats_dirty.emit()
	return true


func hero_star_cost(id: String) -> int:
	var stars: int = heroes.get(id, {}).get("stars", 1)
	if stars >= GameContent.HERO_MAX_STARS:
		return -1
	return GameContent.HERO_STAR_COST[stars]


func upgrade_hero_star(id: String) -> bool:
	var cost := hero_star_cost(id)
	if cost < 0 or not spend({"hero_shard": cost}):
		return false
	heroes[id]["stars"] = int(heroes[id]["stars"]) + 1
	collection_changed.emit()
	stats_dirty.emit()
	return true


func max_hero_stars() -> int:
	var best := 0
	for id in heroes:
		best = maxi(best, int(heroes[id].get("stars", 1)))
	return best


# =============================================================================
# PETS
# =============================================================================

func unlock_pet(id: String) -> bool:
	if pets.has(id) or not GameContent.PETS.has(id):
		return false
	if not spend({"gold": int(GameContent.PETS[id]["unlock"].get("gold", 0))}):
		return false
	pets[id] = {"level": 1}
	collection_changed.emit()
	return true


func equip_pet(id: String) -> void:
	if id != "" and not pets.has(id):
		return
	active_pet = id
	pet_changed.emit(id)
	stats_dirty.emit()


func pet_stage(id: String) -> int:
	var lv: int = pets.get(id, {}).get("level", 1)
	var stage := 0
	for threshold in GameContent.PET_EVOLVE_LEVELS:
		if lv >= threshold:
			stage += 1
	return stage


func level_up_pet(id: String) -> bool:
	if not pets.has(id):
		return false
	var lv: int = pets[id]["level"]
	if lv >= GameContent.PET_MAX_LEVEL:
		return false
	if not spend(GameContent.pet_level_cost(lv)):
		return false
	var old_stage := pet_stage(id)
	pets[id]["level"] = lv + 1
	collection_changed.emit()
	if id == active_pet:
		stats_dirty.emit()
		if pet_stage(id) != old_stage:
			pet_changed.emit(id)  # respawn with evolved visuals
	return true


func max_pet_level() -> int:
	var best := 0
	for id in pets:
		best = maxi(best, int(pets[id].get("level", 1)))
	return best


# =============================================================================
# MOUNTS
# =============================================================================

func unlock_mount(id: String) -> bool:
	if mounts.has(id) or not GameContent.MOUNTS.has(id):
		return false
	var unlock: Dictionary = GameContent.MOUNTS[id]["unlock"]
	if level < int(unlock.get("level", 1)):
		return false
	if not spend({"gold": int(unlock.get("gold", 0))}):
		return false
	mounts[id] = {"skin": 0, "skins": [0]}
	if active_mount == "":
		active_mount = id
	collection_changed.emit()
	mount_changed.emit(active_mount, mounted)
	return true


func select_mount(id: String) -> void:
	if not mounts.has(id):
		return
	active_mount = id
	collection_changed.emit()
	mount_changed.emit(active_mount, mounted)
	stats_dirty.emit()


func set_mounted(value: bool) -> void:
	if value and active_mount == "":
		return
	if mounted == value:
		return
	mounted = value
	mount_changed.emit(active_mount, mounted)
	stats_dirty.emit()


func mount_skin_palette(id: String) -> String:
	if not GameContent.MOUNTS.has(id):
		return ""
	var skins: Array = GameContent.MOUNTS[id]["skins"]
	var idx: int = mounts.get(id, {}).get("skin", 0)
	return skins[clampi(idx, 0, skins.size() - 1)]


func buy_or_select_skin(id: String, skin_index: int) -> bool:
	if not mounts.has(id):
		return false
	var owned: Array = mounts[id]["skins"]
	if not owned.has(skin_index):
		if not spend({"gold": int(GameContent.MOUNTS[id]["skin_cost"])}):
			return false
		owned.append(skin_index)
	mounts[id]["skin"] = skin_index
	collection_changed.emit()
	mount_changed.emit(active_mount, mounted)
	return true


# =============================================================================
# HOMESTEAD BUILDINGS
# =============================================================================

func building_level(building_id: String) -> int:
	for p in plots:
		if not p.is_empty() and p["id"] == building_id:
			return int(p["level"])
	return 0


func build_cost(plot_index: int, building_id: String) -> Dictionary:
	var current := 0
	var p: Dictionary = plots[plot_index]
	if not p.is_empty():
		current = int(p["level"])
	if current >= GameContent.BUILDING_MAX_LEVEL:
		return {}
	return GameContent.BUILDINGS[building_id]["cost"][current + 1]


## Build on an empty plot or upgrade the building already there
func build_or_upgrade(plot_index: int, building_id: String) -> bool:
	if plot_index < 0 or plot_index >= plots.size():
		return false
	var p: Dictionary = plots[plot_index]
	if p.is_empty():
		if building_level(building_id) > 0:
			return false  # one of each building
	elif p["id"] != building_id or int(p["level"]) >= GameContent.BUILDING_MAX_LEVEL:
		return false
	var cost := build_cost(plot_index, building_id)
	if cost.is_empty() or not spend(cost):
		return false
	if p.is_empty():
		plots[plot_index] = {"id": building_id, "level": 1, "last_collect": _now()}
	else:
		collect_building(plot_index)
		p["level"] = int(p["level"]) + 1
	buildings_changed.emit()
	stats_dirty.emit()
	GameEvent.building_built.emit(building_id, int(plots[plot_index]["level"]))
	return true


## Units produced and waiting to be collected
func building_pending(plot_index: int) -> int:
	var p: Dictionary = plots[plot_index]
	if p.is_empty():
		return 0
	var bdef: Dictionary = GameContent.BUILDINGS[p["id"]]
	if not bdef.has("produces"):
		return 0
	var hours: float = clampf((_now() - float(p["last_collect"])) / 3600.0, 0.0, GameContent.BUILDING_STORAGE_HOURS)
	return int(floor(hours * float(bdef["per_hour"][int(p["level"])])))


func collect_building(plot_index: int) -> int:
	var amount := building_pending(plot_index)
	var p: Dictionary = plots[plot_index]
	if p.is_empty():
		return 0
	if amount <= 0:
		return 0
	var bdef: Dictionary = GameContent.BUILDINGS[p["id"]]
	var items := {bdef["produces"]: amount}
	if bdef.has("bonus_item"):
		items[bdef["bonus_item"]] = maxi(1, amount / 10)
	if not grant({"items": items}):
		return 0
	p["last_collect"] = _now()
	buildings_changed.emit()
	return amount


func _now() -> float:
	return Time.get_unix_time_from_system()


# =============================================================================
# COUNTERS
# =============================================================================

func register_kill(monster_id: String, is_boss: bool) -> void:
	kills_total += 1
	if is_boss:
		boss_kills[monster_id] = int(boss_kills.get(monster_id, 0)) + 1
