class_name Level extends Node2D

@export var spawn_point : SpawnPoint


func _ready() -> void:
	if !spawn_point:
		spawn_point = find_child("SpawnPoint")
	var player : Player = GameManager.PLAYER_SCN.instantiate()
	add_child(player)
	player.global_position = spawn_point.global_position
	player.death.connect(GameManager._on_player_death)
	GameManager.player = player
