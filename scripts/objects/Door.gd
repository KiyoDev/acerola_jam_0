# Level goal
class_name Door extends Area2D


@export var next_level : String
@export var collider : CollisionShape2D


func enter() -> void:
	print("entered door")
	GameManager.get_next_level(next_level)
