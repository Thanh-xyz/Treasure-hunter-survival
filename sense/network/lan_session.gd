extends Node
## Direct-IP LAN session. The host owns the active zone, player transform relay
## enemy simulation, player vitals and enemy-drop transactions.

signal status_changed(text: String, is_error: bool)
signal session_ready(role: String, host_zone: String)
signal session_ended(reason: String)
signal host_zone_requested(zone_id: String)

const PORT := 24567
const MAX_CLIENTS := 3
const PROTOCOL_VERSION := 7  # v7: socket stones, single character, no player level (save v7)
const SEND_INTERVAL := 0.05
const ZONE_INTERVAL := 1.0
const ENEMY_SEND_INTERVAL := 0.10
const MAX_ENEMY_BATCH := 96
const CLIENT_HIT_RANGE := 78.0
const CLIENT_HIT_COOLDOWN := 0.18
const CLIENT_BASE_DAMAGE := 10.0
const LOOT_PICKUP_RANGE := 64.0
const MAX_LOOT_QUANTITY := 9999
const LOOT_RESERVATION_TIMEOUT := 2.0
const PROFILE_INTERVAL := 0.5
const PLAYER_INVULNERABILITY := 0.5
const RESPAWN_INVULNERABILITY := 2.0
const MIN_PLAYER_HP := 20
const MAX_PLAYER_HP := 5000
const MAX_PLAYER_ATTACK := 5000
const MAX_PLAYER_DEFENSE := 500
const MAX_PLAYER_CRIT_BONUS := 100.0
const MAX_PLAYER_LIFE_STEAL := 100.0
const MAX_PLAYER_DODGE := 40.0
const MAX_PLAYER_CRIT_DAMAGE := 200.0
const MAX_PLAYER_REGEN := 50.0
const NETWORK_ITEM_SCENE := preload("res://sense/items/game_item.tscn")

enum Mode { OFFLINE, HOST, CLIENT }

var mode: Mode = Mode.OFFLINE
var local_player: Node2D = null
var world_root: Node = null
var peer_names: Dictionary = {}
var accepted_peers: Dictionary = {}
var peer_positions: Dictionary = {}
var remote_avatars: Dictionary = {}
var enemies: Dictionary = {}
var loot: Dictionary = {}
var player_states: Dictionary = {}

var _send_left: float = 0.0
var _zone_left: float = 0.0
var _enemy_send_left: float = 0.0
var _last_facing := Vector2.DOWN
var _joining: bool = false
var _next_enemy_id: int = 1
var _enemy_hit_times: Dictionary = {}
var _next_loot_id: int = 1
var _next_transaction_id: int = 1
var _applied_transactions: Dictionary = {}
var _earned_rewards: Array[Dictionary] = []
var _pending_loot_transactions: Dictionary = {}
var _loot_reservations: Dictionary = {}
var _next_consumable_request_id: int = 1
var _pending_consumable_requests: Dictionary = {}
var _resolved_consumable_requests: Dictionary = {}
var _profile_send_left: float = 0.0
var _peer_damage_times: Dictionary = {}
var _peer_respawn_until: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func bind(root: Node, player: Node2D) -> void:
	world_root = root
	local_player = player


func start_host() -> Error:
	stop(false)
	_earned_rewards.clear()
	_applied_transactions.clear()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		_set_status("Không thể mở UDP %d: %s" % [PORT, error_string(err)], true)
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.HOST
	peer_names[1] = "Guest_Host"
	accepted_peers[1] = true
	_capture_host_player_state()
	_adopt_existing_enemies()
	_set_status("Đang host tại UDP %d" % PORT, false)
	session_ready.emit("host", GameState.current_zone)
	return OK


func join_host(address: String) -> Error:
	var clean := address.strip_edges().left(128)
	if clean == "" or clean.contains(" "):
		_set_status("IP hoặc hostname không hợp lệ", true)
		return ERR_INVALID_PARAMETER
	stop(false)
	_earned_rewards.clear()
	_applied_transactions.clear()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(clean, PORT)
	if err != OK:
		_set_status("Không thể kết nối %s:%d: %s" % [clean, PORT, error_string(err)], true)
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	_joining = true
	_clear_local_enemies()
	_set_status("Đang kết nối %s:%d..." % [clean, PORT], false)
	return OK


func stop(emit_end: bool = true, reason: String = "Đã ngắt Wi-Fi") -> void:
	var was_active := mode != Mode.OFFLINE or _joining
	_joining = false
	mode = Mode.OFFLINE
	accepted_peers.clear()
	peer_names.clear()
	peer_positions.clear()
	_clear_remote_avatars()
	_clear_enemy_registry()
	_clear_loot_registry()
	player_states.clear()
	_enemy_hit_times.clear()
	_peer_damage_times.clear()
	_peer_respawn_until.clear()
	_pending_loot_transactions.clear()
	_loot_reservations.clear()
	_pending_consumable_requests.clear()
	_resolved_consumable_requests.clear()
	_next_consumable_request_id = 1
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if emit_end and was_active:
		session_ended.emit(reason)


func is_active() -> bool:
	return mode != Mode.OFFLINE


func is_host() -> bool:
	return mode == Mode.HOST


func role_text() -> String:
	match mode:
		Mode.HOST:
			return "Host Wi-Fi :%d" % PORT
		Mode.CLIENT:
			return "Client Wi-Fi :%d" % PORT
		_:
			return "Local"


func short_role_text() -> String:
	match mode:
		Mode.HOST:
			return "[Host]"
		Mode.CLIENT:
			return "[Client]"
		_:
			return "[Local]"


func local_addresses_text() -> String:
	var values: Array[String] = []
	for address: String in IP.get_local_addresses():
		if address.contains(":") or address.begins_with("127.") or address.begins_with("169.254."):
			continue
		values.append(address)
	return ", ".join(values) if not values.is_empty() else "Không tìm thấy IPv4 LAN"


