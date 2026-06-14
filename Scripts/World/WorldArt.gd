extends Node2D

# Bright procedural city dressing using simple 2D primitives only.
# The city is intentionally authored from ColorRect/Polygon2D nodes to avoid texture memory pressure.

const MAP_W := 1600
const MAP_H := 1000
const ROAD_W := 132
const SIDEWALK_W := 22

var _building_shapes := []

func _ready() -> void:
	_build_sky_and_grass()
	_build_roads()
	_build_city_blocks()
	_build_parking_lots()
	_build_park_area()
	_build_bus_stops()
	_build_traffic_signals()
	_build_trees()
	_build_lamp_posts()
	_create_building_collision()

func _build_sky_and_grass() -> void:
	_add_rect(Rect2(0, 0, MAP_W, MAP_H), GamePalette.GRASS_A)
	_add_rect(Rect2(0, 0, MAP_W, 180), GamePalette.SKY_BOTTOM)
	_add_rect(Rect2(0, 0, MAP_W, 95), GamePalette.SKY_MID)
	_add_rect(Rect2(0, 0, MAP_W, 42), GamePalette.SKY_TOP)
	_add_rect(Rect2(0, 0, MAP_W, MAP_H), GamePalette.SUNLIGHT)
	for x in range(0, MAP_W, 80):
		for y in range(200, MAP_H, 80):
			if int((x + y) / 80) % 2 == 0:
				_add_rect(Rect2(x, y, 80, 80), GamePalette.GRASS_B)

func _build_roads() -> void:
	var vertical_roads = [360, 820, 1240]
	var horizontal_roads = [300, 650]
	for x in vertical_roads:
		_add_road(Rect2(x - ROAD_W / 2, 0, ROAD_W, MAP_H), true)
	for y in horizontal_roads:
		_add_road(Rect2(0, y - ROAD_W / 2, MAP_W, ROAD_W), false)
	for x in vertical_roads:
		for y in horizontal_roads:
			_add_crosswalk(Vector2(x, y))

func _add_road(rect: Rect2, vertical: bool) -> void:
	_add_rect(Rect2(rect.position.x - SIDEWALK_W, rect.position.y, SIDEWALK_W, rect.size.y), GamePalette.SIDEWALK)
	_add_rect(Rect2(rect.position.x + rect.size.x, rect.position.y, SIDEWALK_W, rect.size.y), GamePalette.SIDEWALK)
	if not vertical:
		_add_rect(Rect2(rect.position.x, rect.position.y - SIDEWALK_W, rect.size.x, SIDEWALK_W), GamePalette.SIDEWALK)
		_add_rect(Rect2(rect.position.x, rect.position.y + rect.size.y, rect.size.x, SIDEWALK_W), GamePalette.SIDEWALK)
	_add_rect(rect, GamePalette.ROAD)
	if vertical:
		for y in range(0, MAP_H, 72):
			_add_rect(Rect2(rect.position.x + ROAD_W / 2 - 3, y + 16, 6, 34), GamePalette.LANE_MARKING)
	else:
		for x in range(0, MAP_W, 72):
			_add_rect(Rect2(x + 16, rect.position.y + ROAD_W / 2 - 3, 34, 6), GamePalette.LANE_MARKING)

func _add_crosswalk(center: Vector2) -> void:
	for i in range(-3, 4):
		_add_rect(Rect2(center.x - 58, center.y + i * 15 - 4, 116, 8), GamePalette.CROSSWALK)
		_add_rect(Rect2(center.x + i * 15 - 4, center.y - 58, 8, 116), GamePalette.CROSSWALK)

func _build_city_blocks() -> void:
	var blocks = [
		Rect2(70, 210, 190, 92), Rect2(475, 110, 220, 120), Rect2(930, 120, 210, 122), Rect2(1325, 170, 185, 110),
		Rect2(92, 430, 210, 135), Rect2(520, 430, 190, 145), Rect2(960, 455, 210, 120), Rect2(1320, 420, 190, 150),
		Rect2(110, 760, 230, 130), Rect2(510, 760, 210, 135), Rect2(930, 760, 225, 130), Rect2(1320, 760, 190, 120)
	]
	var colors = [GamePalette.BUILDING_BLUE, GamePalette.BUILDING_TAN, GamePalette.BUILDING_RED, GamePalette.BUILDING_WHITE]
	for i in range(blocks.size()):
		_add_building(blocks[i], colors[i % colors.size()], i)

func _add_building(rect: Rect2, color: Color, index: int) -> void:
	_building_shapes.append(rect)
	_add_rect(rect, color)
	_add_rect(Rect2(rect.position.x, rect.position.y + rect.size.y - 18, rect.size.x, 18), color.darkened(0.18))
	if index % 3 == 0:
		_add_rect(Rect2(rect.position.x + 14, rect.position.y + rect.size.y - 30, rect.size.x - 28, 18), GamePalette.SHOP_AWNING)
		_add_label("24/7 STORE", rect.position + Vector2(22, rect.size.y - 56), 12, Color.white)
	for wx in range(int(rect.position.x + 16), int(rect.position.x + rect.size.x - 20), 38):
		for wy in range(int(rect.position.y + 14), int(rect.position.y + rect.size.y - 36), 32):
			_add_rect(Rect2(wx, wy, 18, 16), GamePalette.WINDOW)

