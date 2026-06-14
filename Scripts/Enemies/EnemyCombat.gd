extends Node
class_name EnemyCombat

# Enemy melee attack timing and hitbox control.

signal attack_started
signal attack_finished

export var attack_duration: float = 0.28
export var recovery_time: float = 0.35

var is_attacking: bool = false
var _owner: KinematicBody2D
var _hitbox: HitboxArea
var _attack_timer: Timer
var _recovery_timer: Timer


func setup(owner_ref: KinematicBody2D, hitbox: HitboxArea, damage: float) -> void:
	_owner = owner_ref
	_hitbox = hitbox
	_hitbox.configure(owner_ref, damage)


func _ready() -> void:
	_attack_timer = _make_timer("AttackTimer", attack_duration)
	_recovery_timer = _make_timer("RecoveryTimer", recovery_time)
	_attack_timer.connect("timeout", self, "_on_attack_finished")


func can_attack() -> bool:
	return not is_attacking and _recovery_timer.is_stopped()


func try_attack(facing: Vector2) -> bool:
	if not can_attack() or _hitbox == null:
		return false

	is_attacking = true
	_position_hitbox(facing)
	emit_signal("attack_started")
	_hitbox.activate()
	_attack_timer.start()
	return true


func _on_attack_finished() -> void:
	is_attacking = false
	emit_signal("attack_finished")
	_recovery_timer.start()


func _position_hitbox(facing: Vector2) -> void:
	var direction = facing
	if direction.length_squared() < 0.01:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	_hitbox.position = direction * 24.0
	_hitbox.rotation = direction.angle()


func _make_timer(timer_name: String, wait_time: float) -> Timer:
	var timer = Timer.new()
	timer.name = timer_name
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	return timer