func _process(delta: float) -> void:
	if mode == Mode.OFFLINE or local_player == null:
		return
	if mode == Mode.HOST:
		_regenerate_peers(delta)
	if mode == Mode.CLIENT:
		for value: Variant in loot.values():
			var item := value as GameItem
			if item and is_instance_valid(item):
				item.visible = item.network_zone_id == GameState.current_zone
	_profile_send_left -= delta
	if _profile_send_left <= 0.0:
		_profile_send_left = PROFILE_INTERVAL
		if mode == Mode.CLIENT and not _joining:
			_send_local_combat_profile()
		elif mode == Mode.HOST:
			_capture_host_player_state()
	_send_left -= delta
	if _send_left <= 0.0:
		_send_left = SEND_INTERVAL
		_send_local_snapshot()
	if mode == Mode.HOST:
		_expire_loot_reservations()
		_zone_left -= delta
		if _zone_left <= 0.0:
			_zone_left = ZONE_INTERVAL
			_sync_host_zone.rpc(GameState.current_zone)
		_enemy_send_left -= delta
		if _enemy_send_left <= 0.0:
			_enemy_send_left = ENEMY_SEND_INTERVAL
			_send_enemy_snapshots()


func _send_local_snapshot() -> void:
	var velocity: Vector2 = local_player.get("velocity")
	if velocity.length_squared() > 0.01:
		_last_facing = velocity.normalized()
	var pos := _bounded_position(local_player.global_position)
	if mode == Mode.HOST:
		_capture_host_player_state()
		var state: Dictionary = player_states.get(1, _default_player_state())
		_receive_snapshot.rpc(1, pos, _last_facing, GameState.current_zone, int(state["hp"]), int(state["max_hp"]), bool(state["dead"]))
	elif mode == Mode.CLIENT and not _joining:
		_submit_snapshot.rpc_id(1, pos, _last_facing)


@rpc("any_peer", "call_remote", "reliable", 0)
func _request_join(protocol: int, requested_name: String) -> void:
	if mode != Mode.HOST:
		return
	var sender := multiplayer.get_remote_sender_id()
	if protocol != PROTOCOL_VERSION:
		_reject_join.rpc_id(sender, "Phiên bản LAN không tương thích")
		return
	var safe_name := _sanitize_name(requested_name, sender)
	accepted_peers[sender] = true
	peer_names[sender] = safe_name
	for id: int in peer_names:
		_register_peer.rpc_id(sender, id, String(peer_names[id]))
	_register_peer.rpc(sender, safe_name)
	_accept_join.rpc_id(sender, GameState.current_zone)
	_send_enemy_registry(sender)
	_send_loot_registry(sender)
	_create_default_peer_state(sender)
	_send_player_registry(sender)
	_set_status("%s đã tham gia" % safe_name, false)


@rpc("authority", "call_remote", "reliable", 0)
func _accept_join(host_zone: String) -> void:
	_joining = false
	peer_names[multiplayer.get_unique_id()] = "Guest_%d" % multiplayer.get_unique_id()
	_set_status("Đã kết nối host", false)
	_send_local_combat_profile()
	session_ready.emit("client", host_zone)


@rpc("authority", "call_remote", "reliable", 0)
func _reject_join(reason: String) -> void:
	_set_status(reason.left(160), true)
	stop(false)


@rpc("authority", "call_remote", "reliable", 0)
func _register_peer(id: int, peer_name: String) -> void:
	peer_names[id] = _sanitize_name(peer_name, id)


@rpc("any_peer", "call_remote", "unreliable_ordered", 2)
func _submit_snapshot(pos: Vector2, facing: Vector2) -> void:
	if mode != Mode.HOST:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not accepted_peers.has(sender):
		return
	var safe_pos := _bounded_position(pos)
	if peer_positions.has(sender):
		safe_pos = (peer_positions[sender] as Vector2).move_toward(safe_pos, 24.0)
	peer_positions[sender] = safe_pos
	var safe_facing := facing.limit_length(1.0)
	_apply_snapshot(sender, safe_pos, safe_facing, GameState.current_zone)
	var state: Dictionary = player_states.get(sender, _default_player_state())
	_receive_snapshot.rpc(sender, safe_pos, safe_facing, GameState.current_zone, int(state["hp"]), int(state["max_hp"]), bool(state["dead"]))


@rpc("authority", "call_remote", "unreliable_ordered", 3)
func _receive_snapshot(id: int, pos: Vector2, facing: Vector2, zone_id: String, hp: int, max_hp: int, dead: bool) -> void:
	if (mode == Mode.CLIENT and _joining) or id == multiplayer.get_unique_id() or not GameContent.ZONES.has(zone_id):
		return
	if max_hp < MIN_PLAYER_HP or max_hp > MAX_PLAYER_HP or hp < 0 or hp > max_hp:
		return
	player_states[id] = {"hp": hp, "max_hp": max_hp, "attack": 1, "defense": 0, "dead": dead}
	_apply_snapshot(id, _bounded_position(pos), facing.limit_length(1.0), zone_id)


@rpc("authority", "call_remote", "reliable", 0)
func _sync_host_zone(zone_id: String) -> void:
	if mode != Mode.CLIENT or not GameContent.ZONES.has(zone_id):
		return
	if zone_id != GameState.current_zone:
		host_zone_requested.emit(zone_id)


func _apply_snapshot(id: int, pos: Vector2, facing: Vector2, zone_id: String) -> void:
	var avatar := remote_avatars.get(id) as LanRemoteAvatar
	if avatar == null or not is_instance_valid(avatar):
		if world_root == null:
			return
		avatar = LanRemoteAvatar.new()
		avatar.setup(id, String(peer_names.get(id, "Guest_%d" % id)))
		avatar.position = pos
		avatar.target_position = pos
		world_root.add_child(avatar)
		remote_avatars[id] = avatar
	avatar.apply_snapshot(pos, facing, zone_id)
	if player_states.has(id):
		var state: Dictionary = player_states[id]
		avatar.apply_vitals(int(state["hp"]), int(state["max_hp"]), bool(state["dead"]))


