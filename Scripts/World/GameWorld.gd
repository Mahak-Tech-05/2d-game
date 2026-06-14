extends Node2D

# Open-world city scene: player, HUD, drivable cars, stores, NPC contacts, and interaction placeholders.
# Open-world city scene: player, HUD, traffic props, stores, NPC contacts, and interaction placeholders.

const _PLAYER_SCENE = preload("res://Scenes/Player/Player.tscn")
const _HUD_SCENE = preload("res://Scenes/UI/GameHUD.tscn")
const _INTERACTABLE_SCRIPT = preload("res://Scripts/World/CityInteractable.gd")
const _VEHICLE_SCRIPT = preload("res://Scripts/World/Vehicle.gd")

func _ready() -> void:
	_spawn_player()
	_spawn_hud()
	_spawn_city_interactions()

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
	_add_vehicle(Vector2(155, 650), "Blista Compact", GamePalette.VEHICLE_RED)
	_add_vehicle(Vector2(1020, 650), "Prairie Cruiser", GamePalette.VEHICLE_BLUE)
	_add_shop(Vector2(180, 260), "Vespucci 24/7")
	_add_shop(Vector2(618, 550), "Downtown Mods")
	_add_npc(Vector2(925, 352), "Lamar", "Mission contact: delivery route placeholder unlocked.", 50)
	_add_npc(Vector2(1288, 610), "Maya", "Street race placeholder added to your phone.", 35)

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
func _add_vehicle(pos: Vector2, title: String, color: Color) -> void:
	var root = _make_interactable(pos, "vehicle", title, "Press E to enter")
	var car = Polygon2D.new()
	car.color = color
	car.polygon = PoolVector2Array([Vector2(-30, -15), Vector2(30, -15), Vector2(36, 0), Vector2(28, 17), Vector2(-28, 17), Vector2(-36, 0)])
	root.add_child(car)
	_add_child_rect(root, Rect2(-16, -11, 32, 10), GamePalette.VEHICLE_GLASS)
	_add_child_rect(root, Rect2(-24, 14, 12, 5), Color(0.05, 0.05, 0.05))
	_add_child_rect(root, Rect2(12, 14, 12, 5), Color(0.05, 0.05, 0.05))

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
