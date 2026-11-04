extends Node
## Two-process loopback harness for the real ENet LAN foundation.

var _role := "host"
var _output := "/tmp/emberfield-lan-peer.json"
var _ready_seen := false
var _last_status := ""
var _failed := false
var _max_remote_seen := 0


func _ready() -> void:
	_parse_args()
	var player := CharacterBody2D.new()
	player.name = "TestPlayer"
	player.position = Vector2(100, 200) if _role == "host" else Vector2(150, 220)
	add_child(player)
	LanSession.bind(self, player)
	LanSession.session_ready.connect(func(_mode: String, _zone: String) -> void: _ready_seen = true)
	LanSession.status_changed.connect(func(text: String, is_error: bool) -> void:
		_last_status = text
		_failed = _failed or is_error
	)
	if _role == "host":
		_failed = LanSession.start_host() != OK
	else:
		_failed = LanSession.join_host("127.0.0.1") != OK
	_finish_after_delay.call_deferred()


func _process(_delta: float) -> void:
	_max_remote_seen = maxi(_max_remote_seen, LanSession.remote_avatars.size())


func _finish_after_delay() -> void:
	await get_tree().create_timer(3.5 if _role == "host" else 2.0).timeout
	var result := {
		"role": _role,
		"ready": _ready_seen,
		"failed": _failed,
		"active": LanSession.is_active(),
		"peer_names": LanSession.peer_names.size(),
		"remote_avatars": LanSession.remote_avatars.size(),
		"max_remote_seen": _max_remote_seen,
		"status": _last_status,
	}
	var file := FileAccess.open(_output, FileAccess.WRITE)
	if file == null:
		push_error("Could not write LAN test result")
		get_tree().quit(2)
		return
	file.store_string(JSON.stringify(result))
	file.close()
	var ok := _ready_seen and not _failed and LanSession.is_active() and _max_remote_seen >= 1
	LanSession.stop(false)
	get_tree().quit(0 if ok else 1)


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			_role = arg.trim_prefix("--role=")
		elif arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
