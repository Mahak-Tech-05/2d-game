extends BossBase

# First boss: Crimson Warden — two escalating combat phases.


func _ready() -> void:
	enemy_id = "boss_crimson_warden"
	boss_name = "Crimson Warden"
	enemy_display_name = boss_name
	max_health = 320.0
	move_speed = 70.0
	chase_speed = 105.0
	attack_damage = 22.0
	detection_range = 280.0
	attack_range = 42.0
	soul_reward = 75
	phase_names = PoolStringArray(["Blood Oath", "Last Stand"])
	phase_thresholds = PoolRealArray([0.6, 0.3])
	._ready()


func _on_phase_entered(phase_index: int, phase_name: String) -> void:
	match phase_index:
		0:
			chase_speed = 130.0
			attack_damage = 26.0
			combat.attack_duration = 0.24
		1:
			chase_speed = 155.0
			attack_damage = 32.0
			combat.attack_duration = 0.2
			detection_range = 320.0

	ai.setup(self, combat, detection_range, attack_range, move_speed, chase_speed)
	combat.setup(self, attack_hitbox, attack_damage)

	if _name_label != null:
		_name_label.text = "%s — %s" % [boss_name, phase_name]
