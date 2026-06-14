extends Node

# Persists and restores game state to user://saves (lightweight JSON, no C# overhead).

export var enable_auto_save: bool = true

var is_initialized: bool = false
var current_save_data: Dictionary = {}

var _saveables: Dictionary = {}
var _auto_save_timer: Timer


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	GameEvents.connect("game_state_changed", self, "_on_game_state_changed")
	_ensure_save_directory_exists()
	_setup_auto_save_timer()


func initialize() -> void:
	if is_initialized:
		return
	is_initialized = true
	print("[SaveManager] Initialized")


func shutdown() -> void:
	if GameEvents.is_connected("game_state_changed", self, "_on_game_state_changed"):
		GameEvents.disconnect("game_state_changed", self, "_on_game_state_changed")
	if _auto_save_timer != null:
		_auto_save_timer.stop()
	is_initialized = false
	_saveables.clear()


func register_saveable(node: Node) -> void:
	if node == null or not node.has_method("capture_state"):
		push_error("[SaveManager] Invalid saveable node.")
		return

	var save_id = ""
	if "save_id" in node:
		save_id = str(node.save_id)
	if save_id.empty():
		save_id = node.name

	_saveables[save_id] = node


func unregister_saveable(node: Node) -> void:
	if node == null:
		return

	var save_id = ""
	if "save_id" in node:
		save_id = str(node.save_id)
	if save_id.empty():
		save_id = node.name

	if _saveables.has(save_id) and _saveables[save_id] == node:
		_saveables.erase(save_id)


func create_new_game_data(slot_index: int) -> void:
	current_save_data = _create_default_save(slot_index)


func has_save(slot_index: int) -> bool:
	return _file_exists(_build_save_path(slot_index))


func peek_save_metadata(slot_index: int) -> Dictionary:
	var path = _build_save_path(slot_index)
	if not _file_exists(path):
		return {}

	var file = File.new()
	if file.open(path, File.READ) != OK:
		return {}

	var parsed = _parse_json(file.get_as_text())
	file.close()
	if parsed.empty():
		return {}
	return parsed


func save_game(slot_index: int) -> bool:
	GameEvents.raise_save_started(slot_index)

	if current_save_data.empty():
		create_new_game_data(slot_index)

	current_save_data["slot_index"] = slot_index
	current_save_data["timestamp_utc"] = _utc_timestamp()
	current_save_data["version"] = GameConstants.SAVE_DATA_VERSION
	current_save_data["playtime_seconds"] = GameManager.session_playtime_seconds
	current_save_data["current_scene"] = SceneManager.current_scene_path

	_capture_registered_saveables()
	_sync_live_player_snapshot()

	var path = _build_save_path(slot_index)
	_ensure_save_directory_exists()

	var file = File.new()
	if file.open(path, File.WRITE) != OK:
		push_error("[SaveManager] Cannot write save: %s" % path)
		GameEvents.raise_save_completed(slot_index, false)
		return false

	file.store_string(JSON.print(current_save_data, "\t"))
	file.close()

	GameEvents.raise_save_completed(slot_index, true)
	print("[SaveManager] Saved slot %d" % slot_index)
	return true


func load_game(slot_index: int) -> bool:
	GameEvents.raise_load_started(slot_index)

	var path = _build_save_path(slot_index)
	if not _file_exists(path):
		push_warning("[SaveManager] Save missing: %s" % path)
		GameEvents.raise_load_completed(slot_index, false)
		return false

	var file = File.new()
	if file.open(path, File.READ) != OK:
		GameEvents.raise_load_completed(slot_index, false)
		return false

	var parsed = _parse_json(file.get_as_text())
	file.close()

	if parsed.empty():
		push_error("[SaveManager] Failed to parse save.")
		GameEvents.raise_load_completed(slot_index, false)
		return false

	if parsed.has("version") and int(parsed["version"]) > GameConstants.SAVE_DATA_VERSION:
		push_warning("[SaveManager] Save version newer than this build.")

	current_save_data = parsed
	_restore_registered_saveables()

	GameEvents.raise_load_completed(slot_index, true)
	print("[SaveManager] Loaded slot %d" % slot_index)
	return true


func delete_save(slot_index: int) -> bool:
	var path = _build_save_path(slot_index)
	if not _file_exists(path):
		return false
	var dir = Directory.new()
	var err = dir.remove(path)
	return err == OK


