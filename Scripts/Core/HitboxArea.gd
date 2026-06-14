extends Area2D
class_name HitboxArea

# Damage-dealing hitbox. Enable briefly during attacks.

signal hit_landed(target, damage)

export var damage: float = 25.0
export var knockback_force: float = 140.0
export var active_time: float = 0.12

var owner_node: Node = null
var _hit_targets: Array = []


func _ready() -> void:
	monitoring = false
	connect("body_entered", self, "_on_body_entered")
	connect("area_entered", self, "_on_area_entered")


func configure(owner_ref: Node, hit_damage: float = -1.0) -> void:
	owner_node = owner_ref
	if hit_damage > 0.0:
		damage = hit_damage


func activate() -> void:
	_hit_targets.clear()
	monitoring = true
	yield(get_tree().create_timer(active_time), "timeout")
	monitoring = false


func _on_body_entered(body: Node) -> void:
	_try_damage(body)


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() != null:
		_try_damage(area.get_parent())


func _try_damage(target: Node) -> void:
	if target == null or target == owner_node:
		return
	if _hit_targets.has(target):
		return

	var damage_receiver = _resolve_damage_receiver(target)
	if damage_receiver == null:
		return

	var applied = 0.0
	if damage_receiver.has_method("receive_damage"):
		applied = damage_receiver.receive_damage(damage, owner_node)
	elif damage_receiver.has_method("take_damage"):
		applied = damage_receiver.take_damage(damage, owner_node)

	if applied > 0.0:
		_hit_targets.append(target)
		_apply_knockback(target)
		emit_signal("hit_landed", target, applied)


func _resolve_damage_receiver(target: Node) -> Node:
	if target.has_method("receive_damage") or target.has_method("take_damage"):
		return target

	var health_parent = target.get_parent()
	if health_parent != null and (
		health_parent.has_method("receive_damage") or health_parent.has_method("take_damage")
	):
		return health_parent

	return null


func _apply_knockback(target: Node) -> void:
	if knockback_force <= 0.0 or owner_node == null:
		return
	if not target.has_method("apply_knockback"):
		return

	var direction = target.global_position - owner_node.global_position
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	target.apply_knockback(direction.normalized() * knockback_force)
