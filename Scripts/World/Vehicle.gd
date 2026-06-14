extends KinematicBody2D
class_name CityVehicle

# Drivable top-down vehicle controller. Uses primitive physics and no textures for low-spec machines.

export var vehicle_name := "Compact"
export var max_forward_speed := 430.0
export var max_reverse_speed := 170.0
export var acceleration := 620.0
export var brake_force := 840.0
export var rolling_friction := 360.0
export var turn_speed := 3.0
export var interaction_radius := 78.0

var speed := 0.0
var velocity := Vector2.ZERO
var driver: Node = null

func _ready() -> void:
	add_to_group("vehicles")
	add_to_group("city_interactable")
	collision_layer = GameConstants.LAYER_PLAYER
	collision_mask = GameConstants.LAYER_WORLD
	set_physics_process(false)

func interact(_player) -> Dictionary:
	return {"type": "vehicle", "title": vehicle_name, "message": "Entered vehicle.", "vehicle": self}

func enter(player: Node) -> void:
	driver = player
	set_physics_process(true)

func exit() -> void:
	driver = null
	speed = 0.0
	velocity = Vector2.ZERO
	set_physics_process(false)

func has_driver() -> bool:
	return driver != null

func get_exit_position() -> Vector2:
	var side = Vector2.UP.rotated(rotation)
	return global_position + side * 46.0

func _physics_process(delta: float) -> void:
	if driver == null:
		return
	_update_speed(delta)
	_update_rotation(delta)
	var forward = Vector2.RIGHT.rotated(rotation)
	velocity = forward * speed
	velocity = move_and_slide(velocity)
	speed = velocity.dot(forward)

func _update_speed(delta: float) -> void:
	var throttle = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	if throttle > 0.05:
		speed = _move_float_toward(speed, max_forward_speed, acceleration * delta)
	elif throttle < -0.05:
		speed = _move_float_toward(speed, -max_reverse_speed, brake_force * delta)
	else:
		speed = _move_float_toward(speed, 0.0, rolling_friction * delta)

func _update_rotation(delta: float) -> void:
	var steer = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if abs(steer) <= 0.01 or abs(speed) <= 8.0:
		return
	var direction_factor = 1.0 if speed >= 0.0 else -1.0
	var speed_factor = clamp(abs(speed) / max_forward_speed, 0.25, 1.0)
	rotation += steer * turn_speed * speed_factor * direction_factor * delta

func _move_float_toward(current: float, target: float, max_delta: float) -> float:
	if abs(target - current) <= max_delta:
		return target
	return current + sign(target - current) * max_delta