func _send_local_combat_profile() -> void:
	if mode != Mode.CLIENT or local_player == null:
		return
	var profile := _read_local_combat_profile()
	_submit_combat_profile.rpc_id(
		1,
		int(profile["hp"]),
		int(profile["max_hp"]),
		int(profile["attack"]),
		int(profile["defense"]),
		float(profile["crit_chance"]),
		float(profile["life_steal"]),
		float(profile["crit_damage"]),
		float(profile["dodge"]),
		float(profile["regeneration"])
	)


@rpc("any_peer", "call_remote", "reliable", 0)
func _submit_combat_profile(current_hp: int, max_hp: int, attack: int, defense: int, crit_chance: float, life_steal: float, crit_damage: float, dodge: float, regeneration: float) -> void:
	if mode != Mode.HOST:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not accepted_peers.has(sender):
		return
	var accepted_max := clampi(max_hp, MIN_PLAYER_HP, MAX_PLAYER_HP)
	var accepted_attack := clampi(attack, 1, MAX_PLAYER_ATTACK)
	var accepted_defense := clampi(defense, 0, MAX_PLAYER_DEFENSE)
	var accepted_crit := clampf(crit_chance, 0.0, MAX_PLAYER_CRIT_BONUS)
	var accepted_life_steal := clampf(life_steal, 0.0, MAX_PLAYER_LIFE_STEAL)
	var existing: Dictionary = player_states.get(sender, {})
	var accepted_hp := clampi(current_hp, 0, accepted_max)
	if bool(existing.get("profile_received", false)):
		accepted_hp = clampi(int(existing.get("hp", accepted_hp)), 0, accepted_max)
	var state := {
		"hp": accepted_hp,
		"max_hp": accepted_max,
		"attack": accepted_attack,
		"defense": accepted_defense,
		"crit_chance": accepted_crit,
		"life_steal": accepted_life_steal,
		"crit_damage": clampf(crit_damage, 0.0, MAX_PLAYER_CRIT_DAMAGE),
		"dodge": clampf(dodge, 0.0, MAX_PLAYER_DODGE),
		"regeneration": clampf(regeneration, 0.0, MAX_PLAYER_REGEN),
		"dead": accepted_hp <= 0,
		"profile_received": true,
	}
	player_states[sender] = state
	_apply_player_state_to_avatar(sender)
	_apply_authoritative_vitals.rpc_id(sender, accepted_hp, accepted_max, bool(state["dead"]), false, peer_positions.get(sender, Vector2.ZERO))


func damage_peer(peer_id: int, raw_damage: int) -> void:
	if mode != Mode.HOST or peer_id == 1 or not accepted_peers.has(peer_id):
		return
	var state: Dictionary = player_states.get(peer_id, {})
	if state.is_empty() or bool(state.get("dead", false)):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < float(_peer_respawn_until.get(peer_id, 0.0)):
		return
	if now - float(_peer_damage_times.get(peer_id, -100.0)) < PLAYER_INVULNERABILITY:
		return
	_peer_damage_times[peer_id] = now
	if Combat.roll_dodge(float(state.get("dodge", 0.0))):
		return
	var actual := GemCatalog.mitigate(clampi(raw_damage, 1, 100000), int(state.get("defense", 0)))
	state["hp"] = maxi(0, int(state["hp"]) - actual)
	state["dead"] = int(state["hp"]) <= 0
	player_states[peer_id] = state
	if bool(state["dead"]):
		_peer_respawn_until[peer_id] = now + PLAYER_INVULNERABILITY
	_apply_player_state_to_avatar(peer_id)
	_apply_authoritative_vitals.rpc_id(peer_id, int(state["hp"]), int(state["max_hp"]), bool(state["dead"]), false, peer_positions.get(peer_id, Vector2.ZERO))


var _peer_regen_acc: Dictionary = {}


## Renewal Stone regeneration for remote peers; the host owns their HP.
func _regenerate_peers(delta: float) -> void:
	for peer_id: Variant in player_states.keys():
		var state: Dictionary = player_states[peer_id]
		var rate := float(state.get("regeneration", 0.0))
		if rate <= 0.0 or bool(state.get("dead", false)) or int(state.get("hp", 0)) >= int(state.get("max_hp", 0)):
			_peer_regen_acc.erase(peer_id)
			continue
		var acc := float(_peer_regen_acc.get(peer_id, 0.0)) + rate * delta
		var whole := int(acc)
		_peer_regen_acc[peer_id] = acc - whole
		if whole <= 0:
			continue
		state["hp"] = mini(int(state["max_hp"]), int(state["hp"]) + whole)
		player_states[peer_id] = state
		_apply_player_state_to_avatar(int(peer_id))
		_apply_authoritative_vitals.rpc_id(int(peer_id), int(state["hp"]), int(state["max_hp"]), false, false, peer_positions.get(peer_id, Vector2.ZERO))


func request_player_respawn() -> void:
	if mode == Mode.CLIENT and not _joining:
		_request_player_respawn.rpc_id(1)


func request_consumable_use(item_id: String) -> bool:
	if mode != Mode.CLIENT or _joining or ItemDatabase.get_item(item_id) == null:
		return false
	var request_id := _next_consumable_request_id
	_next_consumable_request_id += 1
	_pending_consumable_requests[request_id] = {"item_id": item_id, "quantity": 1}
	_request_consumable_use.rpc_id(1, request_id, item_id)
	return true


