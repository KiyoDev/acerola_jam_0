class_name HeldItem extends RigidBody2D

# Solid collision
@export var collider : CollisionPolygon2D
# Used to detect if player is within range to pick up the key
@export var area : Area2D


var held : bool = false

var original_parent : Node
var thrown : bool = false


func _ready() -> void:
	original_parent = get_parent()
	#area.body_entered.connect(_on_player_entered)
	#area.body_exited.connect(_on_player_exited)


func pickup() -> void:
	held = true
	collider.set_deferred("disabled", true)
	freeze = true


func drop(direction : int) -> void:
	held = false
	reparent(original_parent)
	global_position.x += direction * 16
	linear_velocity = Vector2(10 * direction, 0)
	collider.set_deferred("disabled", false)
	freeze = false


func throw(direction : int) -> void:
	held = false
	reparent(original_parent)
	global_position.x += direction * 16
	freeze = false
	linear_velocity = Vector2(300 * direction, 0)
	thrown = true
	collider.set_deferred("disabled", false)
	

#
#func _on_player_entered(body : Node) -> void:
	#freeze = true
#
#
#func _on_player_exited(body : Node) -> void:
	#pass
