extends KinematicBody2D
class_name TrafficCar

# Autonomous traffic vehicle that follows lane waypoints and brakes near obstacles.

export var cruise_speed := 165.0
export var acceleration := 420.0
export var brake_force := 720.0
export var obstacle_probe_distance := 58.0

var velocity := Vector2.ZERO
var speed := 0.0
var _route := []
var _target_index := 0

func setup(route: Array, color: Color) -> void:
	_route = route.duplicate()
	if not _route.empty():
		global_position = _route[0]
		_target_index = 1 % _route.size()
	_add_visual(color)

func _ready() -> void:
	add_to_group("traffic_cars")
	collision_layer = GameConstants.LAYER_INTERACTABLES
	collision_mask = GameConstants.LAYER_WORLD

func _physics_process(delta: float) -> void:
	if _route.size() < 2:
		return
	var target: Vector2 = _route[_target_index]
	var to_target = target - global_position
	if to_target.length() < 14.0:
		_target_index = (_target_index + 1) % _route.size()
		target = _route[_target_index]
		to_target = target - global_position
	var desired_dir = to_target.normalized()
	rotation = lerp_angle(rotation, desired_dir.angle(), min(1.0, delta * 5.0))
	var target_speed = 0.0 if _has_obstacle_ahead(desired_dir) else cruise_speed
	var rate = brake_force if target_speed < speed else acceleration
	speed = _move_float_toward(speed, target_speed, rate * delta)
	velocity = desired_dir * speed
	velocity = move_and_slide(velocity)

func _has_obstacle_ahead(dir: Vector2) -> bool:
	var space = get_world_2d().direct_space_state
	var from = global_position + dir * 18.0
	var to = global_position + dir * obstacle_probe_distance
	var hit = space.intersect_ray(from, to, [self], GameConstants.LAYER_WORLD | GameConstants.LAYER_INTERACTABLES)
	return not hit.empty()

func _move_float_toward(current: float, target: float, max_delta: float) -> float:
	if abs(target - current) <= max_delta:
		return target
	return current + sign(target - current) * max_delta

func _add_visual(color: Color) -> void:
	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.extents = Vector2(28, 14)
	shape.shape = box
	add_child(shape)
	var body = Polygon2D.new()
	body.color = color
	body.polygon = PoolVector2Array([Vector2(-30, -13), Vector2(24, -13), Vector2(32, 0), Vector2(24, 15), Vector2(-28, 15), Vector2(-34, 0)])
	add_child(body)
	var glass = ColorRect.new()
	glass.rect_position = Vector2(-12, -9)
	glass.rect_size = Vector2(24, 8)
	glass.color = GamePalette.VEHICLE_GLASS
	add_child(glass)
