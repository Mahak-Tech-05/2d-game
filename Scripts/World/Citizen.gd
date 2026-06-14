extends KinematicBody2D
class_name CityCitizen

# Lightweight pedestrian AI. Citizens stay on supplied sidewalk waypoints and pause before road crossings.

const MAX_SPEED := 58.0
const ARRIVE_DISTANCE := 8.0
const ROAD_PAUSE_SECONDS := 0.8

var display_name := "Citizen"
var velocity := Vector2.ZERO
var _waypoints := []
var _target_index := 0
var _wait_time := 0.0
var _rng := RandomNumberGenerator.new()
var _dialogue := ["Hello", "Need help?", "Nice weather", "Get lost"]

func setup(name: String, waypoints: Array, seed: int) -> void:
	display_name = name
	_waypoints = waypoints.duplicate()
	_rng.seed = seed
	if _waypoints.empty():
		_waypoints = [global_position]
	_target_index = int(_rng.randi_range(0, _waypoints.size() - 1))
	global_position = _waypoints[_target_index]
	_pick_next_target()

func _ready() -> void:
	add_to_group("citizens")
	add_to_group("city_interactable")
	collision_layer = GameConstants.LAYER_INTERACTABLES
	collision_mask = GameConstants.LAYER_WORLD

func interact(_player) -> Dictionary:
	var index = int(_rng.randi_range(0, _dialogue.size() - 1))
	return {"type": "npc", "title": display_name, "message": _dialogue[index]}

func _physics_process(delta: float) -> void:
	if _wait_time > 0.0:
		_wait_time -= delta
		velocity = Vector2.ZERO
		return
	var target: Vector2 = _waypoints[_target_index]
	var to_target = target - global_position
	if to_target.length() <= ARRIVE_DISTANCE:
		_pick_next_target()
		return
	velocity = to_target.normalized() * MAX_SPEED
	velocity = move_and_slide(velocity)

func _pick_next_target() -> void:
	if _waypoints.size() <= 1:
		return
	var previous = _target_index
	var current = global_position
	var candidates = []
	for i in range(_waypoints.size()):
		if i == previous:
			continue
		var point: Vector2 = _waypoints[i]
		if abs(point.x - current.x) < 6.0 or abs(point.y - current.y) < 6.0:
			candidates.append(i)
	if candidates.empty():
		while _target_index == previous:
			_target_index = int(_rng.randi_range(0, _waypoints.size() - 1))
	else:
		_target_index = candidates[int(_rng.randi_range(0, candidates.size() - 1))]
	if _is_road_edge(global_position) or _is_road_edge(_waypoints[_target_index]):
		_wait_time = ROAD_PAUSE_SECONDS + _rng.randf_range(0.0, 0.9)

func _is_road_edge(pos: Vector2) -> bool:
	var road_x = [360.0, 820.0, 1240.0]
	var road_y = [300.0, 650.0]
	for x in road_x:
		var dx = abs(pos.x - x)
		if dx > 66.0 and dx < 96.0:
			return true
	for y in road_y:
		var dy = abs(pos.y - y)
		if dy > 66.0 and dy < 96.0:
			return true
	return false
