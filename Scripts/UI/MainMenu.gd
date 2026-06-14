extends Control

# Main menu with themed buttons and save-aware continue.


func _ready() -> void:
	$CenterContainer/MenuPanel/NewGameButton.connect("pressed", self, "_on_new_game_pressed")
	$CenterContainer/MenuPanel/ContinueButton.connect("pressed", self, "_on_continue_pressed")
	$CenterContainer/MenuPanel/QuitButton.connect("pressed", self, "_on_quit_pressed")
	_refresh_continue_button()
	GameManager.transition_to(GameState.State.MAIN_MENU)


func _refresh_continue_button() -> void:
	var has_save = SaveManager.has_save(0)
	$CenterContainer/MenuPanel/ContinueButton.disabled = not has_save
	$CenterContainer/MenuPanel/TitleLabel.text = "Sun City Open World"
	if has_save:
		$CenterContainer/MenuPanel/VersionLabel.text = "Welcome back — continue your city run"
	else:
		$CenterContainer/MenuPanel/VersionLabel.text = "Press New Game to hit the streets"


func _on_new_game_pressed() -> void:
	GameManager.start_new_game(0)


func _on_continue_pressed() -> void:
	GameManager.continue_game(0)


func _on_quit_pressed() -> void:
	GameManager.quit_to_desktop()
