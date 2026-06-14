extends KinematicBody2D
class_name Player

# GTA-inspired top-down player controller with smooth acceleration, collision, and interactions.

export var walk_speed: float = 210.0
export var drive_speed: float = 360.0
export var acceleration: float = 950.0
export var deceleration: float = 1200.0
export var save_id: String = "player"

var facing: Vector2 = Vector2.DOWN
var velocity: Vector2 = Vector2.ZERO
var money: int = 250
var in_vehicle := false
var vehicle_name := "On Foot"
var current_vehicle = null
var _saved_collision_layer := 0
var _saved_collision_mask := 0
var _visual: Node2D
var _body_rect: CanvasItem
var _weapon_pivot: Node2D

onready var health: HealthComponent = $HealthComponent
onready var stamina: StaminaComponent = $StaminaComponent
onready var combat: PlayerCombat = $Combat
onready var attack_hitbox: HitboxArea = $Combat/AttackHitbox
onready var camera: Camera2D = $Camera2D

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
	_setup_camera()
	apply_save_data(SaveManager.current_save_data)
	GameEvents.raise_money_changed(money)
	GameEvents.raise_mission_text_changed("Explore Sun City. Press E near cars, shops, and citizens.")
	GameEvents.raise_vehicle_status_changed(vehicle_name)

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameState.State.PLAYING:
		return
	if in_vehicle:
		_update_attached_vehicle_state()
		_handle_actions()
		return
	var input_vector = _get_input_velocity()
	var desired_velocity = input_vector * walk_speed
	var input_vector = _get_input_velocity()
	var target_speed = drive_speed if in_vehicle else walk_speed
	var desired_velocity = input_vector * target_speed
	var rate = acceleration if input_vector.length_squared() > 0.01 else deceleration
	velocity = _move_vector_toward(velocity, desired_velocity, rate * delta)
	velocity = move_and_slide(velocity)
	if velocity.length_squared() > 4.0:
		facing = velocity.normalized()
	_update_visuals(delta)
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
		money = int(stats.get("money", money))
		var max_hp = float(stats.get("max_health", health.max_health))
		var hp = float(stats.get("health", max_hp))
		health.set_health(hp, max_hp)

func capture_state() -> Dictionary:
	return {
		"position": {"x": global_position.x, "y": global_position.y},
		"health": health.current_health,
		"max_health": health.max_health,
		"money": money,
		"in_vehicle": in_vehicle
	}

func restore_state(state: Dictionary) -> void:
	if state.has("position"):
		var pos = state["position"]
		global_position = Vector2(float(pos.get("x", global_position.x)), float(pos.get("y", global_position.y)))
	if state.has("health"):
		health.set_health(float(state["health"]), float(state.get("max_health", health.max_health)))
	money = int(state.get("money", money))
	GameEvents.raise_money_changed(money)

func receive_damage(amount: float, source = null) -> float:
	var applied = health.take_damage(amount, source)
	if applied > 0.0:
		GameEvents.raise_player_damaged(applied, source)
	return applied

func apply_knockback(force: Vector2) -> void:
	velocity += force

func set_invincible_visual(active: bool) -> void:
	if _body_rect == null:
		return
	_body_rect.modulate = Color(1.0, 1.0, 1.0, 0.65) if active else Color(1.0, 1.0, 1.0, 1.0)

func add_money(amount: int) -> void:
	money = max(0, money + amount)
	GameEvents.raise_money_changed(money)
	_sync_stats_to_save_data()

func _setup_camera() -> void:
	if camera == null:
		return
	camera.current = true
	camera.smoothing_enabled = true
	camera.smoothing_speed = 4.5
	camera.drag_margin_h_enabled = true
	camera.drag_margin_v_enabled = true
	camera.drag_margin_left = 0.18
	camera.drag_margin_right = 0.18
	camera.drag_margin_top = 0.16
	camera.drag_margin_bottom = 0.16
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1600
	camera.limit_bottom = 1000

func _move_vector_toward(current: Vector2, target: Vector2, max_delta: float) -> Vector2:
	var diff = target - current
	var length = diff.length()
	if length <= max_delta or length <= 0.001:
		return target
	return current + diff / length * max_delta

func _get_input_velocity() -> Vector2:
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	return input_vector.normalized() if input_vector.length_squared() > 1.0 else input_vector

func _handle_actions() -> void:
	if Input.is_action_just_pressed("interact"):
		if in_vehicle:
			_exit_vehicle()
		else:
			_try_interact()

func _try_interact() -> void:
	var nearest = _find_nearest_interactable()
	var nearest = null
	var best_dist := 72.0
	for item in get_tree().get_nodes_in_group("city_interactable"):
		var dist = global_position.distance_to(item.global_position)
		if dist < best_dist:
			best_dist = dist
			nearest = item
	if nearest == null or not nearest.has_method("interact"):
		GameEvents.raise_mission_text_changed("No interaction nearby. Walk to a car, store, or citizen and press E.")
		return
	var result = nearest.interact(self)
	GameEvents.raise_mission_text_changed(str(result.get("title", "City")) + ": " + str(result.get("message", "")))
	if result.has("money_delta"):
		add_money(int(result["money_delta"]))
	if str(result.get("type", "")) == "vehicle" and result.has("vehicle"):
		_enter_vehicle(result["vehicle"])

