extends Area2D

# Activates a boss when the player enters the arena.

export var boss_path: NodePath
export var one_shot: bool = true

var _triggered: bool = false
var _boss: BossBase


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameConstants.LAYER_PLAYER
	connect("body_entered", self, "_on_body_entered")

	if boss_path != NodePath(""):
		_boss = get_node_or_null(boss_path)


func set_boss(boss: Node) -> void:
	_boss = boss


func _resolve_boss() -> void:
	if _boss != null:
		return
	if boss_path != NodePath(""):
		_boss = get_node_or_null(boss_path)


func _on_body_entered(body: Node) -> void:
	if _triggered and one_shot:
		return
	if not body.is_in_group(GameConstants.GROUP_PLAYER):
		return

	_resolve_boss()
	if _boss == null:
		push_warning("[BossArenaTrigger] Boss reference missing.")
		return

	_triggered = true
	_boss.activate_boss()
	monitoring = false
