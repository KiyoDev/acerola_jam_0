extends TileMap


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _input(event: InputEvent) -> void:
	if !event.is_action_type() or (!(event is InputEventAction) and !(event is InputEventKey) and !(event is InputEventJoypadButton) and !(event is InputEventJoypadMotion)): return
	
	if Input.is_action_just_pressed("jump"):
		GameManager.get_next_level("level_1")
