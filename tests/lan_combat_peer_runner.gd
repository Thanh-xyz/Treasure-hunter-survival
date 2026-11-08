extends Node
## Two-process ENet test for host-owned enemy HP and lifecycle.

var _role := "host"
var _output := "/tmp/emberfield-lan-combat-peer.json"
class TestPlayer:
	extends CharacterBody2D
	var inventory := InventoryData.new()
	var stats := CharacterStats.new()
	var crit_chance := 0.0
	var life_steal := 0.0
	func get_inventory() -> InventoryData:
		return inventory
	func get_lan_combat_modifiers() -> Dictionary:
		return {"crit_chance": crit_chance, "life_steal": life_steal}
	func apply_lan_vitals(hp: int, max_hp: int, _dead: bool, _respawned: bool, _pos: Vector2) -> void:
		stats.base_max_health = max_hp
		stats.current_health = hp


var _player: TestPlayer
var _ready_seen := false
var _failed := false
var _elapsed := 0.0
var _enemy_id := 0
var _initial_hp := -1
var _minimum_hp := 1000000
var _enemy_seen := false
var _hp_change_seen := false
var _removal_seen := false
var _far_hit_rejected := false
var _seen_elapsed := 0.0
var _next_hit := 0.0
var _far_request_sent := false
var _loot_id := 0
var _loot_seen := false
var _loot_removed := false
var _loot_granted := false
var _loot_far_request_sent := false
var _loot_far_rejected := false
var _reward_restore_seen := false
var _full_bag_preserved := false
var _partial_pickup_seen := false
var _client_loot_phase := 0
var _critical_hit_seen := false
var _life_steal_seen := false


func _ready() -> void:
	_parse_args()
	_player = TestPlayer.new()
	_player.name = "TestPlayer"
	_player.position = Vector2(100, 200) if _role == "host" else Vector2(900, 900)
	if _role == "client":
		_player.stats.current_health = 40
		_player.crit_chance = 100.0
		_player.life_steal = 50.0
	add_child(_player)
	LanSession.bind(self, _player)
	LanSession.session_ready.connect(func(_mode: String, _zone: String) -> void: _ready_seen = true)
	LanSession.status_changed.connect(func(_text: String, is_error: bool) -> void: _failed = _failed or is_error)
	if _role == "host":
		_failed = LanSession.start_host() != OK
		_build_host_enemy()
	else:
		_failed = LanSession.join_host("127.0.0.1") != OK
	_finish_after_delay.call_deferred()


func _build_host_enemy() -> void:
	var enemy := Monster.create("slime")
	enemy.position = Vector2(160, 220)
	enemy.max_hp = 24
	enemy.hp = 24
	enemy.xp_reward = 0
	enemy.def = enemy.def.duplicate(true)
	enemy.def["gold"] = Vector2i.ZERO
	enemy.def["loot"] = []
	add_child(enemy)
	enemy.set_physics_process(false)
	_enemy_id = enemy.network_id
	_initial_hp = enemy.hp
	_minimum_hp = enemy.hp
	enemy.hp_changed.connect(func(hp: int, _max_hp: int) -> void:
		_minimum_hp = mini(_minimum_hp, hp)
		_hp_change_seen = _hp_change_seen or hp < _initial_hp
	)
	_loot_id = LanSession.spawn_authoritative_item(Vector2(170, 220), "health_potion", 2)


func _fill_client_inventory() -> void:
	var sword := ItemDatabase.get_item("ashwood_blade")
	for i in range(_player.inventory.inventory_slots.size()):
		_player.inventory.inventory_slots[i] = {"item": sword, "quantity": 1}
	_player.inventory.inventory_changed.emit()


