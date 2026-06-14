extends Node
class_name StaminaComponent

# Reusable stamina pool with passive regeneration.

signal stamina_changed(current, maximum)
signal stamina_depleted
signal stamina_restored

export var max_stamina: float = 100.0
export var start_at_max: bool = true
export var regen_per_second: float = 18.0
export var regen_delay_seconds: float = 0.8

var current_stamina: float = 100.0
var _regen_blocked: float = 0.0


func _ready() -> void:
	if start_at_max:
		current_stamina = max_stamina
	else:
		current_stamina = clamp(current_stamina, 0.0, max_stamina)
	_emit_stamina_changed()


func _process(delta: float) -> void:
	if not _can_regen():
		if _regen_blocked > 0.0:
			_regen_blocked = max(_regen_blocked - delta, 0.0)
		return

	var before = current_stamina
	current_stamina = min(current_stamina + regen_per_second * delta, max_stamina)
	if current_stamina != before:
		_emit_stamina_changed()


func get_ratio() -> float:
	if max_stamina <= 0.0:
		return 0.0
	return current_stamina / max_stamina


func can_consume(amount: float) -> bool:
	return amount <= 0.0 or current_stamina >= amount


func consume(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if current_stamina < amount:
		return false

	current_stamina -= amount
	_regen_blocked = regen_delay_seconds
	_emit_stamina_changed()

	if current_stamina <= 0.0:
		emit_signal("stamina_depleted")

	return true


func set_stamina(value: float, maximum: float = -1.0) -> void:
	if maximum > 0.0:
		max_stamina = maximum
	current_stamina = clamp(value, 0.0, max_stamina)
	_emit_stamina_changed()


func restore_full() -> void:
	current_stamina = max_stamina
	_regen_blocked = 0.0
	_emit_stamina_changed()
	emit_signal("stamina_restored")


func _can_regen() -> bool:
	return _regen_blocked <= 0.0 and current_stamina < max_stamina


func _emit_stamina_changed() -> void:
	emit_signal("stamina_changed", current_stamina, max_stamina)
