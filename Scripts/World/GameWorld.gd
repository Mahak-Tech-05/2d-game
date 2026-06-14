extends Node2D

# Open-world city scene: player, HUD, drivable cars, stores, NPC contacts, and interaction placeholders.

const _PLAYER_SCENE = preload("res://Scenes/Player/Player.tscn")
const _HUD_SCENE = preload("res://Scenes/UI/GameHUD.tscn")
const _INTERACTABLE_SCRIPT = preload("res://Scripts/World/CityInteractable.gd")
const _VEHICLE_SCRIPT = preload("res://Scripts/World/Vehicle.gd")
const _CITIZEN_SCRIPT = preload("res://Scripts/World/Citizen.gd")
const _TRAFFIC_SCRIPT = preload("res://Scripts/World/TrafficCar.gd")

const MAX_ACTIVE_CITIZENS := 15

func _ready() -> void:
	_spawn_player()
	_spawn_hud()
	_spawn_city_interactions()
	_spawn_citizens()
	_spawn_traffic()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.return_to_main_menu()
		get_tree().set_input_as_handled()

func _spawn_player() -> void:
	var player = _PLAYER_SCENE.instance()
	var spawn_position = Vector2(790, 555)
	if SaveManager.current_save_data.has("player_position"):
		var saved_pos = SaveManager.current_save_data["player_position"]
		spawn_position = Vector2(float(saved_pos.get("x", spawn_position.x)), float(saved_pos.get("y", spawn_position.y)))
	player.global_position = spawn_position
	$Entities.add_child(player)

func _spawn_hud() -> void:
	var hud = _HUD_SCENE.instance()
	add_child(hud)

func _spawn_city_interactions() -> void:
	_add_vehicle(Vector2(155, 650), "Blista Compact", GamePalette.VEHICLE_RED, 0.0)
	_add_vehicle(Vector2(1020, 650), "Prairie Cruiser", GamePalette.VEHICLE_BLUE, PI)
	_add_shop(Vector2(180, 260), "Vespucci 24/7")
	_add_shop(Vector2(618, 550), "Downtown Mods")
	_add_npc(Vector2(925, 352), "Lamar", "Mission contact: delivery route placeholder unlocked.", 50)
	_add_npc(Vector2(1288, 610), "Maya", "Street race placeholder added to your phone.", 35)

func _spawn_citizens() -> void:
	var sidewalk_points = _get_sidewalk_points()
	var names = ["Alex", "Mina", "Jay", "Rosa", "Omar", "Lena", "Vic", "Nia", "Sam", "Ivy", "Leo", "Tara"]
	var count = min(MAX_ACTIVE_CITIZENS, names.size())
	for i in range(count):
		var citizen = KinematicBody2D.new()
		citizen.name = "Citizen%s" % names[i]
		citizen.set_script(_CITIZEN_SCRIPT)
		$Entities.add_child(citizen)
		citizen.setup(names[i], sidewalk_points, 1000 + i * 17)
		_add_citizen_visual(citizen, i)

func _spawn_traffic() -> void:
	var routes = _get_traffic_routes()
	var colors = [Color(0.95, 0.68, 0.08), Color(0.1, 0.42, 0.95), Color(0.9, 0.12, 0.12), Color(0.08, 0.62, 0.24), Color(0.85, 0.85, 0.82), Color(0.55, 0.22, 0.8)]
	for i in range(routes.size()):
		var traffic = KinematicBody2D.new()
		traffic.name = "TrafficCar%d" % i
		traffic.set_script(_TRAFFIC_SCRIPT)
		$Entities.add_child(traffic)
		traffic.setup(routes[i], colors[i % colors.size()])

func _get_sidewalk_points() -> Array:
	return [
		Vector2(278, 210), Vector2(442, 210), Vector2(738, 220), Vector2(902, 220), Vector2(1158, 220), Vector2(1322, 220),
		Vector2(278, 390), Vector2(442, 390), Vector2(738, 390), Vector2(902, 390), Vector2(1158, 390), Vector2(1322, 390),
		Vector2(278, 572), Vector2(442, 572), Vector2(738, 572), Vector2(902, 572), Vector2(1158, 572), Vector2(1322, 572),
		Vector2(278, 742), Vector2(442, 742), Vector2(738, 742), Vector2(902, 742), Vector2(1158, 742), Vector2(1322, 742)
	]

