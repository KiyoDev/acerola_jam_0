# Level goal
class_name Door extends Area2D


@export var next_level : String
@export var collider : CollisionShape2D


func enter() -> void:
	GameManager.get_next_level(next_level.to_lower())
