extends KinematicBody2D

# Lightweight combat target for Phase 2 testing (replaced by enemy AI in Phase 3).

export var max_health: float = 80.0
export var respawn_seconds: float = 4.0

var _spawn_position: Vector2 = Vector2.ZERO
var _knockback: Vector2 = Vector2.ZERO
var _body: CanvasItem

onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	_spawn_position = global_position
	_body = $Visual/Body

	health.set_max_health(max_health, true)
	health.connect("health_changed", self, "_on_health_changed")
	health.connect("died", self, "_on_died")

	collision_layer = GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD


func _physics_process(delta: float) -> void:
	_knockback = GameConstants.vector_move_toward_zero(_knockback, 300.0 * delta)
	move_and_slide(_knockback)


func receive_damage(amount: float, source = null) -> float:
	return health.take_damage(amount, source)


func apply_knockback(force: Vector2) -> void:
	_knockback += force


func _on_health_changed(current: float, maximum: float) -> void:
	if _body == null:
		return
	var ratio = 0.0 if maximum <= 0.0 else current / maximum
	_body.modulate = Color(0.55 + ratio * 0.3, 0.2, 0.22, 1.0)


func _on_died() -> void:
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	yield(get_tree().create_timer(respawn_seconds), "timeout")
	_respawn()


func _respawn() -> void:
	global_position = _spawn_position
	health.set_health(max_health, max_health)
	visible = true
	collision_layer = GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD
	set_physics_process(true)