func _get_traffic_routes() -> Array:
	return [
		[Vector2(80, 274), Vector2(1520, 274)],
		[Vector2(1520, 326), Vector2(80, 326)],
		[Vector2(80, 624), Vector2(1520, 624)],
		[Vector2(1520, 676), Vector2(80, 676)],
		[Vector2(334, 930), Vector2(334, 80)],
		[Vector2(386, 80), Vector2(386, 930)]
	]

func _add_citizen_visual(citizen: Node2D, index: int) -> void:
	var colors = [Color(0.95, 0.72, 0.22), Color(0.22, 0.56, 0.95), Color(0.85, 0.28, 0.42), Color(0.18, 0.70, 0.38)]
	var shape = CollisionShape2D.new()
	var capsule = CapsuleShape2D.new()
	capsule.radius = 7
	capsule.height = 18
	shape.shape = capsule
	citizen.add_child(shape)
	var body = Polygon2D.new()
	body.color = colors[index % colors.size()]
	body.polygon = PoolVector2Array([Vector2(-7, -15), Vector2(7, -15), Vector2(8, 10), Vector2(-8, 10)])
	citizen.add_child(body)
	var head = Polygon2D.new()
	head.color = GamePalette.PLAYER_SKIN
	head.polygon = PoolVector2Array([Vector2(-6, -26), Vector2(6, -26), Vector2(7, -15), Vector2(-7, -15)])
	citizen.add_child(head)

func _add_vehicle(pos: Vector2, title: String, color: Color, angle: float) -> void:
	var car = KinematicBody2D.new()
	car.name = title.replace(" ", "")
	car.set_script(_VEHICLE_SCRIPT)
	car.vehicle_name = title
	car.global_position = pos
	car.rotation = angle
	$Entities.add_child(car)

	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.extents = Vector2(34, 18)
	shape.shape = box
	car.add_child(shape)

	var body = Polygon2D.new()
	body.color = color
	body.polygon = PoolVector2Array([Vector2(-34, -16), Vector2(28, -16), Vector2(38, 0), Vector2(28, 18), Vector2(-30, 18), Vector2(-40, 0)])
	car.add_child(body)
	_add_child_rect(car, Rect2(-16, -12, 30, 11), GamePalette.VEHICLE_GLASS)
	_add_child_rect(car, Rect2(-25, 15, 12, 5), Color(0.05, 0.05, 0.05))
	_add_child_rect(car, Rect2(12, 15, 12, 5), Color(0.05, 0.05, 0.05))

func _add_shop(pos: Vector2, title: String) -> void:
	var root = _make_interactable(pos, "shop", title, "Press E to shop")
	_add_child_rect(root, Rect2(-34, -18, 68, 36), GamePalette.SHOP_AWNING)
	var label = Label.new()
	label.text = "SHOP"
	label.rect_position = Vector2(-22, -9)
	label.add_color_override("font_color", Color.white)
	root.add_child(label)

func _add_npc(pos: Vector2, title: String, message: String, payout: int) -> void:
	var root = _make_interactable(pos, "npc", title, "Press E to talk")
	root.payout = payout
	root.set_meta("message", message)
	var body = Polygon2D.new()
	body.color = Color(0.95, 0.72, 0.22)
	body.polygon = PoolVector2Array([Vector2(-8, -18), Vector2(8, -18), Vector2(10, 12), Vector2(-10, 12)])
	root.add_child(body)
	var head = Polygon2D.new()
	head.color = GamePalette.PLAYER_SKIN
	head.polygon = PoolVector2Array([Vector2(-7, -30), Vector2(7, -30), Vector2(8, -18), Vector2(-8, -18)])
	root.add_child(head)

func _make_interactable(pos: Vector2, kind: String, title: String, prompt: String) -> Area2D:
	var root = Area2D.new()
	root.set_script(_INTERACTABLE_SCRIPT)
	root.global_position = pos
	root.interaction_type = kind
	root.display_name = title
	root.prompt = prompt
	$Entities.add_child(root)
	return root

func _add_child_rect(parent: Node, rect: Rect2, color: Color) -> void:
	var node = ColorRect.new()
	node.rect_position = rect.position
	node.rect_size = rect.size
	node.color = color
	parent.add_child(node)
