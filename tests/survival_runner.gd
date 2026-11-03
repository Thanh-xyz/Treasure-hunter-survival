extends Node2D
## Standalone runner: godot --headless --path . res://tests/SurvivalTests.tscn


func _ready() -> void:
	var t := preload("res://tests/survival_tests.gd").new()
	add_child(t)
	var ok: bool = await t.run_all()
	get_tree().quit(0 if ok else 1)
