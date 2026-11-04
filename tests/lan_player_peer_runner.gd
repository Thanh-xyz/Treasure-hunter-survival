extends Node
## Two-process ENet test for host-owned player combat profile, HP and respawn.

class TestPlayer:
	extends CharacterBody2D
	var stats := CharacterStats.new()
	var dead := false
	var respawn_seen := false
	var vitals_updates := 0
	var inventory := InventoryData.new()

	func is_dead() -> bool:
		return dead

	func get_inventory() -> InventoryData:
		return inventory

	func apply_lan_vitals(hp: int, max_hp: int, is_dead_state: bool, respawned: bool, respawn_pos: Vector2) -> void:
		stats.base_max_health = max_hp
		stats.current_health = hp
		dead = is_dead_state
		vitals_updates += 1
		if respawned:
			global_position = respawn_pos
			respawn_seen = true


var _role := "host"
var _output := "/tmp/emberfield-lan-player-peer.json"
var _player: TestPlayer
var _ready_seen := false
var _failed := false
var _elapsed := 0.0
var _client_peer_id := 0
var _profile_seen := false
var _attack_profile_seen := false
var _damage_seen := false
var _iframe_rejected := false
var _death_seen := false
var _respawn_seen := false
var _respawn_request_sent := false
var _enemy_id := 0
var _enemy_initial_hp := 0
var _damage_step := 0
var _next_enemy_hit := 0.0
var _healing_requested := false
var _healing_seen := false
var _consumption_restore_seen := false


func _ready() -> void:
	_parse_args()
	_player = TestPlayer.new()
	_player.name = "TestPlayer"
	_player.position = Vector2(100, 200) if _role == "host" else Vector2(150, 220)
	_player.stats.base_max_health = 100
	_player.stats.current_health = 100
	_player.stats.base_attack_damage = 10 if _role == "host" else 30
	_player.stats.base_defense = 0 if _role == "host" else 5
	if _role == "client":
		_player.inventory.add_item(ItemDatabase.get_item("health_potion"), 1)
	add_child(_player)
	LanSession.bind(self, _player)
	LanSession.session_ready.connect(func(_mode: String, _zone: String) -> void: _ready_seen = true)
	LanSession.status_changed.connect(func(_text: String, is_error: bool) -> void: _failed = _failed or is_error)
	if _role == "host":
		_failed = LanSession.start_host() != OK
		_build_enemy()
	else:
		_failed = LanSession.join_host("127.0.0.1") != OK
	_finish_after_delay.call_deferred()


func get_lan_spawn_position() -> Vector2:
	return Vector2(320, 480)


func _build_enemy() -> void:
	var enemy := Monster.create("slime")
	enemy.position = Vector2(165, 220)
	enemy.max_hp = 100
	enemy.hp = 100
	enemy.xp_reward = 0
	enemy.def = enemy.def.duplicate(true)
	enemy.def["gold"] = Vector2i.ZERO
	enemy.def["loot"] = []
	add_child(enemy)
	enemy.set_physics_process(false)
	_enemy_id = enemy.network_id
	_enemy_initial_hp = enemy.hp


func _process(delta: float) -> void:
	_elapsed += delta
	if _role == "host":
		_process_host()
	else:
		_process_client()


func _process_host() -> void:
	if _client_peer_id == 0:
		for id: int in LanSession.peer_names:
			if id != 1:
				_client_peer_id = id
				break
	if _client_peer_id == 0:
		return
	var state: Dictionary = LanSession.player_states.get(_client_peer_id, {})
	_profile_seen = _profile_seen or (bool(state.get("profile_received", false)) and int(state.get("max_hp", 0)) == 100 and int(state.get("defense", -1)) == 5)
	_attack_profile_seen = _attack_profile_seen or int(state.get("attack", 0)) == 30
	var enemy := LanSession.enemies.get(_enemy_id) as Monster
	if enemy and is_instance_valid(enemy):
		_attack_profile_seen = _attack_profile_seen and _enemy_initial_hp - enemy.hp >= 26
	if not _profile_seen:
		return
	_healing_seen = _healing_seen or (_damage_step >= 1 and int(state.get("hp", 0)) == 85)
	if _elapsed >= 1.3 and _damage_step == 0:
		LanSession.damage_peer(_client_peer_id, 70)
		var after_first: Dictionary = LanSession.player_states[_client_peer_id]
		_damage_seen = int(after_first["hp"]) == 35
		LanSession.damage_peer(_client_peer_id, 20)
		var after_second: Dictionary = LanSession.player_states[_client_peer_id]
		_iframe_rejected = int(after_second["hp"]) == 35
		_damage_step = 1
	if _elapsed >= 2.6 and _damage_step == 1 and _healing_seen:
		LanSession.damage_peer(_client_peer_id, 999)
		_damage_step = 2
	state = LanSession.player_states.get(_client_peer_id, {})
	_death_seen = _death_seen or bool(state.get("dead", false))
	_respawn_seen = _respawn_seen or (_death_seen and not bool(state.get("dead", true)) and int(state.get("hp", 0)) == int(state.get("max_hp", -1)) and (LanSession.peer_positions.get(_client_peer_id, Vector2.ZERO) as Vector2).distance_to(get_lan_spawn_position()) < 0.1)


