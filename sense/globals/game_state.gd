extends Node
## GameState — the local player profile (autoload).
##
## Owns the single character's collection (pets, mounts), homestead buildings and
## counters. There is no player level or XP (owner decision 2026-11-08, save v7): power comes
## from equipment, socket stones, pets and mounts. Gold and items live in the player's InventoryData;
## helpers here (can_afford / spend / grant) operate on it.
##
## Everything here is plain data so SaveService can serialize it as JSON.

signal collection_changed
signal pet_changed(pet_id: String)
signal mount_changed(mount_id: String, mounted: bool)
signal buildings_changed
signal stats_dirty   ## Something that affects player stats changed

const PLOT_COUNT := 6

var pets: Dictionary = {}          ## "<species>:<quality>" -> {"level": int, "gems": Array[String](8)}
var active_pet: String = ""        ## a pet key
var mounts: Dictionary = {}        ## mount_id -> {"skin", "skins", "level", "form", "gems"}
var active_mount: String = ""
var mounted: bool = false          ## runtime only (not saved)
var plots: Array = []              ## index -> {} or {"id","level","last_collect"}
var boss_kills: Dictionary = {}
## Boss encounter ids already rewarded on this profile (sheet 06 §8.4): a reconnect or a reload
## can never pay the same encounter twice. Newest last, capped.
var boss_claims: Array = []
const BOSS_CLAIMS_CAP := 200
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
	pets = {str(CompanionCatalog.pets().get("starter", "ember_fox:common")): _new_pet_record()}
	active_pet = ""
	mounts = {}
	active_mount = ""
	mounted = false
	plots = []
	for i in range(PLOT_COUNT):
		plots.append({})
	boss_kills = {}
	boss_claims = []
	kills_total = 0
	current_zone = "town"
	_apply_runtime_settings()


# =============================================================================
# SERIALIZATION
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"pets": pets, "active_pet": active_pet,
		"mounts": mounts, "active_mount": active_mount,
		"plots": plots, "boss_kills": boss_kills, "boss_claims": boss_claims, "kills_total": kills_total,
		"current_zone": current_zone, "settings": settings,
	}


func from_dict(d: Dictionary) -> void:
	reset_profile()
	pets = {}
	var raw_pets: Dictionary = d.get("pets", {})
	for key in raw_pets:
		if not CompanionCatalog.is_pet_key(str(key)):
			continue
		var pet_entry: Dictionary = raw_pets[key]
		var pet_record := _new_pet_record()
		pet_record["level"] = clampi(int(pet_entry.get("level", 1)), 1, CompanionCatalog.pet_max_level())
		pet_record["gems"] = _read_sockets(pet_entry.get("gems", []))
		pets[str(key)] = pet_record
	active_pet = str(d.get("active_pet", ""))
	if active_pet != "" and not pets.has(active_pet):
		active_pet = ""
	mounts = {}
	var raw_mounts: Dictionary = d.get("mounts", {})
	for m_id in raw_mounts:
		if CompanionCatalog.mount(str(m_id)).is_empty():
			continue
		var entry: Dictionary = raw_mounts[m_id]
		var skins: Array = []
		for s in entry.get("skins", [0]):
			skins.append(int(s))
		var mount_record := _new_mount_record()
		mount_record["skin"] = int(entry.get("skin", 0))
		mount_record["skins"] = skins
		mount_record["level"] = clampi(int(entry.get("level", 1)), 1, CompanionCatalog.mount_max_level())
		mount_record["form"] = clampi(int(entry.get("form", 0)), 0, CompanionCatalog.mount_max_form())
		mount_record["gems"] = _read_sockets(entry.get("gems", []))
		mounts[str(m_id)] = mount_record
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
	boss_claims = []
	for claim: Variant in d.get("boss_claims", []):
		boss_claims.append(str(claim))
	kills_total = int(d.get("kills_total", 0))
	current_zone = str(d.get("current_zone", "town"))
	var s: Dictionary = d.get("settings", {})
	for k in s:
		settings[k] = s[k]
	_apply_runtime_settings()
	_emit_all()


func _apply_runtime_settings() -> void:
	Engine.max_fps = clampi(int(settings.get("max_fps", 60)), 30, 120)