func _build_parking_lots() -> void:
	var lots = [Rect2(70, 610, 230, 95), Rect2(940, 610, 240, 95)]
	for lot in lots:
		_add_rect(lot, Color(0.42, 0.44, 0.45))
		for x in range(int(lot.position.x + 18), int(lot.position.x + lot.size.x - 18), 42):
			_add_rect(Rect2(x, lot.position.y + 8, 3, lot.size.y - 16), Color(0.88, 0.88, 0.82))
		_add_label("P", lot.position + Vector2(12, 8), 20, Color.white)

func _build_park_area() -> void:
	var park = Rect2(1215, 805, 250, 145)
	_add_rect(park, Color(0.16, 0.64, 0.24))
	_add_rect(Rect2(park.position.x + 18, park.position.y + 62, park.size.x - 36, 16), Color(0.78, 0.68, 0.48))
	_add_label("CITY PARK", park.position + Vector2(78, 14), 18, Color.white)
	for x in [1248, 1328, 1410]:
		_add_rect(Rect2(x - 14, park.position.y + 104, 28, 8), Color(0.42, 0.24, 0.12))
		_add_rect(Rect2(x - 3, park.position.y + 88, 6, 24), Color(0.18, 0.18, 0.16))

func _build_bus_stops() -> void:
	for pos in [Vector2(485, 236), Vector2(1110, 686)]:
		_add_rect(Rect2(pos.x - 34, pos.y - 8, 68, 16), Color(0.10, 0.32, 0.72))
		_add_rect(Rect2(pos.x - 30, pos.y - 34, 60, 26), Color(0.58, 0.84, 1.0, 0.72))
		_add_rect(Rect2(pos.x - 38, pos.y - 38, 76, 6), Color(0.08, 0.16, 0.24))
		_add_label("BUS", pos + Vector2(-18, -31), 10, Color.white)

func _build_traffic_signals() -> void:
	for pos in [Vector2(292, 222), Vector2(428, 378), Vector2(752, 572), Vector2(888, 728), Vector2(1172, 222), Vector2(1308, 572)]:
		_add_rect(Rect2(pos.x - 3, pos.y - 28, 6, 34), GamePalette.LAMP_POST)
		_add_rect(Rect2(pos.x - 8, pos.y - 46, 16, 24), Color(0.06, 0.07, 0.08))
		_add_circle(pos + Vector2(0, -39), 3.2, Color(0.95, 0.08, 0.06))
		_add_circle(pos + Vector2(0, -32), 3.2, Color(0.95, 0.78, 0.08))
		_add_circle(pos + Vector2(0, -25), 3.2, Color(0.04, 0.82, 0.18))

func _build_trees() -> void:
	var positions = [Vector2(35, 370), Vector2(275, 375), Vector2(465, 300), Vector2(715, 305), Vector2(900, 330), Vector2(1185, 335), Vector2(1295, 310), Vector2(1530, 330), Vector2(410, 725), Vector2(790, 735), Vector2(1220, 725), Vector2(1540, 720)]
	for pos in positions:
		_add_rect(Rect2(pos.x - 4, pos.y, 8, 28), GamePalette.TREE_TRUNK)
		_add_circle(pos + Vector2(0, -10), 22, GamePalette.TREE_LEAF)

func _build_lamp_posts() -> void:
	for pos in [Vector2(310, 220), Vector2(410, 220), Vector2(770, 575), Vector2(870, 575), Vector2(1190, 220), Vector2(1290, 575), Vector2(320, 760), Vector2(1240, 760)]:
		_add_rect(Rect2(pos.x - 3, pos.y - 24, 6, 48), GamePalette.LAMP_POST)
		_add_circle(pos + Vector2(0, -30), 10, GamePalette.LAMP_GLOW)

func _create_building_collision() -> void:
	var walls = get_parent().get_node_or_null("Walls")
	if walls == null:
		return
	for i in range(_building_shapes.size()):
		var rect: Rect2 = _building_shapes[i]
		var body = StaticBody2D.new()
		body.name = "BuildingCollision%d" % i
		body.collision_layer = GameConstants.LAYER_WORLD
		body.collision_mask = 0
		body.position = rect.position + rect.size * 0.5
		var shape = CollisionShape2D.new()
		var box = RectangleShape2D.new()
		box.extents = rect.size * 0.5
		shape.shape = box
		body.add_child(shape)
		walls.add_child(body)

func _add_rect(rect: Rect2, color: Color) -> ColorRect:
	var node = ColorRect.new()
	node.rect_position = rect.position
	node.rect_size = rect.size
	node.color = color
	add_child(node)
	return node

func _add_circle(pos: Vector2, radius: float, color: Color) -> void:
	var poly = Polygon2D.new()
	poly.color = color
	var points = PoolVector2Array()
	for i in range(12):
		var a = PI * 2.0 * float(i) / 12.0
		points.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = points
	poly.position = pos
	add_child(poly)

func _add_label(text: String, pos: Vector2, size: int, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.rect_position = pos
	label.add_color_override("font_color", color)
	label.add_constant_override("line_spacing", 0)
	label.rect_size = Vector2(120, 22)
	add_child(label)
