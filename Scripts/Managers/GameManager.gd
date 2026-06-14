extends Node

# Top-level coordinator autoload. Owns game state, pause logic, and session flow.

var current_state: int = GameState.State.BOOT
var previous_state: int = GameState.State.BOOT
var is_initialized: bool = false
var active_save_slot: int = -1
var session_playtime_seconds: float = 0.0


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	initialize()


func _process(delta: float) -> void:
	if not is_initialized or current_state != GameState.State.PLAYING:
		return
	session_playtime_seconds += delta


func initialize() -> void:
	if is_initialized:
		return

	SaveManager.initialize()
	SceneManager.initialize()
	transition_to(GameState.State.MAIN_MENU)
	is_initialized = true
	print("[GameManager] Initialized — Sun City Open World (Godot 3 / low-spec)")


func shutdown() -> void:
	if not is_initialized:
		return
	SaveManager.shutdown()
	SceneManager.shutdown()
	is_initialized = false


func transition_to(new_state: int) -> void:
	if current_state == new_state:
		return

	previous_state = current_state
	current_state = new_state
	_apply_state_side_effects(new_state)
	GameEvents.raise_state_changed(previous_state, current_state)


func start_new_game(slot_index: int = 0) -> void:
	active_save_slot = int(clamp(slot_index, 0, GameConstants.MAX_SAVE_SLOTS - 1))
	session_playtime_seconds = 0.0

	SaveManager.create_new_game_data(active_save_slot)
	GameEvents.raise_new_game_started()
	transition_to(GameState.State.LOADING)

	var loaded = yield(SceneManager.change_scene_async(GameConstants.SCENE_GAME_WORLD), "completed")
	if loaded:
		_on_new_game_scene_ready()
	else:
		push_error("[GameManager] Failed to load game world.")
		transition_to(GameState.State.MAIN_MENU)


func continue_game(slot_index: int = 0) -> void:
	active_save_slot = int(clamp(slot_index, 0, GameConstants.MAX_SAVE_SLOTS - 1))

	if not SaveManager.has_save(active_save_slot):
		push_warning("[GameManager] No save in slot %d." % active_save_slot)
		return

	transition_to(GameState.State.LOADING)

	if not SaveManager.load_game(active_save_slot):
		transition_to(GameState.State.MAIN_MENU)
		return

	var target_scene = GameConstants.SCENE_GAME_WORLD
	if SaveManager.current_save_data.has("current_scene"):
		target_scene = str(SaveManager.current_save_data["current_scene"])

	var loaded = yield(SceneManager.change_scene_async(target_scene), "completed")
	if loaded:
		_on_continue_game_scene_ready()
	else:
		push_error("[GameManager] Failed to load saved scene.")
		transition_to(GameState.State.MAIN_MENU)


func return_to_main_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	transition_to(GameState.State.LOADING)

	var loaded = yield(
		SceneManager.change_scene_async(GameConstants.SCENE_MAIN_MENU, true, false, true),
		"completed"
	)
	if loaded:
		transition_to(GameState.State.MAIN_MENU)


func pause_game() -> void:
	if current_state != GameState.State.PLAYING:
		return
	get_tree().paused = true
	transition_to(GameState.State.PAUSED)
	GameEvents.raise_game_paused()


func resume_game() -> void:
	if current_state != GameState.State.PAUSED:
		return
	get_tree().paused = false
	transition_to(GameState.State.PLAYING)
	GameEvents.raise_game_resumed()


func toggle_pause() -> void:
	if current_state == GameState.State.PLAYING:
		pause_game()
	elif current_state == GameState.State.PAUSED:
		resume_game()


func request_quick_save() -> void:
	if active_save_slot < 0:
		push_warning("[GameManager] Quick save ignored — no active slot.")
		return
	SaveManager.save_game(active_save_slot)


func quit_to_desktop() -> void:
	shutdown()
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		quit_to_desktop()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and current_state in [GameState.State.PLAYING, GameState.State.PAUSED]:
		toggle_pause()
		get_tree().set_input_as_handled()
	elif event.is_action_pressed("quick_save") and current_state == GameState.State.PLAYING:
		request_quick_save()
		get_tree().set_input_as_handled()


func _on_new_game_scene_ready() -> void:
	transition_to(GameState.State.PLAYING)
	SaveManager.save_game(active_save_slot)


func _on_continue_game_scene_ready() -> void:
	if SaveManager.current_save_data.has("playtime_seconds"):
		session_playtime_seconds = float(SaveManager.current_save_data["playtime_seconds"])
	transition_to(GameState.State.PLAYING)


func _apply_state_side_effects(current: int) -> void:
	match current:
		GameState.State.PLAYING:
			get_tree().paused = false
			Engine.time_scale = 1.0
		GameState.State.PAUSED, GameState.State.DIALOGUE, GameState.State.INVENTORY, GameState.State.CUTSCENE:
			get_tree().paused = current == GameState.State.PAUSED
		GameState.State.MAIN_MENU:
			get_tree().paused = false
			Engine.time_scale = 1.0
			active_save_slot = -1
