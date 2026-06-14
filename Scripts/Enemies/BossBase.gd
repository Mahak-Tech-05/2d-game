extends EnemyBase
class_name BossBase

# Boss framework: phases, arena lock, HUD integration.

signal phase_changed(phase_index, phase_name)
signal boss_activated
signal boss_defeated

export var boss_name: String = "Unknown Lord"
export var phase_names: PoolStringArray = PoolStringArray(["Phase I", "Phase II"])
export var phase_thresholds: PoolRealArray = PoolRealArray([0.65, 0.35])

var current_phase: int = -1
var is_activated: bool = false
var _name_label: Label


func _ready() -> void:
	add_to_group(GameConstants.GROUP_BOSSES)
	starts_active = false
	soul_reward = 50
	._ready()
	set_active(false)

	_name_label = get_node_or_null("Visual/NameLabel")


func activate_boss() -> void:
	if is_activated or _is_dead:
		return

	is_activated = true
	set_active(true)
	GameEvents.raise_boss_spawned(self)
	emit_signal("boss_activated")


func _on_health_changed(current: float, maximum: float) -> void:
	._on_health_changed(current, maximum)
	if not is_activated or maximum <= 0.0:
		return

	var ratio = current / maximum
	_check_phase_transition(ratio)
	GameEvents.raise_boss_health_changed(self, current, maximum, boss_name)


func _check_phase_transition(health_ratio: float) -> void:
	for i in range(phase_thresholds.size()):
		if i <= current_phase:
			continue
		if health_ratio <= phase_thresholds[i]:
			_enter_phase(i)
			break


func _enter_phase(phase_index: int) -> void:
	current_phase = phase_index
	var phase_name = phase_names[phase_index] if phase_index < phase_names.size() else "Phase %d" % (phase_index + 1)
	_on_phase_entered(phase_index, phase_name)
	emit_signal("phase_changed", phase_index, phase_name)
	GameEvents.raise_boss_phase_changed(self, phase_index, phase_name)


func _on_phase_entered(_phase_index: int, _phase_name: String) -> void:
	# Override in subclasses for unique patterns.
	pass


func _on_died() -> void:
	if _is_dead:
		return

	GameEvents.raise_boss_defeated(self)
	emit_signal("boss_defeated")
	._on_died()
