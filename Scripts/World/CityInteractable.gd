extends Area2D
class_name CityInteractable

export(String, "vehicle", "shop", "npc") var interaction_type := "npc"
export var display_name := "Citizen"
export var prompt := "Press E"
export var payout := 0

func _ready() -> void:
	add_to_group("city_interactable")
	collision_layer = 0
	collision_mask = GameConstants.LAYER_PLAYER
	if get_node_or_null("CollisionShape2D") == null:
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 34
		shape.shape = circle
		add_child(shape)

func interact(player) -> Dictionary:
	match interaction_type:
		"vehicle":
			return {"type": interaction_type, "title": display_name, "message": "Entered vehicle. WASD to cruise, E to exit.", "vehicle": self}
		"shop":
			return {"type": interaction_type, "title": display_name, "message": "Shop placeholder: snacks, repair kits, and style upgrades coming soon.", "money_delta": -25}
		_:
			return {"type": interaction_type, "title": display_name, "message": str(get_meta("message") if has_meta("message") else "NPC placeholder: new street mission contact unlocked."), "money_delta": payout}
