extends KinematicBody2D
class_name CityVehicle

export var vehicle_name := "Compact"
export var drive_speed := 310.0
export var acceleration := 900.0
export var brake := 1100.0

var velocity := Vector2.ZERO
var driver = null

func _ready() -> void:
	add_to_group("vehicles")
	collision_layer = GameConstants.LAYER_PLAYER
	collision_mask = GameConstants.LAYER_WORLD

func enter(player) -> void:
	driver = player
	visible = true
	set_physics_process(true)

func exit() -> void:
	driver = null
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if driver == null:
		return
	global_position = driver.global_position