func _create_default_save(slot_index: int) -> Dictionary:
	return {
		"version": GameConstants.SAVE_DATA_VERSION,
		"slot_index": slot_index,
		"timestamp_utc": _utc_timestamp(),
		"playtime_seconds": 0.0,
		"current_scene": GameConstants.SCENE_GAME_WORLD,
		"player_name": "Yodha",
		"player_position": {"x": 512.0, "y": 288.0},
		"player_stats": {
			"level": 1,
			"experience": 0,
			"health": 100.0,
			"max_health": 100.0,
			"stamina": 100.0,
			"max_stamina": 100.0,
			"souls": 0
		},
		"inventory": [],
		"equipment": {},
		"quests": {},
		"skills": {},
		"world_flags": {},
		"custom_blocks": {}
	}


func _sync_live_player_snapshot() -> void:
	var tree = get_tree()
	if tree == null:
		return

	var players = tree.get_nodes_in_group(GameConstants.GROUP_PLAYER)
	if players.empty():
		return

	var player = players[0]
	if not player.has_method("capture_state"):
		return

	var snapshot = player.capture_state()
	if snapshot.has("position"):
		current_save_data["player_position"] = snapshot["position"]
	if snapshot.has("health"):
		var stats = current_save_data.get("player_stats", {})
		stats["health"] = snapshot["health"]
		stats["max_health"] = snapshot.get("max_health", stats.get("max_health", 100.0))
		stats["stamina"] = snapshot.get("stamina", stats.get("stamina", 100.0))
		stats["max_stamina"] = snapshot.get("max_stamina", stats.get("max_stamina", 100.0))
		current_save_data["player_stats"] = stats


func _capture_registered_saveables() -> void:
	if not current_save_data.has("custom_blocks"):
		current_save_data["custom_blocks"] = {}

	current_save_data["custom_blocks"] = {}

	for save_id in _saveables.keys():
		var node = _saveables[save_id]
		if node != null and is_instance_valid(node):
			current_save_data["custom_blocks"][save_id] = node.capture_state()


func _restore_registered_saveables() -> void:
	if not current_save_data.has("custom_blocks"):
		return

	var blocks = current_save_data["custom_blocks"]
	for save_id in _saveables.keys():
		if blocks.has(save_id):
			var node = _saveables[save_id]
			if node != null and is_instance_valid(node):
				node.restore_state(blocks[save_id])


func _setup_auto_save_timer() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = GameConstants.AUTO_SAVE_INTERVAL_SECONDS
	_auto_save_timer.one_shot = false
	_auto_save_timer.autostart = false
	add_child(_auto_save_timer)
	_auto_save_timer.connect("timeout", self, "_on_auto_save_timeout")


func _on_game_state_changed(_previous: int, current: int) -> void:
	if _auto_save_timer == null:
		return
	if current == GameState.State.PLAYING and enable_auto_save:
		_auto_save_timer.start()
	else:
		_auto_save_timer.stop()


func _on_auto_save_timeout() -> void:
	if not enable_auto_save or not is_initialized:
		return
	if GameManager.active_save_slot < 0 or GameManager.current_state != GameState.State.PLAYING:
		return
	save_game(GameManager.active_save_slot)


func _ensure_save_directory_exists() -> void:
	var dir = Directory.new()
	if not dir.dir_exists(GameConstants.SAVE_DIRECTORY):
		dir.make_dir_recursive(GameConstants.SAVE_DIRECTORY)


func _build_save_path(slot_index: int) -> String:
	return "%s/%s%d%s" % [
		GameConstants.SAVE_DIRECTORY,
		GameConstants.SAVE_FILE_PREFIX,
		slot_index,
		GameConstants.SAVE_FILE_EXTENSION
	]


func _file_exists(path: String) -> bool:
	var dir = Directory.new()
	return dir.file_exists(path)


func _parse_json(text: String) -> Dictionary:
	var result = JSON.parse(text)
	if result.error != OK:
		push_error("[SaveManager] JSON parse error at line %d" % result.error_line)
		return {}
	if typeof(result.result) != TYPE_DICTIONARY:
		return {}
	return result.result


func _utc_timestamp() -> String:
	# Unix timestamp — works on all Godot 3.x versions without extra APIs.
	return str(OS.get_unix_time())
