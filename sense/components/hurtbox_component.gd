# Hurtbox Component - Reusable damage receiver
# Attach to Area2D node, configure collision shape separately per entity
class_name HurtboxComponent
extends Area2D

## Time before this hurtbox can receive damage again (i-frames)
@export var invincibility_time: float = 0.5

## Emitted when damage is received
signal damage_received(amount: int, knockback: float, from_position: Vector2)
## Emitted when the authority already resolved variance and critical chance.
signal resolved_damage_received(amount: int, critical: bool, knockback: float, from_position: Vector2)

var can_take_damage: bool = true
var _confirmed_result: Dictionary = {}

func _ready() -> void:
	# Layer/Mask should be set in scene inspector based on entity type:
	# Player: Layer 5 (PLAYER_HURTBOX), Mask: Layer 8 (ENEMY_HITBOX)
	# Enemy: Layer 6 (ENEMY_HURTBOX), Mask: Layer 7 (PLAYER_HITBOX)
	pass


## Called by legacy/raw damage sources. Returns false when invincibility rejects it.
func take_damage(amount: int, knockback: float, from_position: Vector2) -> bool:
	# print("[HURTBOX] take_damage called! Amount: ", amount, " can_take_damage: ", can_take_damage)
	# print("[HURTBOX] My layer: ", collision_layer, " My mask: ", collision_mask)
	if amount <= 0 or not can_take_damage:
		# print("[HURTBOX] Blocked - invincible!")
		return false
	
	can_take_damage = false
	# print("[HURTBOX] Emitting damage_received signal")
	damage_received.emit(amount, knockback, from_position)
	_release_invincibility.call_deferred()
	return true


## Called when the attacker/host has already produced one authoritative hit roll.
## The target confirms the amount it actually applied, allowing on-hit passives to
## consume the real result without changing the legacy damage signal contract.
func take_resolved_damage(amount: int, critical: bool, knockback: float, from_position: Vector2) -> Dictionary:
	if not can_take_damage or amount <= 0:
		return {}
	can_take_damage = false
	_confirmed_result = {}
	if resolved_damage_received.get_connections().is_empty():
		damage_received.emit(amount, knockback, from_position)
		confirm_resolved_damage(amount, critical)
	else:
		resolved_damage_received.emit(amount, critical, knockback, from_position)
	var result := _confirmed_result.duplicate()
	_confirmed_result = {}
	_release_invincibility.call_deferred()
	return result


func confirm_resolved_damage(amount: int, critical: bool) -> void:
	_confirmed_result = {"amount": maxi(amount, 0), "crit": critical}


func _release_invincibility() -> void:
	await get_tree().create_timer(invincibility_time).timeout
	can_take_damage = true


## Reset invincibility (useful when respawning)
func reset() -> void:
	can_take_damage = true
