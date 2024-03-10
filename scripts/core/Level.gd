class_name Level extends Node2D

signal loaded

@export var face_right := true
@export var spawn_point : SpawnPoint


func _ready() -> void:
	load_level()


func load_level() -> void:
	if !spawn_point:
		spawn_point = find_child("SpawnPoint")
	GameManager.register_level(self)
	
	loaded.emit()
