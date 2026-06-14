extends Object
class_name GameConstants

# Centralized paths and tuning values (low-RAM friendly defaults).

const SAVE_DIRECTORY = "user://saves"
const SAVE_FILE_PREFIX = "slot_"
const SAVE_FILE_EXTENSION = ".json"
const MAX_SAVE_SLOTS = 3
const SAVE_DATA_VERSION = 1
const AUTO_SAVE_INTERVAL_SECONDS = 300.0

# Scene paths
const SCENE_BOOTSTRAP = "res://Scenes/Main/Bootstrap.tscn"
const SCENE_MAIN_MENU = "res://Scenes/UI/MainMenu.tscn"
const SCENE_GAME_WORLD = "res://Scenes/World/GameWorld.tscn"
const SCENE_PLAYER = "res://Scenes/Player/Player.tscn"
const SCENE_GAME_HUD = "res://Scenes/UI/GameHUD.tscn"
const SCENE_TRAINING_DUMMY = "res://Scenes/World/TrainingDummy.tscn"
const SCENE_SHADE_STALKER = "res://Scenes/Enemies/ShadeStalker.tscn"
const SCENE_FALLEN_GUARD = "res://Scenes/Enemies/FallenGuard.tscn"
const SCENE_BOSS_CRIMSON_WARDEN = "res://Scenes/Enemies/BossCrimsonWarden.tscn"
const SCENE_LOADING = "res://Scenes/UI/LoadingScreen.tscn"
const SCENE_PAUSE_MENU = "res://Scenes/UI/PauseMenu.tscn"

# Physics layer bit masks
const LAYER_WORLD = 1
const LAYER_PLAYER = 2
const LAYER_ENEMIES = 4
const LAYER_PLAYER_HITBOX = 8
const LAYER_ENEMY_HITBOX = 16
const LAYER_INTERACTABLES = 32
const LAYER_LOOT = 64

# Groups
const GROUP_PLAYER = "player"
const GROUP_ENEMIES = "enemies"
const GROUP_BOSSES = "bosses"
const GROUP_NPCS = "npcs"
const GROUP_SAVEABLES = "saveables"
const GROUP_PERSIST = "persist"


# Godot 3 compatible helpers (no randf_range / Vector2.move_toward).
static func rand_range_float(from: float, to: float) -> float:
	return rand_range(from, to)


static func vector_move_toward_zero(vec: Vector2, max_delta: float) -> Vector2:
	var length = vec.length()
	if length <= 0.0001:
		return Vector2.ZERO
	if max_delta >= length:
		return Vector2.ZERO
	return vec * ((length - max_delta) / length)
