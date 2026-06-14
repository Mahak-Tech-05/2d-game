extends Object
class_name GameState

# High-level application states used to gate input, UI, and simulation.
enum State {
	BOOT,
	MAIN_MENU,
	LOADING,
	PLAYING,
	PAUSED,
	DIALOGUE,
	INVENTORY,
	CUTSCENE,
	GAME_OVER,
	VICTORY
}