func _find_nearest_interactable():
	var nearest = null
	var best_dist := 78.0
	for vehicle in get_tree().get_nodes_in_group("vehicles"):
		if vehicle.has_method("has_driver") and vehicle.has_driver():
			continue
		var vehicle_dist = global_position.distance_to(vehicle.global_position)
		if vehicle_dist < best_dist:
			best_dist = vehicle_dist
			nearest = vehicle
	for item in get_tree().get_nodes_in_group("city_interactable"):
		if item.is_in_group("vehicles"):
			continue
		var dist = global_position.distance_to(item.global_position)
		if dist < best_dist:
			best_dist = dist
			nearest = item
	return nearest

func _enter_vehicle(vehicle) -> void:
	if vehicle == null or vehicle.has_driver():
		return
	current_vehicle = vehicle
	in_vehicle = true
	vehicle_name = vehicle.vehicle_name
	velocity = Vector2.ZERO
	_saved_collision_layer = collision_layer
	_saved_collision_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	if _visual != null:
		_visual.visible = false
	vehicle.enter(self)
	_update_attached_vehicle_state()
	GameEvents.raise_vehicle_status_changed("Driving")
	GameEvents.raise_mission_text_changed("Driving %s. WASD accelerates, reverses, and steers. Press E to exit." % vehicle_name)

func _exit_vehicle() -> void:
	if current_vehicle == null:
		return
	var exit_pos = current_vehicle.get_exit_position()
	current_vehicle.exit()
	global_position = exit_pos
	in_vehicle = false
	vehicle_name = "On Foot"
	current_vehicle = null
	collision_layer = _saved_collision_layer if _saved_collision_layer != 0 else GameConstants.LAYER_PLAYER
	collision_mask = _saved_collision_mask if _saved_collision_mask != 0 else GameConstants.LAYER_WORLD
	if _visual != null:
		_visual.visible = true
		_visual.scale = Vector2.ONE
	GameEvents.raise_vehicle_status_changed("On Foot")
	GameEvents.raise_mission_text_changed("Exited vehicle. Walk to another car, store, or citizen and press E.")

func _update_attached_vehicle_state() -> void:
	if current_vehicle == null or not is_instance_valid(current_vehicle):
		in_vehicle = false
		GameEvents.raise_vehicle_status_changed("On Foot")
		return
	global_position = current_vehicle.global_position
	facing = Vector2.RIGHT.rotated(current_vehicle.rotation)
	if str(result.get("type", "")) == "vehicle":
		_enter_vehicle(str(result.get("title", "Vehicle")))

func _enter_vehicle(name: String) -> void:
	in_vehicle = true
	vehicle_name = name
	walk_speed = 260.0
	_visual.scale = Vector2(1.25, 1.05)
	GameEvents.raise_vehicle_status_changed("Driving: %s" % vehicle_name)

func _exit_vehicle() -> void:
	in_vehicle = false
	vehicle_name = "On Foot"
	walk_speed = 210.0
	_visual.scale = Vector2.ONE
	GameEvents.raise_vehicle_status_changed(vehicle_name)
	GameEvents.raise_mission_text_changed("Exited vehicle. Visit a store or talk to a citizen for missions.")

func _update_visuals(delta: float) -> void:
	if _weapon_pivot != null and facing.length_squared() > 0.01:
		_weapon_pivot.rotation = facing.angle()
	if _visual != null:
		var bob = sin(OS.get_ticks_msec() * 0.012) * (1.5 if velocity.length_squared() > 20.0 else 0.0)
		_visual.position = _visual.position.linear_interpolate(Vector2(0, bob), min(1.0, delta * 12.0))
		if facing.x != 0:
			_visual.scale.x = abs(_visual.scale.x) * sign(facing.x)

func _on_health_changed(current: float, maximum: float) -> void:
	GameEvents.raise_player_health_changed(current, maximum)
	_sync_stats_to_save_data()

func _on_stamina_changed(current: float, maximum: float) -> void:
	GameEvents.raise_player_stamina_changed(current, maximum)

func _on_died() -> void:
	GameEvents.raise_player_died()
	GameManager.transition_to(GameState.State.GAME_OVER)
	yield(get_tree().create_timer(1.5), "timeout")
	GameManager.return_to_main_menu()

func _sync_stats_to_save_data() -> void:
	if SaveManager.current_save_data.empty():
		return
	SaveManager.current_save_data["player_position"] = {"x": global_position.x, "y": global_position.y}
	SaveManager.current_save_data["player_stats"] = {
		"health": health.current_health,
		"max_health": health.max_health,
		"money": money
	}
