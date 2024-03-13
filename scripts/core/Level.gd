class_name Level extends Node2D

signal loaded

@export var floor := -1
@export var face_right := true
@export var spawn_point : SpawnPoint

var screen_area : Area2D


func _ready() -> void:
	load_level()
	screen_area = Area2D.new()
	add_child(screen_area)
	var collision := CollisionShape2D.new()
	screen_area.add_child(collision)
	var rect := RectangleShape2D.new()
	rect.size = get_viewport_rect().size
	collision.shape = rect
	screen_area.collision_layer = 0b0010_0000_0000_0000_0000
	screen_area.collision_mask = ~0


func load_level() -> void:
	if !spawn_point:
		spawn_point = find_child("SpawnPoint")
	GameManager.register_level(self)
	
	loaded.emit()
