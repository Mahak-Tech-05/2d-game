extends CanvasLayer

# Clean open-world HUD: health top-left, money top-right, mission bottom-left, vehicle status bottom-right.

var _health_fill: ColorRect
var _health_label: Label
var _money_label: Label
var _mission_label: Label
var _vehicle_label: Label
var _pause_overlay: ColorRect
var _bar_width := 190.0

func _ready() -> void:
	_clear_legacy_children()
	_build_hud()
	GameEvents.connect("player_health_changed", self, "_on_player_health_changed")
	GameEvents.connect("money_changed", self, "_on_money_changed")
	GameEvents.connect("mission_text_changed", self, "_on_mission_text_changed")
	GameEvents.connect("vehicle_status_changed", self, "_on_vehicle_status_changed")
	GameEvents.connect("game_paused", self, "_on_game_paused")
	GameEvents.connect("game_resumed", self, "_on_game_resumed")
	call_deferred("_bind_player")

func _clear_legacy_children() -> void:
	for child in get_children():
		child.queue_free()

func _build_hud() -> void:
	var health_panel = _panel(Rect2(18, 18, 238, 48))
	add_child(health_panel)
	_health_label = _label("HEALTH", Vector2(12, 6), 13, GamePalette.MISSION_TEXT)
	health_panel.add_child(_health_label)
	var bg = _rect(Rect2(12, 27, _bar_width, 12), Color(0.12, 0.16, 0.14, 0.72))
	health_panel.add_child(bg)
	_health_fill = _rect(Rect2(12, 27, _bar_width, 12), GamePalette.HP_FILL)
	health_panel.add_child(_health_fill)

	var money_panel = _panel(Rect2(1350, 18, 220, 48))
	money_panel.anchor_left = 1.0
	money_panel.anchor_right = 1.0
	money_panel.margin_left = -238
	money_panel.margin_right = -18
	add_child(money_panel)
	_money_label = _label("$250", Vector2(12, 9), 24, GamePalette.MONEY_GREEN)
	_money_label.align = Label.ALIGN_RIGHT
	_money_label.rect_size = Vector2(196, 30)
	money_panel.add_child(_money_label)

	var mission_panel = _panel(Rect2(18, 500, 455, 58))
	mission_panel.anchor_top = 1.0
	mission_panel.anchor_bottom = 1.0
	mission_panel.margin_top = -76
	mission_panel.margin_bottom = -18
	add_child(mission_panel)
	_mission_label = _label("Explore Sun City. Press E near cars, shops, and citizens.", Vector2(14, 10), 14, GamePalette.MISSION_TEXT)
	_mission_label.rect_size = Vector2(425, 40)
	_mission_label.autowrap = true
	mission_panel.add_child(_mission_label)

	var vehicle_panel = _panel(Rect2(1250, 510, 332, 48))
	vehicle_panel.anchor_left = 1.0
	vehicle_panel.anchor_right = 1.0
	vehicle_panel.anchor_top = 1.0
	vehicle_panel.anchor_bottom = 1.0
	vehicle_panel.margin_left = -350
	vehicle_panel.margin_right = -18
	vehicle_panel.margin_top = -66
	vehicle_panel.margin_bottom = -18
	add_child(vehicle_panel)
	_vehicle_label = _label("On Foot", Vector2(12, 10), 16, GamePalette.MISSION_TEXT)
	_vehicle_label.align = Label.ALIGN_RIGHT
	_vehicle_label.rect_size = Vector2(304, 24)
	vehicle_panel.add_child(_vehicle_label)

	_pause_overlay = ColorRect.new()
	_pause_overlay.anchor_right = 1.0
	_pause_overlay.anchor_bottom = 1.0
	_pause_overlay.color = Color(0.78, 0.88, 1.0, 0.28)
	_pause_overlay.visible = false
	add_child(_pause_overlay)
	var pause_label = _label("PAUSED", Vector2(-120, -36), 30, Color(0.05, 0.11, 0.16))
	pause_label.anchor_left = 0.5
	pause_label.anchor_top = 0.5
	pause_label.anchor_right = 0.5
	pause_label.anchor_bottom = 0.5
	pause_label.align = Label.ALIGN_CENTER
	_pause_overlay.add_child(pause_label)

func _bind_player() -> void:
	var players = get_tree().get_nodes_in_group(GameConstants.GROUP_PLAYER)
	if players.empty():
		return
	var player = players[0]
	if player.has_node("HealthComponent"):
		var hp = player.get_node("HealthComponent")
		_on_player_health_changed(hp.current_health, hp.max_health)
	if player.get("money") != null:
		_on_money_changed(int(player.get("money")))

func _on_player_health_changed(current: float, maximum: float) -> void:
	var ratio = 0.0 if maximum <= 0.0 else clamp(current / maximum, 0.0, 1.0)
	_health_fill.rect_size.x = _bar_width * ratio
	_health_label.text = "HEALTH  %d/%d" % [int(ceil(current)), int(maximum)]

func _on_money_changed(total: int) -> void:
	_money_label.text = "$%06d" % total

func _on_mission_text_changed(text: String) -> void:
	_mission_label.text = text

func _on_vehicle_status_changed(text: String) -> void:
	_vehicle_label.text = text

func _on_game_paused() -> void:
	_pause_overlay.visible = true

func _on_game_resumed() -> void:
	_pause_overlay.visible = false

func _panel(rect: Rect2) -> ColorRect:
	var panel = ColorRect.new()
	panel.rect_position = rect.position
	panel.rect_size = rect.size
	panel.color = GamePalette.HUD_PANEL
	return panel

func _rect(rect: Rect2, color: Color) -> ColorRect:
	var node = ColorRect.new()
	node.rect_position = rect.position
	node.rect_size = rect.size
	node.color = color
	return node

func _label(text: String, pos: Vector2, _size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.rect_position = pos
	label.add_color_override("font_color", color)
	return label