func _process(delta: float) -> void:
	_elapsed += delta
	if _role == "host":
		if _elapsed >= 0.8 and _minimum_hp == _initial_hp:
			_far_hit_rejected = true
		_critical_hit_seen = _critical_hit_seen or (_minimum_hp < _initial_hp - 11)
		for peer_id: int in LanSession.player_states:
			if peer_id != 1:
				var state: Dictionary = LanSession.player_states[peer_id]
				_life_steal_seen = _life_steal_seen or int(state.get("hp", 0)) > 40
		if _enemy_id > 0 and not LanSession.enemies.has(_enemy_id):
			_removal_seen = true
		if _loot_id > 0 and not LanSession.loot.has(_loot_id):
			_loot_removed = true
		if _elapsed >= 0.8 and _loot_id > 0 and LanSession.loot.has(_loot_id):
			_loot_far_rejected = true
			var host_loot := LanSession.loot[_loot_id] as GameItem
			_full_bag_preserved = _full_bag_preserved or host_loot.quantity == 2
			_partial_pickup_seen = _partial_pickup_seen or host_loot.quantity == 1
		return
	if not _ready_seen:
		return
	if _enemy_id == 0:
		for id: int in LanSession.enemies:
			_enemy_id = id
			var enemy := LanSession.enemies[id] as Monster
			_initial_hp = enemy.hp
			_minimum_hp = enemy.hp
			_enemy_seen = true
			_seen_elapsed = _elapsed
			LanSession.request_enemy_hit(_enemy_id)
			_far_request_sent = true
			break
	if _enemy_id == 0:
		return
	if _loot_id == 0:
		for id: int in LanSession.loot:
			_loot_id = id
			_loot_seen = true
			_fill_client_inventory()
			LanSession.request_loot_pickup(id)
			_loot_far_request_sent = true
			break
	if LanSession.enemies.has(_enemy_id):
		var replica := LanSession.enemies[_enemy_id] as Monster
		_minimum_hp = mini(_minimum_hp, replica.hp)
		_hp_change_seen = _hp_change_seen or replica.hp < _initial_hp
	else:
		_removal_seen = true
	var since_seen := _elapsed - _seen_elapsed
	if since_seen >= 0.8:
		_player.position = Vector2(150, 220)
	if since_seen >= 1.05 and _elapsed >= _next_hit:
		_next_hit = _elapsed + 0.25
		LanSession.request_enemy_hit(_enemy_id)
	if _loot_id > 0 and since_seen >= 0.9 and LanSession.loot.has(_loot_id):
		var replica := LanSession.loot[_loot_id] as GameItem
		match _client_loot_phase:
			0:
				LanSession.request_loot_pickup(_loot_id)
				if since_seen >= 1.35 and _player.inventory.get_item_count("health_potion") == 0 and replica.quantity == 2:
					_full_bag_preserved = true
					_player.inventory.inventory_slots[0] = {"item": ItemDatabase.get_item("health_potion"), "quantity": 19}
					_client_loot_phase = 1
			1:
				LanSession.request_loot_pickup(_loot_id)
				if _player.inventory.get_item_count("health_potion") == 20 and replica.quantity == 1:
					_partial_pickup_seen = true
					_player.inventory.inventory_slots[1] = {"item": null, "quantity": 0}
					_client_loot_phase = 2
			2:
				LanSession.request_loot_pickup(_loot_id)
	_loot_removed = _loot_id > 0 and not LanSession.loot.has(_loot_id)
	_loot_granted = _loot_granted or (_client_loot_phase == 2 and _player.inventory.get_item_count("health_potion") == 21)
	if _loot_granted and not _reward_restore_seen and since_seen >= 3.2:
		var rewards := LanSession.take_earned_rewards()
		SaveService.deserialize_inventory(_player.inventory, {"gold": 0, "slots": [], "equipment": {}})
		LanSession.restore_earned_rewards(rewards)
		_reward_restore_seen = _player.inventory.get_item_count("health_potion") == 2


func _finish_after_delay() -> void:
	await get_tree().create_timer(5.5 if _role == "host" else 4.8).timeout
	var result := {
		"role": _role,
		"ready": _ready_seen,
		"failed": _failed,
		"enemy_id": _enemy_id,
		"enemy_seen": _enemy_seen if _role == "client" else _enemy_id > 0,
		"initial_hp": _initial_hp,
		"minimum_hp": _minimum_hp,
		"hp_change_seen": _hp_change_seen,
		"removal_seen": _removal_seen,
		"far_request_sent": _far_request_sent,
		"far_hit_rejected": _far_hit_rejected,
		"loot_id": _loot_id,
		"loot_seen": _loot_seen if _role == "client" else _loot_id > 0,
		"loot_removed": _loot_removed,
		"loot_granted": _loot_granted,
		"loot_far_request_sent": _loot_far_request_sent,
		"loot_far_rejected": _loot_far_rejected,
		"reward_restore_seen": _reward_restore_seen,
		"full_bag_preserved": _full_bag_preserved,
		"partial_pickup_seen": _partial_pickup_seen,
		"critical_hit_seen": _critical_hit_seen,
		"life_steal_seen": _life_steal_seen,
	}
	var file := FileAccess.open(_output, FileAccess.WRITE)
	if file == null:
		get_tree().quit(2)
		return
	file.store_string(JSON.stringify(result))
	file.close()
	var ok := _ready_seen and not _failed and _enemy_id > 0 and _hp_change_seen and _removal_seen and _loot_id > 0 and _loot_removed
	if _role == "host":
		ok = ok and _far_hit_rejected and _loot_far_rejected and _full_bag_preserved and _partial_pickup_seen and _critical_hit_seen and _life_steal_seen
	else:
		ok = ok and _enemy_seen and _far_request_sent and _loot_seen and _loot_far_request_sent and _loot_granted and _reward_restore_seen and _full_bag_preserved and _partial_pickup_seen
	LanSession.stop(false)
	get_tree().quit(0 if ok else 1)


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			_role = arg.trim_prefix("--role=")
		elif arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
