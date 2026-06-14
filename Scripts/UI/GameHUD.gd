extends CanvasLayer

# In-game HUD with styled panel, boss bar, and pause overlay.

var _player: Node = null
var _health_fill: ColorRect
var _stamina_fill: ColorRect
var _boss_fill: ColorRect
var _health_label: Label
var _stamina_label: Label
var _souls_label: Label
var _boss_label: Label
var _boss_row: Control
var _pause_overlay: ColorRect
var _bar_width: float = 150.0
var _boss_bar_width: float = 380.0


func _ready() -> void:
	_health_fill = $Margin/VBox/HealthRow/Bar/Fill
	_stamina_fill = $Margin/VBox/StaminaRow/Bar/Fill
	_health_label = $Margin/VBox/HealthRow/Label
	_stamina_label = $Margin/VBox/StaminaRow/Label
	_souls_label = $Margin/SoulsLabel
	_boss_row = $Margin/BossRow
	_boss_fill = $Margin/BossRow/Bar/Fill
	_boss_label = $Margin/BossRow/Label
	_pause_overlay = $PauseOverlay
	_boss_row.visible = false
	_pause_overlay.visible = false

	GameEvents.connect("player_health_changed", self, "_on_player_health_changed")
	GameEvents.connect("player_stamina_changed", self, "_on_player_stamina_changed")
	GameEvents.connect("souls_changed", self, "_on_souls_changed")
	GameEvents.connect("boss_spawned", self, "_on_boss_spawned")
	GameEvents.connect("boss_health_changed", self, "_on_boss_health_changed")
	GameEvents.connect("boss_phase_changed", self, "_on_boss_phase_changed")
	GameEvents.connect("boss_defeated", self, "_on_boss_defeated")
	GameEvents.connect("game_paused", self, "_on_game_paused")
	GameEvents.connect("game_resumed", self, "_on_game_resumed")

	call_deferred("_bind_player")


func _bind_player() -> void:
	var players = get_tree().get_nodes_in_group(GameConstants.GROUP_PLAYER)
	if players.empty():
		return

	_player = players[0]
	if _player.has_node("HealthComponent"):
		var hp = _player.get_node("HealthComponent")
		_on_player_health_changed(hp.current_health, hp.max_health)
	if _player.has_node("StaminaComponent"):
		var sp = _player.get_node("StaminaComponent")
		_on_player_stamina_changed(sp.current_stamina, sp.max_stamina)

	var souls = 0
	if SaveManager.current_save_data.has("player_stats"):
		souls = int(SaveManager.current_save_data["player_stats"].get("souls", 0))
	_on_souls_changed(souls)


func _on_player_health_changed(current: float, maximum: float) -> void:
	_set_bar(_health_fill, _bar_width, current, maximum)
	_health_label.text = "Vitality %d/%d" % [int(ceil(current)), int(maximum)]


func _on_player_stamina_changed(current: float, maximum: float) -> void:
	_set_bar(_stamina_fill, _bar_width, current, maximum)
	_stamina_label.text = "Spirit %d/%d" % [int(ceil(current)), int(maximum)]


func _on_souls_changed(total: int) -> void:
	_souls_label.text = "Souls: %d" % total


func _on_boss_spawned(boss) -> void:
	_boss_row.visible = true
	if boss != null and "boss_name" in boss:
		_boss_label.text = str(boss.boss_name)


func _on_boss_health_changed(_boss, current: float, maximum: float, boss_name: String) -> void:
	_boss_row.visible = true
	_boss_label.text = boss_name
	_set_bar(_boss_fill, _boss_bar_width, current, maximum)


func _on_boss_phase_changed(_boss, _phase_index: int, phase_name: String) -> void:
	var base_name = _boss_label.text.split(" — ")[0]
	_boss_label.text = "%s — %s" % [base_name, phase_name]


func _on_boss_defeated(_boss) -> void:
	yield(get_tree().create_timer(2.0), "timeout")
	_boss_row.visible = false


func _on_game_paused() -> void:
	_pause_overlay.visible = true


func _on_game_resumed() -> void:
	_pause_overlay.visible = false


func _set_bar(fill: ColorRect, width: float, current: float, maximum: float) -> void:
	var ratio = 0.0 if maximum <= 0.0 else clamp(current / maximum, 0.0, 1.0)
	fill.rect_size.x = width * ratio
