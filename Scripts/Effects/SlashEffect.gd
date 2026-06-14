extends Node2D

# Brief attack arc flash (Polygon2D, auto-frees).

var _poly: Polygon2D
var _life: float = 0.14


func setup(origin: Vector2, direction: Vector2, color: Color = GamePalette.PLAYER_BLADE) -> void:
	global_position = origin
	rotation = direction.angle()

	_poly = Polygon2D.new()
	_poly.color = Color(color.r, color.g, color.b, 0.75)
	_poly.polygon = PoolVector2Array([
		Vector2(8, -3), Vector2(34, 0), Vector2(8, 3), Vector2(14, 0)
	])
	add_child(_poly)


func _process(delta: float) -> void:
	_life -= delta
	var alpha = max(_life / 0.14, 0.0)
	modulate = Color(1.0, 1.0, 1.0, alpha)
	scale = Vector2(1.0 + (1.0 - alpha) * 0.35, 1.0 + (1.0 - alpha) * 0.35)
	if _life <= 0.0:
		queue_free()
