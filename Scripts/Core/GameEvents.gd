extends Node

# Global event bus autoload. Subscribe in _ready, unsubscribe in _exit_tree.

signal game_state_changed(previous, current)
signal scene_transition_started(scene_path)
signal scene_transition_finished(scene_path)
signal save_started(slot_index)
signal save_completed(slot_index, success)
signal load_started(slot_index)
signal load_completed(slot_index, success)
signal new_game_started
signal game_paused
signal game_resumed
signal player_health_changed(current, maximum)
signal player_stamina_changed(current, maximum)
signal player_damaged(amount, source)
signal player_died
signal enemy_defeated(enemy, soul_reward)
signal souls_changed(total_souls)
signal boss_spawned(boss)
signal boss_health_changed(boss, current, maximum, boss_name)
signal boss_phase_changed(boss, phase_index, phase_name)
signal boss_defeated(boss)


func raise_state_changed(previous: int, current: int) -> void:
	emit_signal("game_state_changed", previous, current)


func raise_scene_transition_started(scene_path: String) -> void:
	emit_signal("scene_transition_started", scene_path)


func raise_scene_transition_finished(scene_path: String) -> void:
	emit_signal("scene_transition_finished", scene_path)


func raise_save_started(slot_index: int) -> void:
	emit_signal("save_started", slot_index)


func raise_save_completed(slot_index: int, success: bool) -> void:
	emit_signal("save_completed", slot_index, success)


func raise_load_started(slot_index: int) -> void:
	emit_signal("load_started", slot_index)


func raise_load_completed(slot_index: int, success: bool) -> void:
	emit_signal("load_completed", slot_index, success)


func raise_new_game_started() -> void:
	emit_signal("new_game_started")


func raise_game_paused() -> void:
	emit_signal("game_paused")


func raise_game_resumed() -> void:
	emit_signal("game_resumed")


func raise_player_health_changed(current: float, maximum: float) -> void:
	emit_signal("player_health_changed", current, maximum)


func raise_player_stamina_changed(current: float, maximum: float) -> void:
	emit_signal("player_stamina_changed", current, maximum)


func raise_player_damaged(amount: float, source) -> void:
	emit_signal("player_damaged", amount, source)


func raise_player_died() -> void:
	emit_signal("player_died")


func raise_enemy_defeated(enemy, soul_reward: int) -> void:
	emit_signal("enemy_defeated", enemy, soul_reward)


func raise_souls_changed(total_souls: int) -> void:
	emit_signal("souls_changed", total_souls)


func raise_boss_spawned(boss) -> void:
	emit_signal("boss_spawned", boss)


func raise_boss_health_changed(boss, current: float, maximum: float, boss_name: String) -> void:
	emit_signal("boss_health_changed", boss, current, maximum, boss_name)


func raise_boss_phase_changed(boss, phase_index: int, phase_name: String) -> void:
	emit_signal("boss_phase_changed", boss, phase_index, phase_name)


func raise_boss_defeated(boss) -> void:
	emit_signal("boss_defeated", boss)