@rpc("any_peer", "call_remote", "reliable", 0)
func _request_consumable_use(request_id: int, item_id: String) -> void:
	if mode != Mode.HOST:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not accepted_peers.has(sender) or request_id <= 0 or request_id >= 1000000000:
		return
	var key := "%d:%d" % [sender, request_id]
	if _resolved_consumable_requests.has(key):
		var previous: Dictionary = _resolved_consumable_requests[key]
		var previous_item_id := String(previous.get("item_id", ""))
		if previous_item_id != item_id:
			_resolve_consumable_use.rpc_id(sender, request_id, item_id, false, int(previous["hp"]), int(previous["max_hp"]))
			return
		_resolve_consumable_use.rpc_id(sender, request_id, previous_item_id, bool(previous["accepted"]), int(previous["hp"]), int(previous["max_hp"]))
		return
	var state: Dictionary = player_states.get(sender, {})
	var item := ItemDatabase.get_item(item_id)
	var accepted := not state.is_empty() and not bool(state.get("dead", false)) and item != null and item.is_consumable() and item.heal_amount > 0
	if accepted:
		state["hp"] = mini(int(state["max_hp"]), int(state["hp"]) + item.heal_amount)
		player_states[sender] = state
		_apply_player_state_to_avatar(sender)
		_apply_authoritative_vitals.rpc_id(sender, int(state["hp"]), int(state["max_hp"]), false, false, peer_positions.get(sender, Vector2.ZERO))
	var result := {
		"item_id": item_id,
		"accepted": accepted,
		"hp": int(state.get("hp", 0)),
		"max_hp": int(state.get("max_hp", MIN_PLAYER_HP)),
	}
	_resolved_consumable_requests[key] = result
	_resolve_consumable_use.rpc_id(sender, request_id, item_id, accepted, int(result["hp"]), int(result["max_hp"]))


@rpc("authority", "call_remote", "reliable", 0)
func _resolve_consumable_use(request_id: int, item_id: String, accepted: bool, _hp: int, _max_hp: int) -> void:
	if mode != Mode.CLIENT or not _pending_consumable_requests.has(request_id):
		return
	var pending: Dictionary = _pending_consumable_requests[request_id]
	if String(pending.get("item_id", "")) != item_id:
		return
	_pending_consumable_requests.erase(request_id)
	if accepted:
		_earned_rewards.append({"kind": "consume_item", "item_id": item_id, "quantity": 1})
		return
	_restore_local_item(item_id, 1)


@rpc("any_peer", "call_remote", "reliable", 0)
func _request_player_respawn() -> void:
	if mode != Mode.HOST:
		return
	var sender := multiplayer.get_remote_sender_id()
	var state: Dictionary = player_states.get(sender, {})
	if not accepted_peers.has(sender) or state.is_empty() or not bool(state.get("dead", false)):
		return
	var respawn_pos := peer_positions.get(sender, Vector2.ZERO) as Vector2
	if world_root and world_root.has_method("get_lan_spawn_position"):
		respawn_pos = world_root.get_lan_spawn_position()
	else:
		var map := SceneTransitionService.get_active_map_node()
		if map and map.has_method("get_spawn_position"):
			respawn_pos = map.get_spawn_position()
	peer_positions[sender] = _bounded_position(respawn_pos)
	state["hp"] = int(state["max_hp"])
	state["dead"] = false
	player_states[sender] = state
	_peer_respawn_until[sender] = Time.get_ticks_msec() / 1000.0 + RESPAWN_INVULNERABILITY
	var avatar := remote_avatars.get(sender) as LanRemoteAvatar
	if avatar and is_instance_valid(avatar):
		avatar.position = respawn_pos
		avatar.target_position = respawn_pos
		avatar.apply_vitals(int(state["hp"]), int(state["max_hp"]), false)
	_apply_authoritative_vitals.rpc_id(sender, int(state["hp"]), int(state["max_hp"]), false, true, respawn_pos)


@rpc("authority", "call_remote", "reliable", 0)
func _apply_authoritative_vitals(hp: int, max_hp: int, dead: bool, respawned: bool, respawn_pos: Vector2) -> void:
	if mode != Mode.CLIENT or local_player == null:
		return
	if max_hp < MIN_PLAYER_HP or max_hp > MAX_PLAYER_HP or hp < 0 or hp > max_hp:
		return
	if local_player.has_method("apply_lan_vitals"):
		local_player.apply_lan_vitals(hp, max_hp, dead, respawned, _bounded_position(respawn_pos))


func _send_player_registry(peer_id: int) -> void:
	for id: int in player_states:
		if id == peer_id:
			continue
		var state: Dictionary = player_states[id]
		_receive_snapshot.rpc_id(peer_id, id, peer_positions.get(id, Vector2.ZERO), Vector2.DOWN, GameState.current_zone, int(state["hp"]), int(state["max_hp"]), bool(state["dead"]))


func _create_default_peer_state(peer_id: int) -> void:
	if not player_states.has(peer_id):
		player_states[peer_id] = _default_player_state()


func _capture_host_player_state() -> void:
	if local_player == null:
		return
	var profile := _read_local_combat_profile()
	profile["dead"] = local_player.has_method("is_dead") and local_player.is_dead()
	profile["profile_received"] = true
	player_states[1] = profile
	peer_positions[1] = _bounded_position(local_player.global_position)


func _read_local_combat_profile() -> Dictionary:
	var result := _default_player_state()
	if local_player == null:
		return result
	var stats: Variant = null
	for property: Dictionary in local_player.get_property_list():
		if String(property.get("name", "")) == "stats":
			stats = local_player.get("stats")
			break
	if stats is CharacterStats:
		result["hp"] = clampi(stats.current_health, 0, MAX_PLAYER_HP)
		result["max_hp"] = clampi(stats.max_health, MIN_PLAYER_HP, MAX_PLAYER_HP)
		result["attack"] = clampi(stats.attack_damage, 1, MAX_PLAYER_ATTACK)
		result["defense"] = clampi(stats.defense, 0, MAX_PLAYER_DEFENSE)
		result["dead"] = stats.current_health <= 0
	if local_player.has_method("get_lan_combat_modifiers"):
		var modifiers: Dictionary = local_player.get_lan_combat_modifiers()
		result["crit_chance"] = clampf(float(modifiers.get("crit_chance", 0.0)), 0.0, MAX_PLAYER_CRIT_BONUS)
		result["life_steal"] = clampf(float(modifiers.get("life_steal", 0.0)), 0.0, MAX_PLAYER_LIFE_STEAL)
		result["crit_damage"] = clampf(float(modifiers.get("crit_damage", 0.0)), 0.0, MAX_PLAYER_CRIT_DAMAGE)
		result["dodge"] = clampf(float(modifiers.get("dodge", 0.0)), 0.0, MAX_PLAYER_DODGE)
		result["regeneration"] = clampf(float(modifiers.get("regeneration", 0.0)), 0.0, MAX_PLAYER_REGEN)
	return result


