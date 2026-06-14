extends Node
class_name SaveableNode

# Base node for world objects that persist through save/load.

export var save_id: String = ""


func _enter_tree() -> void:
	if save_id.empty():
		save_id = name
	SaveManager.register_saveable(self)


func _exit_tree() -> void:
	if SaveManager != null:
		SaveManager.unregister_saveable(self)


func capture_state() -> Dictionary:
	return {}


func restore_state(state: Dictionary) -> void:
	pass
