extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var window : Window = get_tree().root
	var os : String = OS.get_name()
	var size : Vector2i = Vector2(2560, 1440) if os == "macOS" else Vector2(1280, 720)
	window.size = size
	
	# center the window
	var screen : Vector2i = DisplayServer.screen_get_size()
	window.position = (screen / 2) - window.size / 2