func _read_sockets(raw: Variant) -> Array:
	var sockets := Array(GemCatalog.empty_sockets())
	if raw is Array:
		for i in range(mini((raw as Array).size(), sockets.size())):
			sockets[i] = str(raw[i])
	return sockets


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
	pet_changed.emit(active_pet)
	mount_changed.emit(active_mount, mounted)
	collection_changed.emit()
	buildings_changed.emit()
	stats_dirty.emit()


# =============================================================================
# STATS AGGREGATION
# =============================================================================

## Combined base stats from the character + pet + mount + buildings.
## Equipment, socket stones and timed buffs are layered on top by CharacterStats itself.
func compute_base_stats() -> Dictionary:
	var base: Dictionary = GameContent.PLAYER_BASE
	var hp: float = float(base["hp"])
	var atk: float = float(base["atk"])
	var def: float = float(base["def"])
	var spd: float = float(base["spd"])
	# Pet (always) and mount (while riding) stats; their Guardian Stones add DEF here too.
	var companion := active_companion_stats()
	hp += float(companion.get("hp", 0.0))
	atk += float(companion.get("atk", 0.0))
	def += float(companion.get("def", 0.0))
	def += float(GemCatalog.total_stats(active_companion_sockets()).get("defense", 0.0))
	spd += float(companion.get("spd", 0.0))
	var gold_pct := float(companion.get("gold_pct", 0.0))
	var magnet := float(companion.get("magnet", 0.0))

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
	if mounted and active_mount != "" and mounts.has(active_mount):
		speed_mult = CompanionCatalog.mount_speed_mult(active_mount, mount_form(active_mount)) + mount_pct

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
# ECONOMY HELPERS (currencies + items live in player's inventory)
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


func get_diamonds() -> int:
	var inv := get_inventory()
	return inv.diamonds if inv else 0


## cost: {"gold": int, "diamonds": int, "<item_id>": int, ...}
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
		elif key == "diamonds":
			if inv.diamonds < amount:
				return false
		elif inv.get_item_count(key) < amount:
			return false
	return true


func spend(cost: Dictionary) -> bool:
	var inv := get_inventory()
	if inv == null:
		return false
	var removals: Array[Dictionary] = []
	var gold_cost := 0
	var diamond_cost := 0
	for key in cost:
		var amount: int = cost[key]
		if amount <= 0:
			continue
		if key == "gold":
			gold_cost += amount
		elif key == "diamonds":
			diamond_cost += amount
		else:
			var item: ItemData = ItemDatabase.get_item(key)
			if item == null:
				return false
			removals.append({"item": item, "quantity": amount})
	return inv.transact(removals, [], -gold_cost, -diamond_cost)


## rewards: {"gold": int, "diamonds": int, "items": {id: qty},
##           (equipment is granted as ordinary items)}
## Item and exact equipment rewards are all-or-nothing.
func grant(rewards: Dictionary) -> bool:
	var inv := get_inventory()
	var items: Dictionary = rewards.get("items", {})
	if rewards.has("equipment"):
		return false  # reference-card equipment rewards were retired in save v6
	if inv == null and (not items.is_empty() or rewards.has("gold") or rewards.has("diamonds")):
		return false
	var gold_reward := int(rewards.get("gold", 0))
	var diamond_reward := int(rewards.get("diamonds", 0))
	if gold_reward < 0 or diamond_reward < 0:
		return false
	var additions: Array[Dictionary] = []
	for item_id in items:
		var item: ItemData = ItemDatabase.get_item(item_id)
		var quantity := int(items[item_id])
		if item == null or quantity <= 0:
			return false
		additions.append({"item": item, "quantity": quantity})
	if inv != null and not inv.transact([], additions, gold_reward, diamond_reward):
		return false
	return true


func format_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in cost:
		var amount: int = cost[key]
		if amount <= 0:
			continue
		if key == "gold":
			parts.append("%d gold" % amount)
		elif key == "diamonds":
			parts.append("%d diamonds" % amount)
		else:
			var item: ItemData = ItemDatabase.get_item(key)
			parts.append("%d %s" % [amount, item.name if item else key])
	return ", ".join(parts) if not parts.is_empty() else "free"


# =============================================================================
# PETS — stat-only companions (brainstorm sheet 03, plan phase C). Keys are
# "<species>:<quality>"; levels cost diamonds; duplicates become diamonds.
# =============================================================================

func _new_pet_record() -> Dictionary:
	return {"level": 1, "gems": Array(GemCatalog.empty_sockets())}


func equip_pet(key: String) -> void:
	if key != "" and not pets.has(key):
		return
	active_pet = key
	pet_changed.emit(key)
	stats_dirty.emit()


