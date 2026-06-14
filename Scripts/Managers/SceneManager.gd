extends Node

# Handles scene loading, fade transitions, and navigation history.

export var fade_duration_seconds: float = 0.3
export var fade_color: Color = Color(0.02, 0.01, 0.05, 1.0)

var is_initialized: bool = false
var is_transitioning: bool = false
var current_scene_path: String = ""

var _scene_history: Array = []
var _transition_layer: CanvasLayer
var _fade_rect: ColorRect


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	_build_transition_overlay()
	var scene = get_tree().current_scene
	if scene != null and scene.filename != "":
		current_scene_path = scene.filename


func initialize() -> void:
	if is_initialized:
		return
	is_initialized = true
	print("[SceneManager] Initialized")


func shutdown() -> void:
	is_initialized = false
	_scene_history.clear()


func go_to_main_menu() -> void:
	change_scene_async(GameConstants.SCENE_MAIN_MENU, true, false, true)


func change_scene_async(
	scene_path: String,
	use_fade: bool = true,
	push_history: bool = false,
	clear_history: bool = false
):
	if scene_path.empty():
		push_error("[SceneManager] Scene path is empty.")
		return false

	if not ResourceLoader.exists(scene_path):
		push_error("[SceneManager] Scene not found: %s" % scene_path)
		return false

	if is_transitioning:
		push_warning("[SceneManager] Transition already in progress.")
		return false

	is_transitioning = true
	GameEvents.raise_scene_transition_started(scene_path)

	if clear_history:
		_scene_history.clear()
	elif push_history and not current_scene_path.empty() and current_scene_path != scene_path:
		_scene_history.push_back(current_scene_path)

	if use_fade:
		yield(_fade_to(1.0), "completed")

	var err = get_tree().change_scene(scene_path)
	if err != OK:
		push_error("[SceneManager] change_scene failed (%s) for %s" % [str(err), scene_path])
		is_transitioning = false
		GameEvents.raise_scene_transition_finished(scene_path)
		return false

	current_scene_path = scene_path

	if use_fade:
		yield(_fade_to(0.0), "completed")

	is_transitioning = false
	GameEvents.raise_scene_transition_finished(scene_path)
	return true


func reload_current_scene_async(use_fade: bool = true):
	if current_scene_path.empty():
		return false
	return yield(change_scene_async(current_scene_path, use_fade), "completed")


func go_back_async(use_fade: bool = true):
	if _scene_history.empty():
		return false
	var previous = _scene_history.pop_back()
	return yield(change_scene_async(previous, use_fade), "completed")


func _build_transition_overlay() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 128
	_transition_layer.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(_transition_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(fade_color.r, fade_color.g, fade_color.b, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_transition_layer.add_child(_fade_rect)


func _fade_to(target_alpha: float):
	var tween = Tween.new()
	add_child(tween)
	var start_alpha = _fade_rect.color.a
	tween.interpolate_property(
		_fade_rect,
		"color:a",
		start_alpha,
		target_alpha,
		fade_duration_seconds,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
	tween.start()
	yield(tween, "tween_all_completed")
	tween.queue_free()
