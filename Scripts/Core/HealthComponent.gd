extends Node
class_name HealthComponent

# Reusable health pool. Attach to any entity that can take damage.

signal health_changed(current, maximum)
signal damaged(amount, source)
signal healed(amount)
signal died

export var max_health: float = 100.0
export var start_at_max: bool = true
export var invincible: bool = false

var current_health: float = 100.0


func _ready() -> void:
	if start_at_max:
		current_health = max_health
	else:
		current_health = clamp(current_health, 0.0, max_health)
	_emit_health_changed()


func is_alive() -> bool:
	return current_health > 0.0


func get_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health


func set_max_health(value: float, refill: bool = false) -> void:
	max_health = max(value, 1.0)
	if refill:
		current_health = max_health
	else:
		current_health = clamp(current_health, 0.0, max_health)
	_emit_health_changed()


func set_health(value: float, maximum: float = -1.0) -> void:
	if maximum > 0.0:
		max_health = maximum
	current_health = clamp(value, 0.0, max_health)
	_emit_health_changed()
	if current_health <= 0.0:
		emit_signal("died")


func take_damage(amount: float, source = null) -> float:
	if not is_alive() or invincible or amount <= 0.0:
		return 0.0

	var applied = min(amount, current_health)
	current_health -= applied
	emit_signal("damaged", applied, source)
	_emit_health_changed()

	if current_health <= 0.0:
		emit_signal("died")

	return applied


func heal(amount: float) -> float:
	if not is_alive() or amount <= 0.0:
		return 0.0

	var missing = max_health - current_health
	var applied = min(amount, missing)
	current_health += applied
	emit_signal("healed", applied)
	_emit_health_changed()
	return applied


func _emit_health_changed() -> void:
	emit_signal("health_changed", current_health, max_health)