func _default_player_state() -> Dictionary:
	return {
		"hp": 100,
		"max_hp": 100,
		"attack": 10,
		"defense": 0,
		"crit_chance": 0.0,
		"life_steal": 0.0,
		"crit_damage": 0.0,
		"dodge": 0.0,
		"regeneration": 0.0,
		"dead": false,
		"profile_received": false,
	}


func _apply_player_state_to_avatar(peer_id: int) -> void:
	var avatar := remote_avatars.get(peer_id) as LanRemoteAvatar
	var state: Dictionary = player_states.get(peer_id, {})
	if avatar and is_instance_valid(avatar) and not state.is_empty():
		avatar.apply_vitals(int(state["hp"]), int(state["max_hp"]), bool(state["dead"]))


func register_enemy(enemy: Monster) -> int:
	if mode != Mode.HOST or enemy == null or enemy.network_replica:
		return 0
	if enemy.network_id > 0 and enemies.get(enemy.network_id) == enemy:
		return enemy.network_id
	var id := _next_enemy_id
	_next_enemy_id += 1
	enemy.network_id = id
	if not GameContent.ZONES.has(enemy.network_zone_id):
		enemy.network_zone_id = GameState.current_zone
	enemies[id] = enemy
	if not enemy.monster_died.is_connected(_on_authoritative_enemy_died):
		enemy.monster_died.connect(_on_authoritative_enemy_died)
	_spawn_enemy_replica.rpc(id, enemy.def_id, enemy.elite, enemy.global_position, enemy.hp, enemy.max_hp, enemy.network_zone_id)
	return id


func request_enemy_hit(enemy_id: int) -> void:
	if mode == Mode.CLIENT and not _joining:
		_request_enemy_hit.rpc_id(1, enemy_id)


@rpc("any_peer", "call_remote", "reliable", 0)
func _request_enemy_hit(enemy_id: int) -> void:
	if mode != Mode.HOST:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not accepted_peers.has(sender) or not peer_positions.has(sender):
		return
	var enemy := enemies.get(enemy_id) as Monster
	if enemy == null or not is_instance_valid(enemy) or enemy.is_dead():
		return
	if enemy.network_zone_id != GameState.current_zone:
		return
	var peer_state: Dictionary = player_states.get(sender, _default_player_state())
	if bool(peer_state.get("dead", false)):
		return
	var peer_pos := peer_positions[sender] as Vector2
	if peer_pos.distance_to(enemy.global_position) > CLIENT_HIT_RANGE + enemy.body_radius:
		return
	var now := Time.get_ticks_msec() / 1000.0
	var hit_key := "%d:%d" % [sender, enemy_id]
	var last := float(_enemy_hit_times.get(hit_key, -100.0))
	if now - last < CLIENT_HIT_COOLDOWN:
		return
	_enemy_hit_times[hit_key] = now
	var roll := Combat.roll(
		float(peer_state.get("attack", CLIENT_BASE_DAMAGE)),
		float(peer_state.get("crit_chance", 0.0)),
		float(peer_state.get("crit_damage", 0.0))
	)
	var applied := enemy.apply_hit(int(roll["amount"]), peer_pos, bool(roll["crit"]), sender)
	_apply_peer_life_steal(sender, applied, float(peer_state.get("life_steal", 0.0)))


func _apply_peer_life_steal(peer_id: int, damage_dealt: int, percent: float) -> void:
	if damage_dealt <= 0 or percent <= 0.0 or not player_states.has(peer_id):
		return
	var state: Dictionary = player_states[peer_id]
	if bool(state.get("dead", false)):
		return
	var heal_amount := int(float(damage_dealt) * clampf(percent, 0.0, MAX_PLAYER_LIFE_STEAL) / 100.0)
	if heal_amount <= 0:
		return
	var previous_hp := int(state.get("hp", 0))
	state["hp"] = mini(int(state.get("max_hp", MIN_PLAYER_HP)), previous_hp + heal_amount)
	if int(state["hp"]) == previous_hp:
		return
	player_states[peer_id] = state
	_apply_player_state_to_avatar(peer_id)
	_apply_authoritative_vitals.rpc_id(
		peer_id,
		int(state["hp"]),
		int(state["max_hp"]),
		false,
		false,
		peer_positions.get(peer_id, Vector2.ZERO)
	)


func spawn_authoritative_item(pos: Vector2, item_id: String, quantity: int) -> int:
	if mode != Mode.HOST or ItemDatabase.get_item(item_id) == null:
		return 0
	return _spawn_authoritative_loot("item", item_id, clampi(quantity, 1, MAX_LOOT_QUANTITY), pos)


func spawn_authoritative_gold(pos: Vector2, amount: int) -> int:
	if mode != Mode.HOST:
		return 0
	return _spawn_authoritative_loot("gold", "", clampi(amount, 1, MAX_LOOT_QUANTITY), pos)


func request_loot_pickup(loot_id: int) -> void:
	if mode == Mode.CLIENT and not _joining:
		_request_loot_pickup.rpc_id(1, loot_id)


