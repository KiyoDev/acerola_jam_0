extends Node


signal switch_1_changed(on : bool)
signal switch_2_changed(on : bool)
signal switch_3_changed(on : bool)
signal switch_4_changed(on : bool)


# global switch states
var switch_1 : bool = false:
	set(value):
		switch_1 = value
		switch_1_changed.emit(value)
var switch_2 : bool = false:
	set(value):
		switch_2 = value
		switch_2_changed.emit(value)
var switch_3 : bool = false:
	set(value):
		switch_3 = value
		switch_3_changed.emit(value)
var switch_4 : bool = false:
	set(value):
		switch_4 = value
		switch_4_changed.emit(value)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var window : Window = get_tree().root
	var os : String = OS.get_name()
	var size : Vector2i = Vector2(2560, 1440) if os == "macOS" else Vector2(1280, 720)
	window.size = size
	#window.canvas_cull_mask &= 0b1111_1111_1111_1111_1111
	
	# center the window
	var screen : Vector2i = DisplayServer.screen_get_size()
	window.position = (screen / 2) - window.size / 2


func flip_switch(name : String) -> void:
	set(name, !get(name))
