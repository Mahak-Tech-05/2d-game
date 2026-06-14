extends Node2D

# Procedural world dressing using ColorRects & Polygon2D only (low RAM).

const MAP_W := 1024
const MAP_H := 576
const TILE := 48


func _ready() -> void:
	_build_sky()
	_build_ground()
	_build_path()
	_build_pillars()
	_build_torches()
	_build_mountains()


func _build_sky() -> void:
	_add_rect(Rect2(0, 0, MAP_W, MAP_H * 0.55), GamePalette.SKY_TOP)
	_add_rect(Rect2(0, MAP_H * 0.35, MAP_W, MAP_H * 0.35), GamePalette.SKY_MID)
	_add_rect(Rect2(0, MAP_H * 0.55, MAP_W, MAP_H * 0.45), GamePalette.SKY_BOTTOM)


func _build_ground() -> void:
	for x in range(0, MAP_W, TILE):
		for y in range(int(MAP_H * 0.55), MAP_H, TILE):
			var alt = (int(x / TILE) + int(y / TILE)) % 2 == 0
			var col = GamePalette.GROUND_A if alt else GamePalette.GROUND_B
			_add_rect(Rect2(x, y, TILE, TILE), col)


func _build_path() -> void:
	var points = [
		Vector2(120, 310), Vector2(280, 300), Vector2(420, 320),
		Vector2(580, 295), Vector2(740, 315), Vector2(900, 300)
	]
	for i in range(points.size() - 1):
		var a = points[i]
		var b = points[i + 1]
		var dir = (b - a).normalized()
		var normal = Vector2(-dir.y, dir.x)
		for step in range(0, int(a.distance_to(b)), 20):
			var p = a + dir * step
			_add_rect(Rect2(p.x - 18, p.y - 10, 36, 20), GamePalette.PATH)
			_add_rect(Rect2(p.x - 20 + normal.x * 14, p.y - 12 + normal.y * 14, 8, 8), GamePalette.PATH_EDGE)


func _build_pillars() -> void:
	var pillar_positions = [Vector2(250, 250), Vector2(500, 220), Vector2(680, 260), Vector2(850, 230)]
	for pos in pillar_positions:
		_add_rect(Rect2(pos.x - 10, pos.y - 40, 20, 80), Color(0.18, 0.12, 0.16))
		_add_rect(Rect2(pos.x - 16, pos.y - 48, 32, 12), Color(0.22, 0.15, 0.2))


func _build_torches() -> void:
	var positions = [Vector2(200, 270), Vector2(450, 250), Vector2(700, 280), Vector2(950, 260)]
	for pos in positions:
		var root = Node2D.new()
		root.position = pos
		add_child(root)

		var pole = ColorRect.new()
		pole.rect_position = Vector2(-2, -8)
		pole.rect_size = Vector2(4, 18)
		pole.color = Color(0.28, 0.18, 0.14)
		root.add_child(pole)

		var flame = ColorRect.new()
		flame.name = "Flame"
		flame.rect_position = Vector2(-6, -18)
		flame.rect_size = Vector2(12, 14)
		flame.color = GamePalette.TORCH
		root.add_child(flame)

		var glow = ColorRect.new()
		glow.rect_position = Vector2(-20, -28)
		glow.rect_size = Vector2(40, 40)
		glow.color = Color(0.9, 0.45, 0.15, 0.08)
		root.add_child(glow)
		root.move_child(glow, 0)

		var flicker = load("res://Scripts/World/TorchFlicker.gd").new()
		root.add_child(flicker)


func _build_mountains() -> void:
	var poly = Polygon2D.new()
	poly.color = Color(0.08, 0.04, 0.09, 0.85)
	poly.polygon = PoolVector2Array([
		Vector2(0, 260), Vector2(120, 180), Vector2(240, 230),
		Vector2(380, 150), Vector2(520, 210), Vector2(660, 140),
		Vector2(820, 200), Vector2(1024, 160), Vector2(1024, 320), Vector2(0, 320)
	])
	add_child(poly)


func _add_rect(rect: Rect2, color: Color) -> void:
	var node = ColorRect.new()
	node.rect_position = rect.position
	node.rect_size = rect.size
	node.color = color
	add_child(node)
