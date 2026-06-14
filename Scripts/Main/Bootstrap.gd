extends Node

# Application entry scene. Hands off to the main menu once core services are live.


func _ready() -> void:
	print("[Bootstrap] Starting The Last Yodha...")
	if not GameManager.is_initialized:
		GameManager.initialize()
	SceneManager.go_to_main_menu()
