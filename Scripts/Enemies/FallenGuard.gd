extends EnemyBase

# Slow, durable frontline enemy.


func _ready() -> void:
	enemy_id = "fallen_guard"
	enemy_display_name = "Fallen Guard"
	max_health = 110.0
	move_speed = 65.0
	chase_speed = 90.0
	attack_damage = 18.0
	detection_range = 150.0
	attack_range = 38.0
	soul_reward = 8
	._ready()