func _spawn_authoritative_loot(kind: String, item_id: String, quantity: int, pos: Vector2) -> int:
	var id := _next_loot_id
	_next_loot_id += 1
	var item := NETWORK_ITEM_SCENE.instantiate() as GameItem
	item.network_id = id
	item.network_zone_id = GameState.current_zone
	item.global_position = _bounded_position(pos)
	if kind == "gold":
		item.setup_gold(quantity)
	else:
		item.setup_item(item_id, quantity)
	item.collected.connect(func(_content_type: GameItem.ContentType, _item_id: String, _quantity: int) -> void:
		_on_host_loot_collected(id)
	)
	if world_root == null:
		return 0
	world_root.add_child(item)
	item.scatter_from(pos)
	loot[id] = item
	_spawn_loot_replica.rpc(id, kind, item_id, quantity, item.global_position, item.network_zone_id)
	return id


@rpc("any_peer", "call_remote", "reliable", 0)
func _request_loot_pickup(loot_id: int) -> void:
	if mode != Mode.HOST:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not accepted_peers.has(sender) or not peer_positions.has(sender):
		return
	var item := loot.get(loot_id) as GameItem
	if item == null or not is_instance_valid(item) or item._is_collected:
		return
	if item.network_zone_id != GameState.current_zone:
		return
	if (peer_positions[sender] as Vector2).distance_to(item.global_position) > LOOT_PICKUP_RANGE:
		return
	var kind := "gold" if item.content_type == GameItem.ContentType.GOLD else "item"
	var quantity := item.value if kind == "gold" else item.quantity
	if kind == "gold":
		_send_loot_transaction(sender, 0, kind, item.item_id, quantity)
		_consume_authoritative_loot(loot_id, true)
		return
	if _loot_reservations.has(loot_id):
		var reservation: Dictionary = _loot_reservations[loot_id]
		if int(reservation.get("peer_id", 0)) == sender:
			var existing_tx := int(reservation.get("tx_id", 0))
			var existing: Dictionary = _pending_loot_transactions.get(existing_tx, {})
			if not existing.is_empty():
				_apply_loot_transaction.rpc_id(sender, existing_tx, loot_id, kind, item.item_id, quantity)
		return
	var tx_id := _next_transaction_id
	_next_transaction_id += 1
	_pending_loot_transactions[tx_id] = {
		"peer_id": sender,
		"loot_id": loot_id,
		"item_id": item.item_id,
		"quantity": quantity,
	}
	_loot_reservations[loot_id] = {
		"peer_id": sender,
		"tx_id": tx_id,
		"expires_at": Time.get_ticks_msec() / 1000.0 + LOOT_RESERVATION_TIMEOUT,
	}
	_apply_loot_transaction.rpc_id(sender, tx_id, loot_id, kind, item.item_id, quantity)


func _send_loot_transaction(peer_id: int, loot_id: int, kind: String, item_id: String, quantity: int) -> void:
	var tx_id := _next_transaction_id
	_next_transaction_id += 1
	_apply_loot_transaction.rpc_id(peer_id, tx_id, loot_id, kind, item_id, quantity)


@rpc("authority", "call_remote", "reliable", 0)
func _apply_loot_transaction(tx_id: int, loot_id: int, kind: String, item_id: String, quantity: int) -> void:
	if mode != Mode.CLIENT or tx_id <= 0 or tx_id >= 1000000000:
		return
	if quantity <= 0 or quantity > MAX_LOOT_QUANTITY or not ["item", "gold"].has(kind):
		return
	if kind == "item" and ItemDatabase.get_item(item_id) == null:
		return
	var player := local_player
	if player == null:
		return
	if _applied_transactions.has(tx_id):
		if kind == "item":
			_acknowledge_loot_transaction.rpc_id(1, tx_id, loot_id, int(_applied_transactions[tx_id]))
		return
	var remaining := _apply_reward_to_local_player(kind, item_id, quantity)
	_applied_transactions[tx_id] = remaining
	var accepted_quantity := quantity - remaining
	if accepted_quantity > 0:
		_earned_rewards.append({"kind": kind, "item_id": item_id, "quantity": accepted_quantity})
	if kind == "item":
		_acknowledge_loot_transaction.rpc_id(1, tx_id, loot_id, remaining)


@rpc("any_peer", "call_remote", "reliable", 0)
func _acknowledge_loot_transaction(tx_id: int, loot_id: int, remaining: int) -> void:
	if mode != Mode.HOST or not _pending_loot_transactions.has(tx_id):
		return
	var sender := multiplayer.get_remote_sender_id()
	var pending: Dictionary = _pending_loot_transactions[tx_id]
	if int(pending.get("peer_id", 0)) != sender or int(pending.get("loot_id", 0)) != loot_id:
		return
	var quantity := int(pending.get("quantity", 0))
	if remaining < 0 or remaining > quantity:
		return
	_pending_loot_transactions.erase(tx_id)
	_loot_reservations.erase(loot_id)
	var item := loot.get(loot_id) as GameItem
	if item == null or not is_instance_valid(item) or item.item_id != String(pending.get("item_id", "")):
		return
	if remaining == 0:
		_consume_authoritative_loot(loot_id, true)
		return
	item.quantity = remaining
	_update_loot_replica.rpc(loot_id, remaining)


func _expire_loot_reservations() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for loot_id: int in _loot_reservations.keys():
		var reservation: Dictionary = _loot_reservations[loot_id]
		if now < float(reservation.get("expires_at", 0.0)):
			continue
		_pending_loot_transactions.erase(int(reservation.get("tx_id", 0)))
		_loot_reservations.erase(loot_id)


func take_earned_rewards() -> Array[Dictionary]:
	var rewards := _earned_rewards.duplicate(true) as Array[Dictionary]
	_earned_rewards.clear()
	_applied_transactions.clear()
	return rewards


func restore_earned_rewards(rewards: Array[Dictionary]) -> void:
	for reward: Dictionary in rewards:
		var kind := String(reward.get("kind", ""))
		var item_id := String(reward.get("item_id", ""))
		var quantity := int(reward.get("quantity", 0))
		if quantity <= 0 or quantity > MAX_LOOT_QUANTITY:
			continue
		if ["item", "gold"].has(kind):
			_apply_reward_to_local_player(kind, item_id, quantity)
		elif kind == "consume_item":
			_remove_local_item(item_id, quantity)


