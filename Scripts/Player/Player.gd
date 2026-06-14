extends KinematicBody2D
class_name Player

# Top-down player movement, save integration, and combat delegation.

export var move_speed: float = 165.0
export var save_id: String = "player"

var facing: Vector2 = Vector2.DOWN
var _knockback_velocity: Vector2 = Vector2.ZERO
var _visual: Node2D
var _body_rect: CanvasItem
var _weapon_pivot: Node2D

onready var health: HealthComponent = $HealthComponent
onready var stamina: StaminaComponent = $StaminaComponent
onready var combat: PlayerCombat = $Combat
onready var attack_hitbox: HitboxArea = $Combat/AttackHitbox


func _enter_tree() -> void:
	add_to_group(GameConstants.GROUP_PLAYER)
	SaveManager.register_saveable(self)


func _exit_tree() -> void:
	if SaveManager != null:
		SaveManager.unregister_saveable(self)


func _ready() -> void:
	collision_layer = GameConstants.LAYER_PLAYER
	collision_mask = GameConstants.LAYER_WORLD

	combat.setup(self, stamina, attack_hitbox)

	health.connect("health_changed", self, "_on_health_changed")
	health.connect("died", self, "_on_died")
	stamina.connect("stamina_changed", self, "_on_stamina_changed")

	_visual = $Visual
	_body_rect = $Visual/Body
	_weapon_pivot = $Visual/WeaponPivot

	combat.connect("attack_started", self, "_on_attack_started")
	apply_save_data(SaveManager.current_save_data)


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameState.State.PLAYING:
		return

	_knockback_velocity = GameConstants.vector_move_toward_zero(_knockback_velocity, 420.0 * delta)

	var velocity = _get_input_velocity()
	if combat.is_dodging():
		velocity = combat.get_override_velocity()
	elif combat.can_move():
		velocity = velocity * move_speed
	else:
		velocity = Vector2.ZERO

	velocity += _knockback_velocity
	velocity = move_and_slide(velocity)

	if velocity.length_squared() > 4.0 and combat.can_move():
		facing = velocity.normalized()

	_update_visuals()
	_handle_actions()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		get_tree().set_input_as_handled()


func apply_save_data(save_data: Dictionary) -> void:
	if save_data.empty():
		return

	if save_data.has("player_position"):
		var pos = save_data["player_position"]
		global_position = Vector2(float(pos.get("x", global_position.x)), float(pos.get("y", global_position.y)))

	if save_data.has("player_stats"):
		var stats = save_data["player_stats"]
		var max_hp = float(stats.get("max_health", health.max_health))
		var hp = float(stats.get("health", max_hp))
		health.set_health(hp, max_hp)

		var max_sp = float(stats.get("max_stamina", stamina.max_stamina))
		var sp = float(stats.get("stamina", max_sp))
		stamina.set_stamina(sp, max_sp)


func capture_state() -> Dictionary:
	return {
		"position": {"x": global_position.x, "y": global_position.y},
		"health": health.current_health,
		"max_health": health.max_health,
		"stamina": stamina.current_stamina,
		"max_stamina": stamina.max_stamina
	}


func restore_state(state: Dictionary) -> void:
	if state.has("position"):
		var pos = state["position"]
		global_position = Vector2(float(pos.get("x", global_position.x)), float(pos.get("y", global_position.y)))
	if state.has("health"):
		health.set_health(float(state["health"]), float(state.get("max_health", health.max_health)))
	if state.has("stamina"):
		stamina.set_stamina(float(state["stamina"]), float(state.get("max_stamina", stamina.max_stamina)))


func receive_damage(amount: float, source = null) -> float:
	if combat.is_invincible:
		return 0.0

	health.invincible = false
	var applied = health.take_damage(amount, source)
	if applied > 0.0:
		combat.on_damaged()
		GameEvents.raise_player_damaged(applied, source)
	return applied


func apply_knockback(force: Vector2) -> void:
	_knockback_velocity += force


func set_invincible_visual(active: bool) -> void:
	if _body_rect == null:
		return
	if active:
		_body_rect.modulate = Color(1.0, 1.0, 1.0, 0.55)
	else:
		_body_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _get_input_velocity() -> Vector2:
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()
	return input_vector


func _handle_actions() -> void:
	if not combat.can_act():
		return

	if Input.is_action_just_pressed("attack"):
		var aim_direction = _get_aim_direction()
		if aim_direction.length_squared() > 0.01:
			facing = aim_direction.normalized()
		combat.try_attack(facing)

	if Input.is_action_just_pressed("dodge"):
		var dodge_dir = _get_input_velocity()
		combat.try_dodge(dodge_dir, facing)


func _get_aim_direction() -> Vector2:
	var mouse_pos = get_global_mouse_position()
	return mouse_pos - global_position


func _update_visuals() -> void:
	if _weapon_pivot != null and facing.length_squared() > 0.01:
		_weapon_pivot.rotation = facing.angle()

	if _visual != null and combat.is_attacking():
		_visual.scale = Vector2(1.06, 1.06)
	elif _visual != null:
		_visual.scale = Vector2.ONE


func _on_attack_started() -> void:
	var slash = load("res://Scripts/Effects/SlashEffect.gd").new()
	get_tree().current_scene.add_child(slash)
	slash.setup(global_position, facing, GamePalette.PLAYER_BLADE)


func _on_health_changed(current: float, maximum: float) -> void:
	GameEvents.raise_player_health_changed(current, maximum)
	_sync_stats_to_save_data()


func _on_stamina_changed(current: float, maximum: float) -> void:
	GameEvents.raise_player_stamina_changed(current, maximum)
	_sync_stats_to_save_data()


func _on_died() -> void:
	GameEvents.raise_player_died()
	GameManager.transition_to(GameState.State.GAME_OVER)
	# Lightweight game-over flow for Phase 2: return to menu after brief delay.
	yield(get_tree().create_timer(1.5), "timeout")
	GameManager.return_to_main_menu()


func _sync_stats_to_save_data() -> void:
	if SaveManager.current_save_data.empty():
		return

	SaveManager.current_save_data["player_position"] = {
		"x": global_position.x,
		"y": global_position.y
	}
	SaveManager.current_save_data["player_stats"] = {
		"level": int(SaveManager.current_save_data.get("player_stats", {}).get("level", 1)),
		"experience": int(SaveManager.current_save_data.get("player_stats", {}).get("experience", 0)),
		"health": health.current_health,
		"max_health": health.max_health,
		"stamina": stamina.current_stamina,
		"max_stamina": stamina.max_stamina,
		"souls": int(SaveManager.current_save_data.get("player_stats", {}).get("souls", 0))
	}
