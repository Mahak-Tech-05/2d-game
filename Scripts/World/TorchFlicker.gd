extends Node2D

# Subtle torch light pulse — very cheap (modulate only).

export var min_energy: float = 0.65
export var max_energy: float = 1.0
export var speed: float = 3.5

var _target: CanvasItem
var _time: float = 0.0


func _ready() -> void:
	_target = get_node_or_null("Flame")
	if _target == null and get_child_count() > 0:
		_target = get_child(0)
	_time = rand_range(0.0, 5.0)


func _process(delta: float) -> void:
	if _target == null:
		return
	_time += delta * speed
	var wave = (sin(_time) + sin(_time * 1.7)) * 0.5
	var energy = lerp(min_energy, max_energy, 0.5 + wave * 0.5)
	_target.modulate = Color(energy, energy * 0.85, energy * 0.55, 1.0)
