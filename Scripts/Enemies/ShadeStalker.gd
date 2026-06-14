extends EnemyBase

# Fast, fragile ambusher.


func _ready() -> void:
	enemy_id = "shade_stalker"
	enemy_display_name = "Shade Stalker"
	max_health = 45.0
	move_speed = 95.0
	chase_speed = 155.0
	attack_damage = 10.0
	detection_range = 200.0
	attack_range = 32.0
	soul_reward = 4
	._ready()