func _process_client() -> void:
	if not _ready_seen:
		return
	if _enemy_id == 0:
		for id: int in LanSession.enemies:
			_enemy_id = id
			_enemy_initial_hp = (LanSession.enemies[id] as Monster).hp
			LanSession.request_enemy_hit(id)
			_next_enemy_hit = _elapsed + 0.25
			break
	if _enemy_id > 0 and LanSession.enemies.has(_enemy_id):
		var enemy := LanSession.enemies[_enemy_id] as Monster
		if _enemy_initial_hp - enemy.hp < 26 and _elapsed >= _next_enemy_hit:
			_next_enemy_hit = _elapsed + 0.25
			LanSession.request_enemy_hit(_enemy_id)
	_death_seen = _death_seen or _player.dead
	if _player.dead and not _respawn_request_sent:
		_respawn_request_sent = true
		LanSession.request_player_respawn()
	_respawn_seen = _respawn_seen or (_player.respawn_seen and not _player.dead and _player.stats.current_health == _player.stats.max_health and _player.global_position.distance_to(get_lan_spawn_position()) < 0.1)
	_damage_seen = _damage_seen or (_player.stats.current_health == 35)
	if _player.stats.current_health == 35 and not _healing_requested:
		var result := _player.inventory.use_item(0)
		if result.get("success", false):
			_healing_requested = LanSession.request_consumable_use(String(result.get("item_id", "")))
	_healing_seen = _healing_seen or (_healing_requested and _player.stats.current_health == 85)
	if _healing_seen and not _consumption_restore_seen:
		var rewards := LanSession.take_earned_rewards()
		SaveService.deserialize_inventory(_player.inventory, {"gold": 0, "slots": [{"id": "health_potion", "qty": 1}], "equipment": {}})
		LanSession.restore_earned_rewards(rewards)
		_consumption_restore_seen = _player.inventory.get_item_count("health_potion") == 0


func _finish_after_delay() -> void:
	await get_tree().create_timer(5.3 if _role == "host" else 4.5).timeout
	var result := {
		"role": _role,
		"ready": _ready_seen,
		"failed": _failed,
		"client_peer_id": _client_peer_id,
		"profile_seen": _profile_seen,
		"attack_profile_seen": _attack_profile_seen,
		"damage_seen": _damage_seen,
		"iframe_rejected": _iframe_rejected,
		"death_seen": _death_seen,
		"respawn_seen": _respawn_seen,
		"respawn_request_sent": _respawn_request_sent,
		"client_hp": _player.stats.current_health,
		"client_dead": _player.dead,
		"client_position": [_player.position.x, _player.position.y],
		"healing_requested": _healing_requested,
		"healing_seen": _healing_seen,
		"consumption_restore_seen": _consumption_restore_seen,
	}
	var file := FileAccess.open(_output, FileAccess.WRITE)
	if file == null:
		get_tree().quit(2)
		return
	file.store_string(JSON.stringify(result))
	file.close()
	var ok := _ready_seen and not _failed and _damage_seen and _death_seen and _respawn_seen
	if _role == "host":
		ok = ok and _client_peer_id > 0 and _profile_seen and _attack_profile_seen and _iframe_rejected and _healing_seen
	else:
		ok = ok and _respawn_request_sent and _healing_requested and _healing_seen and _consumption_restore_seen
	LanSession.stop(false)
	get_tree().quit(0 if ok else 1)


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			_role = arg.trim_prefix("--role=")
		elif arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
