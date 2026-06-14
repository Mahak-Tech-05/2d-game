extends Node2D

# Playable arena with enemies, boss arena, and training dummy.

const _PLAYER_SCENE = preload("res://Scenes/Player/Player.tscn")
const _HUD_SCENE = preload("res://Scenes/UI/GameHUD.tscn")
const _DUMMY_SCENE = preload("res://Scenes/World/TrainingDummy.tscn")
const _SHADE_SCENE = preload("res://Scenes/Enemies/ShadeStalker.tscn")
const _GUARD_SCENE = preload("res://Scenes/Enemies/FallenGuard.tscn")
const _BOSS_SCENE = preload("res://Scenes/Enemies/BossCrimsonWarden.tscn")


func _ready() -> void:
	_spawn_player()
	_spawn_hud()
	_spawn_training_dummy()
	_spawn_enemies()
	_spawn_boss()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.return_to_main_menu()
		get_tree().set_input_as_handled()


func _spawn_player() -> void:
	var player = _PLAYER_SCENE.instance()
	var spawn_position = Vector2(160, 300)

	if SaveManager.current_save_data.has("player_position"):
		var saved_pos = SaveManager.current_save_data["player_position"]
		spawn_position = Vector2(float(saved_pos.get("x", spawn_position.x)), float(saved_pos.get("y", spawn_position.y)))

	player.global_position = spawn_position
	$Entities.add_child(player)


func _spawn_hud() -> void:
	var hud = _HUD_SCENE.instance()
	add_child(hud)


func _spawn_training_dummy() -> void:
	var dummy = _DUMMY_SCENE.instance()
	dummy.global_position = Vector2(280, 300)
	$Entities.add_child(dummy)


func _spawn_enemies() -> void:
	var shade_positions = [Vector2(480, 240), Vector2(560, 380), Vector2(700, 300)]
	var guard_positions = [Vector2(400, 360), Vector2(650, 420)]

	for pos in shade_positions:
		var enemy = _SHADE_SCENE.instance()
		enemy.global_position = pos
		$Entities.add_child(enemy)

	for pos in guard_positions:
		var enemy = _GUARD_SCENE.instance()
		enemy.global_position = pos
		$Entities.add_child(enemy)


func _spawn_boss() -> void:
	var boss = _BOSS_SCENE.instance()
	boss.global_position = Vector2(900, 300)
	$BossArena/BossSpawn.add_child(boss)

	var trigger = $BossArena/BossTrigger
	if trigger != null:
		trigger.boss_path = trigger.get_path_to(boss)
		if trigger.has_method("set_boss"):
			trigger.set_boss(boss)