## Hatch one egg from the bag. One transaction: the egg is consumed and either the new pet is
## added or (duplicate) its diamonds are paid. Returns {} on failure, else
## {"key", "species", "quality", "duplicate": bool, "diamonds": int}.
func hatch_egg(egg_id: String, rng: RandomNumberGenerator = null) -> Dictionary:
	var inv := get_inventory()
	var egg_item := ItemDatabase.get_item(egg_id)
	if inv == null or egg_item == null or CompanionCatalog.egg(egg_id).is_empty() or inv.get_item_count(egg_id) <= 0:
		return {}
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var rolled := CompanionCatalog.roll_egg(egg_id, rng)
	if rolled.is_empty():
		return {}
	var key: String = rolled["key"]
	var duplicate := pets.has(key)
	var diamonds := CompanionCatalog.duplicate_diamonds(rolled["quality"]) if duplicate else 0
	if not inv.transact([{"item": egg_item, "quantity": 1}], [], 0, diamonds):
		return {}
	if not duplicate:
		pets[key] = _new_pet_record()
		if active_pet == "":
			equip_pet(key)
	collection_changed.emit()
	GameEvent.pet_hatched.emit(key, duplicate, diamonds)
	return {"key": key, "species": rolled["species"], "quality": rolled["quality"], "duplicate": duplicate, "diamonds": diamonds}


## Buy an egg into the bag (pet menu shop). Price comes from data.
func buy_egg(egg_id: String) -> bool:
	var e := CompanionCatalog.egg(egg_id)
	var inv := get_inventory()
	var egg_item := ItemDatabase.get_item(egg_id)
	if e.is_empty() or inv == null or egg_item == null:
		return false
	var price: Dictionary = e.get("price", {})
	if not can_afford(price):
		return false
	return inv.transact([], [{"item": egg_item, "quantity": 1}], -int(price.get("gold", 0)), -int(price.get("diamonds", 0)))


func pet_level(key: String) -> int:
	return int(pets.get(key, {}).get("level", 0))


func level_up_pet(key: String) -> bool:
	if not pets.has(key):
		return false
	var cost := CompanionCatalog.pet_level_cost(pet_level(key))
	if cost < 0 or not spend({"diamonds": cost}):
		return false
	pets[key]["level"] = pet_level(key) + 1
	collection_changed.emit()
	if key == active_pet:
		stats_dirty.emit()
	return true


func max_pet_level() -> int:
	var best := 0
	for key in pets:
		best = maxi(best, int(pets[key].get("level", 1)))
	return best


# =============================================================================
# MOUNTS (brainstorm sheet 04): diamond levels, 8 stones, form evolution 0–3.
# =============================================================================

func _new_mount_record() -> Dictionary:
	return {"skin": 0, "skins": [0], "level": 1, "form": 0, "gems": Array(GemCatalog.empty_sockets())}


func unlock_mount(id: String) -> bool:
	if mounts.has(id) or CompanionCatalog.mount(id).is_empty():
		return false
	var unlock: Dictionary = CompanionCatalog.mount(id).get("unlock", {})
	if not spend({"gold": int(unlock.get("gold", 0)), "diamonds": int(unlock.get("diamonds", 0))}):
		return false
	mounts[id] = _new_mount_record()
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


func mount_level(id: String) -> int:
	return int(mounts.get(id, {}).get("level", 0))


func mount_form(id: String) -> int:
	return int(mounts.get(id, {}).get("form", 0))


func level_up_mount(id: String) -> bool:
	if not mounts.has(id):
		return false
	var cost := CompanionCatalog.mount_level_cost(mount_level(id))
	if cost < 0 or not spend({"diamonds": cost}):
		return false
	mounts[id]["level"] = mount_level(id) + 1
	collection_changed.emit()
	if id == active_mount:
		stats_dirty.emit()
	return true


## The skin entry in use: {"name", "tint"?, "art"?}.
func mount_skin(id: String) -> Dictionary:
	var skins: Array = CompanionCatalog.mount(id).get("skins", [])
	if skins.is_empty():
		return {}
	return skins[clampi(int(mounts.get(id, {}).get("skin", 0)), 0, skins.size() - 1)]


