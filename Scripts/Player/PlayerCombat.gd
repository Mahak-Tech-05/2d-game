extends Node
class_name PlayerCombat

# Player attack, dodge, and invincibility handling.

enum State { IDLE, ATTACKING, DODGING }

signal attack_started
signal attack_finished
signal dodge_started
signal dodge_finished

export var attack_stamina_cost: float = 12.0
export var dodge_stamina_cost: float = 22.0
export var attack_duration: float = 0.32
export var dodge_duration: float = 0.28
export var dodge_speed: float = 320.0
export var dodge_cooldown: float = 0.15
export var invincibility_after_hit: float = 0.45

var state: int = State.IDLE
var dodge_velocity: Vector2 = Vector2.ZERO
var is_invincible: bool = false

var _player: KinematicBody2D
var _stamina: StaminaComponent
var _hitbox: HitboxArea
var _attack_timer: Timer
var _dodge_timer: Timer
var _cooldown_timer: Timer
var _invincibility_timer: Timer


func setup(player: KinematicBody2D, stamina: StaminaComponent, hitbox: HitboxArea) -> void:
	_player = player
	_stamina = stamina
	_hitbox = hitbox
	_hitbox.configure(player)


func _ready() -> void:
	_attack_timer = _create_timer("AttackTimer", attack_duration)
	_dodge_timer = _create_timer("DodgeTimer", dodge_duration)
	_cooldown_timer = _create_timer("CooldownTimer", dodge_cooldown)
	_invincibility_timer = _create_timer("InvincibilityTimer", invincibility_after_hit)

	_attack_timer.connect("timeout", self, "_on_attack_finished")
	_dodge_timer.connect("timeout", self, "_on_dodge_finished")
	_invincibility_timer.connect("timeout", self, "_on_invincibility_finished")


func can_move() -> bool:
	return state != State.ATTACKING


func can_act() -> bool:
	return state == State.IDLE and _cooldown_timer.is_stopped()


func is_attacking() -> bool:
	return state == State.ATTACKING


func is_dodging() -> bool:
	return state == State.DODGING


func get_override_velocity() -> Vector2:
	if state == State.DODGING:
		return dodge_velocity
	return Vector2.ZERO


func try_attack(facing: Vector2) -> bool:
	if not can_act() or _stamina == null:
		return false
	if not _stamina.consume(attack_stamina_cost):
		return false

	state = State.ATTACKING
	_position_hitbox(facing)
	emit_signal("attack_started")
	_hitbox.activate()
	_attack_timer.start()
	return true


func try_dodge(direction: Vector2, fallback_facing: Vector2) -> bool:
	if not can_act() or _stamina == null:
		return false
	if not _stamina.consume(dodge_stamina_cost):
		return false

	if direction.length_squared() < 0.01:
		direction = fallback_facing
	if direction.length_squared() < 0.01:
		direction = Vector2.RIGHT

	direction = direction.normalized()
	state = State.DODGING
	dodge_velocity = direction * dodge_speed
	_set_invincible(true)
	emit_signal("dodge_started")
	_dodge_timer.start()
	return true


func on_damaged() -> void:
	_set_invincible(true)
	_invincibility_timer.start()


func _on_attack_finished() -> void:
	state = State.IDLE
	emit_signal("attack_finished")
	_cooldown_timer.start()


func _on_dodge_finished() -> void:
	state = State.IDLE
	dodge_velocity = Vector2.ZERO
	emit_signal("dodge_finished")
	_set_invincible(false)
	_cooldown_timer.start()


func _on_invincibility_finished() -> void:
	if state != State.DODGING:
		_set_invincible(false)


func _set_invincible(value: bool) -> void:
	is_invincible = value
	if _player != null and _player.has_method("set_invincible_visual"):
		_player.set_invincible_visual(value)


func _position_hitbox(facing: Vector2) -> void:
	if _hitbox == null:
		return

	var direction = facing
	if direction.length_squared() < 0.01:
		direction = Vector2.RIGHT
	direction = direction.normalized()

	_hitbox.position = direction * 28.0
	_hitbox.rotation = direction.angle()


func _create_timer(timer_name: String, wait_time: float) -> Timer:
	var timer = Timer.new()
	timer.name = timer_name
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	return timer