func _apply_reward_to_local_player(kind: String, item_id: String, quantity: int) -> int:
	if local_player == null or not local_player.has_method("get_inventory"):
		return quantity
	var inventory := local_player.get_inventory() as InventoryData
	if inventory == null:
		return quantity
	if kind == "gold":
		inventory.gold += quantity
		return 0
	return inventory.add_item(ItemDatabase.get_item(item_id), quantity)


func _restore_local_item(item_id: String, quantity: int) -> void:
	if local_player == null or not local_player.has_method("get_inventory"):
		return
	var inventory := local_player.get_inventory() as InventoryData
	if inventory:
		inventory.add_item(ItemDatabase.get_item(item_id), quantity)


func _remove_local_item(item_id: String, quantity: int) -> void:
	if local_player == null or not local_player.has_method("get_inventory"):
		return
	var inventory := local_player.get_inventory() as InventoryData
	var item := ItemDatabase.get_item(item_id)
	if inventory and item:
		inventory.remove_item(item, quantity)


@rpc("authority", "call_remote", "reliable", 0)
func _spawn_loot_replica(id: int, kind: String, item_id: String, quantity: int, pos: Vector2, zone_id: String) -> void:
	if mode != Mode.CLIENT or not _valid_loot_payload(id, kind, item_id, quantity, pos, zone_id):
		return
	if loot.has(id):
		return
	var item := NETWORK_ITEM_SCENE.instantiate() as GameItem
	item.network_replica = true
	item.network_id = id
	item.network_zone_id = zone_id
	item.global_position = pos
	if kind == "gold":
		item.setup_gold(quantity)
	else:
		item.setup_item(item_id, quantity)
	if world_root == null:
		return
	world_root.add_child(item)
	item.visible = zone_id == GameState.current_zone
	loot[id] = item


@rpc("authority", "call_remote", "reliable", 0)
func _update_loot_replica(id: int, quantity: int) -> void:
	if mode != Mode.CLIENT or quantity <= 0 or quantity > MAX_LOOT_QUANTITY:
		return
	var item := loot.get(id) as GameItem
	if item == null or not is_instance_valid(item) or item.content_type != GameItem.ContentType.ITEM:
		return
	item.quantity = quantity
	item._network_pickup_pending = false


@rpc("authority", "call_remote", "reliable", 0)
func _remove_loot_replica(id: int, collected: bool) -> void:
	if mode != Mode.CLIENT:
		return
	var item := loot.get(id) as GameItem
	loot.erase(id)
	if item == null or not is_instance_valid(item):
		return
	if collected:
		item.apply_network_collected()
	else:
		item.queue_free()


func _consume_authoritative_loot(id: int, collected: bool) -> void:
	var item := loot.get(id) as GameItem
	loot.erase(id)
	_remove_loot_replica.rpc(id, collected)
	if item and is_instance_valid(item):
		item._is_collected = true
		item.queue_free()


func _on_host_loot_collected(id: int) -> void:
	if mode == Mode.HOST and loot.has(id):
		loot.erase(id)
		_remove_loot_replica.rpc(id, true)


func _send_loot_registry(peer_id: int) -> void:
	for id: int in loot:
		var item := loot[id] as GameItem
		if item == null or not is_instance_valid(item) or item._is_collected:
			continue
		var kind := "gold" if item.content_type == GameItem.ContentType.GOLD else "item"
		var quantity := item.value if kind == "gold" else item.quantity
		_spawn_loot_replica.rpc_id(peer_id, id, kind, item.item_id, quantity, item.global_position, item.network_zone_id)


@rpc("authority", "call_remote", "reliable", 0)
func _spawn_enemy_replica(id: int, def_id: String, elite: bool, pos: Vector2, hp: int, max_hp: int, zone_id: String) -> void:
	if mode != Mode.CLIENT or not _valid_enemy_payload(id, def_id, pos, hp, max_hp, zone_id):
		return
	var enemy := enemies.get(id) as Monster
	if enemy == null or not is_instance_valid(enemy):
		enemy = Monster.create(def_id, elite)
		enemy.network_replica = true
		enemy.network_id = id
		enemy.network_zone_id = zone_id
		enemy.position = pos
		enemy.network_target_position = pos
		if world_root == null:
			return
		world_root.add_child(enemy)
		enemies[id] = enemy
	enemy.apply_network_snapshot(pos, Vector2.DOWN, "idle", hp, max_hp, zone_id)


@rpc("authority", "call_remote", "unreliable_ordered", 4)
func _receive_enemy_snapshots(batch: Array) -> void:
	if mode != Mode.CLIENT or batch.size() > MAX_ENEMY_BATCH:
		return
	for raw: Variant in batch:
		if not raw is Array:
			continue
		var entry := raw as Array
		if entry.size() != 9:
			continue
		var id := int(entry[0])
		var def_id := String(entry[1])
		var elite := bool(entry[2])
		var pos := entry[3] as Vector2
		var facing := entry[4] as Vector2
		var enemy_state := String(entry[5]).left(24)
		var hp := int(entry[6])
		var max_hp := int(entry[7])
		var zone_id := String(entry[8])
		if not _valid_enemy_payload(id, def_id, pos, hp, max_hp, zone_id):
			continue
		if not enemies.has(id):
			_spawn_enemy_replica(id, def_id, elite, pos, hp, max_hp, zone_id)
		var enemy := enemies.get(id) as Monster
		if enemy and is_instance_valid(enemy):
			enemy.apply_network_snapshot(pos, facing.limit_length(1.0), enemy_state, hp, max_hp, zone_id)