func buy_or_select_skin(id: String, skin_index: int) -> bool:
	var skins: Array = CompanionCatalog.mount(id).get("skins", [])
	if not mounts.has(id) or skin_index < 0 or skin_index >= skins.size():
		return false
	var owned: Array = mounts[id]["skins"]
	var has := false
	for owned_index: Variant in owned:
		has = has or int(owned_index) == skin_index
	if not has:
		if not spend({"gold": int((skins[skin_index] as Dictionary).get("cost", 0))}):
			return false
		owned.append(skin_index)
	mounts[id]["skin"] = skin_index
	collection_changed.emit()
	mount_changed.emit(active_mount, mounted)
	return true


# =============================================================================
# COMPANION SOCKET STONES — pets and mounts share the equipment stone system.
# kind = "pet" | "mount"; id = pet key or mount id.
# =============================================================================

func _companion_record(kind: String, id: String) -> Dictionary:
	if kind == "pet":
		return pets.get(id, {})
	if kind == "mount":
		return mounts.get(id, {})
	return {}


func companion_sockets(kind: String, id: String) -> Array[String]:
	var sockets := GemCatalog.empty_sockets()
	var raw: Array = _companion_record(kind, id).get("gems", [])
	for i in range(mini(raw.size(), sockets.size())):
		sockets[i] = str(raw[i])
	return sockets


