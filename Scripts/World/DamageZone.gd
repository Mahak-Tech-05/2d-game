extends Area2D

# Environmental hazard to test player damage and invincibility frames.

export var damage_per_tick: float = 8.0
export var tick_interval: float = 0.6

var _tick_timer: Timer


func _ready() -> void:
	collision_layer = GameConstants.LAYER_ENEMY_HITBOX
	collision_mask = GameConstants.LAYER_PLAYER

	_tick_timer = Timer.new()
	_tick_timer.wait_time = tick_interval
	_tick_timer.one_shot = false
	_tick_timer.autostart = true
	add_child(_tick_timer)
	_tick_timer.connect("timeout", self, "_on_tick")

	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(GameConstants.GROUP_PLAYER):
		_apply_damage(body)


func _on_tick() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group(GameConstants.GROUP_PLAYER):
			_apply_damage(body)


func _apply_damage(body: Node) -> void:
	if body.has_method("receive_damage"):
		body.receive_damage(damage_per_tick, self)


func _on_body_exited(_body: Node) -> void:
	pass
