class_name Hazard extends PhysicsBody2D

@export var area : Area2D


#func _ready() -> void:
	#area.body_entered.connect(_on_player_entered)
	#
#
#func _on_player_entered(body : Node) -> void:
	#pass