## Socket the stone at inventory_index into a pet or mount. Mounts may evolve (sheet 04 §6):
## returns {"ok": bool, "evolved": bool, "form": int}.
func socket_companion_gem(kind: String, id: String, gem_index: int, inventory_index: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var record := _companion_record(kind, id)
	var inv := get_inventory()
	if record.is_empty() or inv == null or gem_index < 0 or gem_index >= GemCatalog.slots_per_holder():
		return {"ok": false}
	var sockets := companion_sockets(kind, id)
	var stone: ItemData = inv.get_item_at(inventory_index).get("item")
	if stone == null or not stone.is_gem() or not sockets[gem_index].is_empty():
		return {"ok": false}
	var simulated := inv._copy_slots(inv.inventory_slots)
	if not inv._remove_at_from_slots(simulated, inventory_index, 1):
		return {"ok": false}
	sockets[gem_index] = stone.id
	inv.inventory_slots = simulated
	record["gems"] = Array(sockets)
	var result := {"ok": true, "evolved": false, "form": int(record.get("form", 0))}
	if kind == "mount":
		if rng == null:
			rng = RandomNumberGenerator.new()
			rng.randomize()
		var filled := 0
		for s_id: String in sockets:
			if not s_id.is_empty():
				filled += 1
		if rng.randf() < CompanionCatalog.evolution_chance(filled, int(record.get("form", 0))):
			record["form"] = int(record.get("form", 0)) + 1
			result["evolved"] = true
			result["form"] = record["form"]
			GameEvent.mount_evolved.emit(id, int(record["form"]))
			mount_changed.emit(active_mount, mounted)
	inv.inventory_changed.emit()
	collection_changed.emit()
	stats_dirty.emit()
	return result


## Return a socketed stone to the bag; fails (nothing lost) when the bag is full.
## Evolution is never undone by removing stones.
func unsocket_companion_gem(kind: String, id: String, gem_index: int) -> bool:
	var record := _companion_record(kind, id)
	var inv := get_inventory()
	if record.is_empty() or inv == null or gem_index < 0 or gem_index >= GemCatalog.slots_per_holder():
		return false
	var sockets := companion_sockets(kind, id)
	var stone := ItemDatabase.get_item(sockets[gem_index]) if not sockets[gem_index].is_empty() else null
	if stone == null:
		return false
	if not inv.transact([], [{"item": stone, "quantity": 1}]):
		return false
	sockets[gem_index] = ""
	record["gems"] = Array(sockets)
	collection_changed.emit()
	stats_dirty.emit()
	return true


## Socket arrays that count right now: the active pet always, the mount only while riding.
func active_companion_sockets() -> Array:
	var arrays: Array = []
	if active_pet != "" and pets.has(active_pet):
		arrays.append(companion_sockets("pet", active_pet))
	if mounted and active_mount != "" and mounts.has(active_mount):
		arrays.append(companion_sockets("mount", active_mount))
	return arrays


## Pet and mount stats right now (pet always, mount while riding), summed by stat key.
func active_companion_stats() -> Dictionary:
	var total := {}
	if active_pet != "" and pets.has(active_pet):
		_add_stats(total, CompanionCatalog.pet_stats(active_pet, pet_level(active_pet)))
	if mounted and active_mount != "" and mounts.has(active_mount):
		_add_stats(total, CompanionCatalog.mount_stats(active_mount, mount_level(active_mount), mount_form(active_mount)))
	return total


func _add_stats(into: Dictionary, add: Dictionary) -> void:
	for k: String in add:
		into[k] = float(into.get(k, 0.0)) + float(add[k])


## Combat modifiers from pet/mount stats as passive-effect entries (crit, dodge, fire, ...).
## Their socket stones are added by InventoryData.get_all_gem_passive_effects(active_companion_sockets()).
func companion_passive_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var totals := active_companion_stats()
	for stat: String in InventoryData.GEM_EFFECTS:
		var value := float(totals.get(stat, 0.0))
		if value > 0.0:
			effects.append({"effect": InventoryData.GEM_EFFECTS[stat], "value": value})
	return effects


# =============================================================================
# BOSSES (brainstorm sheet 06, plan phase E)
# =============================================================================

func has_claimed(encounter_id: String) -> bool:
	return encounter_id in boss_claims


## Pay one encounter's rewards to this profile exactly once. Items that do not fit drop at the
## player's feet (never lost). Returns false when the encounter was already claimed.
func grant_boss_rewards(encounter_id: String, rewards: Array) -> bool:
	if encounter_id.is_empty() or has_claimed(encounter_id):
		return false
	boss_claims.append(encounter_id)
	while boss_claims.size() > BOSS_CLAIMS_CAP:
		boss_claims.pop_front()
	var inv := get_inventory()
	var player := get_player() as Node2D
	for r: Variant in rewards:
		if not r is Dictionary:
			continue
		var item := ItemDatabase.get_item(str(r.get("item_id", "")))
		var qty := int(r.get("quantity", 1))
		if item == null or qty <= 0:
			continue
		var left := inv.add_item(item, qty) if inv != null else qty
		if left > 0 and player != null:
			ItemSpawner.spawn_item(get_tree(), player.global_position, item.id, left, player.global_position)
		GameEvent.toast.emit("Boss reward: %s x%d" % [item.name, qty], Color(1.0, 0.85, 0.35))
	SaveService.save_game()
	return true


## Combine fragments into their card (sheet 06 §7.2). One transaction, no failure chance.
func combine_card_fragments(fragment_id: String) -> bool:
	var card_id := BossCatalog.card_for_fragment(fragment_id)
	var inv := get_inventory()
	if card_id.is_empty() or inv == null:
		return false
	var need := int(BossCatalog.card(card_id).get("fragments_needed", 0))
	var fragment := ItemDatabase.get_item(fragment_id)
	var card_item := ItemDatabase.get_item(card_id)
	if need <= 0 or fragment == null or card_item == null:
		return false
	return inv.transact([{"item": fragment, "quantity": need}], [{"item": card_item, "quantity": 1}])


## Use a Boss Summon Card where the player stands (sheet 06 §7.3). The card is consumed only
## after the boss has appeared. Returns "" on success or a reason for the player.
func use_boss_card(card_id: String) -> String:
	var c := BossCatalog.card(card_id)
	var inv := get_inventory()
	if c.is_empty() or inv == null or inv.get_item_count(card_id) <= 0:
		return "You have no %s." % c.get("name", card_id)
	if LanSession.mode == LanSession.Mode.CLIENT:
		return "Only the host can summon bosses in a Wi-Fi game for now."
	var map := get_tree().get_first_node_in_group("field_map") as FieldMap
	if map == null:
		return "Boss cards work out in the wild, not in town or dungeons."
	var region := str(map.cfg.get("region", ""))
	var regions: Array = c.get("regions", [])
	if not region in regions:
		return "This card only works in: %s." % ", ".join(regions)
	var boss := map.summon_card_boss(str(c.get("boss", "")))
	if boss == null:
		return "Another boss is already here."
	inv.transact([{"item": ItemDatabase.get_item(card_id), "quantity": 1}], [])
	return ""


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
	if cost.is_empty() or not can_afford(cost):
		return false
	# Preserve the old rate boundary: pending output must be collected before
	# changing level, and a full inventory must leave both cost and level intact.
	if not p.is_empty() and building_pending(plot_index) > 0:
		if collect_building(plot_index) <= 0:
			return false
	if not spend(cost):
		return false
	if p.is_empty():
		plots[plot_index] = {"id": building_id, "level": 1, "last_collect": _now()}
	else:
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
