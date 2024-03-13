@tool
class_name JumpBlock extends StaticBody2D


@export var sprite : AnimatedSprite2D
@export var collider : CollisionPolygon2D

@export var on := true:
	set(value):
		on = value
		
		if sprite and collider:
			if on:
				sprite.animation = "on"
				collider.disabled = false
			else:
				sprite.animation = "off"
				collider.disabled = true


func _ready() -> void:
	GameManager.player_jumped.connect(_on_player_jumped)


func _on_player_jumped() -> void:
	on = !on
