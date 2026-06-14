extends Node
class_name EnemyAI

# Lightweight enemy state machine (no pathfinding — low CPU cost).

enum State { IDLE, PATROL, CHASE, ATTACK, STUNNED, DEAD }

signal state_changed(previous, current)

export var patrol_radius: float = 72.0
export var idle_time: float = 1.2
export var stun_duration: float = 0.25

var current_state: int = State.IDLE
var facing: Vector2 = Vector2.DOWN

var _enemy: KinematicBody2D
var _combat: EnemyCombat
var _detection_range: float = 160.0
var _attack_range: float = 34.0
var _move_speed: float = 85.0
var _chase_speed: float = 120.0

var _spawn_origin: Vector2 = Vector2.ZERO
var _patrol_target: Vector2 = Vector2.ZERO
var _idle_timer: float = 0.0
var _stun_timer: float = 0.0
var _is_active: bool = true


func setup(
	enemy_ref: KinematicBody2D,
	combat_ref: EnemyCombat,
	detection_range: float,
	attack_range: float,
	move_speed: float,
	chase_speed: float
) -> void:
	_enemy = enemy_ref
	_combat = combat_ref
	_detection_range = detection_range
	_attack_range = attack_range
	_move_speed = move_speed
	_chase_speed = chase_speed
	_spawn_origin = enemy_ref.global_position
	_pick_patrol_target()


func set_active(value: bool) -> void:
	_is_active = value
	if not value:
		_transition_to(State.IDLE)


func mark_dead() -> void:
	_transition_to(State.DEAD)


func on_damaged() -> void:
	if current_state != State.DEAD:
		_stun_timer = stun_duration
		_transition_to(State.STUNNED)


func process_ai(delta: float) -> Vector2:
	if not _is_active or _enemy == null or current_state == State.DEAD:
		return Vector2.ZERO

	match current_state:
		State.IDLE:
			return _process_idle(delta)
		State.PATROL:
			return _process_patrol(delta)
		State.CHASE:
			return _process_chase(delta)
		State.ATTACK:
			return _process_attack()
		State.STUNNED:
			return _process_stunned(delta)

	return Vector2.ZERO


func _process_idle(delta: float) -> Vector2:
	var player = _get_player()
	if _can_see(player):
		_transition_to(State.CHASE)
		return Vector2.ZERO

	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_transition_to(State.PATROL)
	return Vector2.ZERO


func _process_patrol(_delta: float) -> Vector2:
	var player = _get_player()
	if _can_see(player):
		_transition_to(State.CHASE)
		return Vector2.ZERO

	var to_target = _patrol_target - _enemy.global_position
	if to_target.length() < 8.0:
		_idle_timer = idle_time
		_transition_to(State.IDLE)
		return Vector2.ZERO

	facing = to_target.normalized()
	return facing * _move_speed


func _process_chase(_delta: float) -> Vector2:
	var player = _get_player()
	if player == null:
		_transition_to(State.PATROL)
		return Vector2.ZERO

	var offset = player.global_position - _enemy.global_position
	var distance = offset.length()

	if distance > _detection_range * 1.35:
		_transition_to(State.PATROL)
		return Vector2.ZERO

	facing = offset.normalized()

	if distance <= _attack_range and _combat.can_attack():
		_transition_to(State.ATTACK)
		_combat.try_attack(facing)
		return Vector2.ZERO

	return facing * _chase_speed


func _process_attack() -> Vector2:
	if _combat != null and not _combat.is_attacking:
		_transition_to(State.CHASE)
	return Vector2.ZERO


func _process_stunned(delta: float) -> Vector2:
	_stun_timer -= delta
	if _stun_timer <= 0.0:
		_transition_to(State.CHASE)
	return Vector2.ZERO


func _transition_to(new_state: int) -> void:
	if current_state == new_state:
		return
	var previous = current_state
	current_state = new_state
	if new_state == State.PATROL:
		_pick_patrol_target()
	emit_signal("state_changed", previous, new_state)


func _pick_patrol_target() -> void:
	var angle = randf() * PI * 2.0
	var offset = Vector2(cos(angle), sin(angle)) * GameConstants.rand_range_float(patrol_radius * 0.35, patrol_radius)
	_patrol_target = _spawn_origin + offset


func _get_player() -> Node:
	var players = get_tree().get_nodes_in_group(GameConstants.GROUP_PLAYER)
	if players.empty():
		return null
	return players[0]


func _can_see(player: Node) -> bool:
	if player == null:
		return false
	return _enemy.global_position.distance_to(player.global_position) <= _detection_range
