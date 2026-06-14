extends KinematicBody2D
class_name EnemyBase

# Base enemy: health, AI movement, combat, and death handling.

signal defeated(enemy)

export var enemy_id: String = "enemy"
export var enemy_display_name: String = "Shade"
export var max_health: float = 60.0
export var move_speed: float = 85.0
export var chase_speed: float = 120.0
export var attack_damage: float = 12.0
export var detection_range: float = 170.0
export var attack_range: float = 34.0
export var soul_reward: int = 5
export var starts_active: bool = true

var facing: Vector2 = Vector2.DOWN
var _knockback: Vector2 = Vector2.ZERO
var _is_dead: bool = false
var _spawn_position: Vector2 = Vector2.ZERO
var _body: CanvasItem
var _visual: Node2D

onready var health: HealthComponent = $HealthComponent
onready var ai: EnemyAI = $EnemyAI
onready var combat: EnemyCombat = $Combat
onready var attack_hitbox: HitboxArea = $Combat/AttackHitbox


func _ready() -> void:
	add_to_group(GameConstants.GROUP_ENEMIES)
	_spawn_position = global_position
	_visual = $Visual
	_body = $Visual/Body

	collision_layer = GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD

	health.set_max_health(max_health, true)
	health.connect("health_changed", self, "_on_health_changed")
	health.connect("died", self, "_on_died")

	combat.setup(self, attack_hitbox, attack_damage)
	ai.setup(self, combat, detection_range, attack_range, move_speed, chase_speed)
	ai.set_active(starts_active)

	attack_hitbox.collision_layer = GameConstants.LAYER_ENEMY_HITBOX
	attack_hitbox.collision_mask = GameConstants.LAYER_PLAYER


func _physics_process(delta: float) -> void:
	if _is_dead or GameManager.current_state != GameState.State.PLAYING:
		return

	_knockback = GameConstants.vector_move_toward_zero(_knockback, 360.0 * delta)

	var velocity = ai.process_ai(delta)
	if ai.facing.length_squared() > 0.01:
		facing = ai.facing

	if combat.is_attacking:
		velocity = Vector2.ZERO

	velocity += _knockback
	velocity = move_and_slide(velocity)
	_update_visual()


func set_active(value: bool) -> void:
	ai.set_active(value)
	set_physics_process(value)
	visible = value


func receive_damage(amount: float, source = null) -> float:
	if _is_dead:
		return 0.0

	var applied = health.take_damage(amount, source)
	if applied > 0.0:
		ai.on_damaged()
	return applied


func apply_knockback(force: Vector2) -> void:
	_knockback += force


func _on_health_changed(current: float, maximum: float) -> void:
	if _body == null:
		return
	var ratio = 0.0 if maximum <= 0.0 else current / maximum
	_body.modulate = Color(0.45 + ratio * 0.35, 0.18, 0.2, 1.0)


func _on_died() -> void:
	if _is_dead:
		return

	_is_dead = true
	ai.mark_dead()
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0

	_award_souls()
	emit_signal("defeated", self)
	GameEvents.raise_enemy_defeated(self, soul_reward)

	_play_death_and_remove()


func _award_souls() -> void:
	if SaveManager.current_save_data.empty():
		return

	var stats = SaveManager.current_save_data.get("player_stats", {})
	var souls = int(stats.get("souls", 0)) + soul_reward
	stats["souls"] = souls
	SaveManager.current_save_data["player_stats"] = stats
	GameEvents.raise_souls_changed(souls)


func _play_death_and_remove() -> void:
	if _body != null:
		var tween = Tween.new()
		add_child(tween)
		tween.interpolate_property(_body, "modulate:a", 1.0, 0.0, 0.35, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_all_completed")
	queue_free()


func _update_visual() -> void:
	if _visual == null:
		return
	if combat.is_attacking:
		_visual.scale = Vector2(1.12, 1.12)
	else:
		_visual.scale = Vector2.ONE