@rpc("authority", "call_remote", "reliable", 0)
func _remove_enemy_replica(id: int, died: bool) -> void:
	if mode != Mode.CLIENT:
		return
	var enemy := enemies.get(id) as Monster
	enemies.erase(id)
	if enemy == null or not is_instance_valid(enemy):
		return
	if died:
		enemy.apply_network_death()
	else:
		enemy.queue_free()


func _send_enemy_snapshots() -> void:
	var batch: Array = []
	var stale: Array[int] = []
	for id: int in enemies:
		var enemy := enemies[id] as Monster
		if enemy == null or not is_instance_valid(enemy):
			stale.append(id)
			continue
		batch.append([id, enemy.def_id, enemy.elite, _bounded_position(enemy.global_position), enemy.facing.limit_length(1.0), enemy.state.left(24), enemy.hp, enemy.max_hp, enemy.network_zone_id])
		if batch.size() >= MAX_ENEMY_BATCH:
			_receive_enemy_snapshots.rpc(batch)
			batch = []
	for id in stale:
		enemies.erase(id)
		_remove_enemy_replica.rpc(id, false)
	if not batch.is_empty():
		_receive_enemy_snapshots.rpc(batch)


func _send_enemy_registry(peer_id: int) -> void:
	for id: int in enemies:
		var enemy := enemies[id] as Monster
		if enemy and is_instance_valid(enemy) and not enemy.is_dead():
			_spawn_enemy_replica.rpc_id(peer_id, id, enemy.def_id, enemy.elite, enemy.global_position, enemy.hp, enemy.max_hp, enemy.network_zone_id)


func _on_authoritative_enemy_died(enemy: Monster) -> void:
	if mode != Mode.HOST or enemy.network_id <= 0:
		return
	var id := enemy.network_id
	enemies.erase(id)
	_remove_enemy_replica.rpc(id, true)


func _adopt_existing_enemies() -> void:
	if get_tree() == null:
		return
	for node in get_tree().get_nodes_in_group("monster"):
		if node is Monster:
			register_enemy(node as Monster)


func _clear_local_enemies() -> void:
	if get_tree() == null:
		return
	for node in get_tree().get_nodes_in_group("monster"):
		if node is Monster:
			(node as Monster).queue_free()


func _clear_enemy_registry() -> void:
	for value: Variant in enemies.values():
		var enemy := value as Monster
		if enemy and is_instance_valid(enemy) and enemy.network_replica:
			enemy.queue_free()
	enemies.clear()
	_next_enemy_id = 1


func _clear_loot_registry() -> void:
	for value: Variant in loot.values():
		var item := value as GameItem
		if item and is_instance_valid(item) and item.network_replica:
			item.queue_free()
	loot.clear()
	_next_loot_id = 1


func _valid_loot_payload(id: int, kind: String, item_id: String, quantity: int, pos: Vector2, zone_id: String) -> bool:
	if id <= 0 or id >= 1000000 or not ["item", "gold"].has(kind):
		return false
	if quantity <= 0 or quantity > MAX_LOOT_QUANTITY or not GameContent.ZONES.has(zone_id):
		return false
	if not is_finite(pos.x) or not is_finite(pos.y) or absf(pos.x) > 10000.0 or absf(pos.y) > 10000.0:
		return false
	return kind == "gold" or ItemDatabase.get_item(item_id) != null


func _valid_enemy_payload(id: int, def_id: String, pos: Vector2, hp: int, max_hp: int, zone_id: String) -> bool:
	return id > 0 and id < 1000000 and GameContent.MONSTERS.has(def_id) and GameContent.ZONES.has(zone_id) and is_finite(pos.x) and is_finite(pos.y) and absf(pos.x) <= 10000.0 and absf(pos.y) <= 10000.0 and max_hp > 0 and max_hp <= 10000000 and hp >= 0 and hp <= max_hp


func _on_peer_connected(id: int) -> void:
	if mode == Mode.HOST:
		_set_status("Peer %d đang handshake..." % id, false)


func _on_peer_disconnected(id: int) -> void:
	accepted_peers.erase(id)
	peer_names.erase(id)
	peer_positions.erase(id)
	player_states.erase(id)
	_peer_damage_times.erase(id)
	_peer_respawn_until.erase(id)
	_remove_remote_avatar(id)
	for loot_id: int in _loot_reservations.keys():
		var reservation: Dictionary = _loot_reservations[loot_id]
		if int(reservation.get("peer_id", 0)) == id:
			_pending_loot_transactions.erase(int(reservation.get("tx_id", 0)))
			_loot_reservations.erase(loot_id)
	for key: String in _resolved_consumable_requests.keys():
		if key.begins_with("%d:" % id):
			_resolved_consumable_requests.erase(key)
	if mode == Mode.HOST:
		_set_status("Peer %d đã rời phiên" % id, false)


func _on_connected_to_server() -> void:
	_request_join.rpc_id(1, PROTOCOL_VERSION, "Guest_Client")


func _on_connection_failed() -> void:
	_set_status("Kết nối Wi-Fi thất bại", true)
	stop(false)


func _on_server_disconnected() -> void:
	stop(false)
	_set_status("Host đã ngắt kết nối", true)
	session_ended.emit("Host đã ngắt kết nối")


func _set_status(text: String, is_error: bool) -> void:
	status_changed.emit(text, is_error)


func _sanitize_name(raw: String, id: int) -> String:
	var value := raw.strip_edges().left(24)
	return value if value != "" else "Guest_%d" % id


func _bounded_position(pos: Vector2) -> Vector2:
	if not is_finite(pos.x) or not is_finite(pos.y):
		return Vector2.ZERO
	return Vector2(clampf(pos.x, -10000.0, 10000.0), clampf(pos.y, -10000.0, 10000.0))


func _remove_remote_avatar(id: int) -> void:
	var avatar := remote_avatars.get(id) as LanRemoteAvatar
	if avatar and is_instance_valid(avatar):
		avatar.queue_free()
	remote_avatars.erase(id)


func _clear_remote_avatars() -> void:
	for id: int in remote_avatars.keys():
		_remove_remote_avatar(id)
