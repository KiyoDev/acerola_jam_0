class_name HeldItem extends RigidBody2D


signal consumed
signal grabbed

const CURSOR_SCN : PackedScene = preload("res://assets/items/item_cursor.tscn")

# Solid collision
@export var collider : CollisionPolygon2D
# Used to detect if player is within range to pick up the key
@export var area : Area2D
@export var area_collider : CollisionShape2D
@export var animator : AnimationPlayer
@export var sprite : Sprite2D


var held : bool = false

var original_collision_layer : int
var original_parent : Node
var released : bool = false
var gravity_down : bool = true


func _ready() -> void:
	original_parent = get_parent()
	#area.body_entered.connect(_on_player_entered)
	#area.body_exited.connect(_on_player_exited)
	original_collision_layer = collision_layer
	print(collision_layer)
	var cursor : AnimatedSprite2D = CURSOR_SCN.instantiate()
	add_child(cursor)
	cursor.position.y -= 12


func _physics_process(delta: float) -> void:
	if !held and linear_velocity == Vector2.ZERO:
		if collision_layer & original_collision_layer == 0:
			collision_layer = original_collision_layer
		released = false


func consume() -> void:
	consumed.emit()
	queue_free()


func pickup(node : Node) -> void:
	held = true
	collision_layer &= ~0b0001_0000_0000_0000_0000
	freeze = true
	reparent(node)
	global_position = node.global_position
	if animator:
		animator.play("held")
	grabbed.emit()


func drop(velocity : Vector2, direction : int) -> void:
	held = false
	reparent(original_parent)
	linear_velocity = Vector2(80 * direction + velocity.x, -10)
	released = true
	freeze = false
	if animator:
		animator.play("loose")


func enable_area() -> void:
	area_collider.set_deferred("disabled", false)
	area_collider.disabled = false


func disable_area() -> void:
	area_collider.set_deferred("disabled", true)
	area_collider.disabled = true


func gravity_modifier() -> int:
	return 1 if gravity_down else -1
	
	
func flip_gravity() -> void:
	gravity_down = !gravity_down
	
	gravity_scale *= -1
	print("g=",gravity_down)
	if gravity_down:
		set_deferred("rotation", 0)
		#collider.position.y = -3
		#area.position.y = -2
		sprite.flip_h = false
	else:
		set_deferred("rotation", PI)
		#collider.position.y = -11
		#area.position.y = -3
		sprite.flip_h = true
	# swap which direction is up so built-in physics methods calculate correctly (like move_and_slide())
	#up_direction = Vector2.UP if gravity_state == Gravity.DOWN else Vector2.DOWN if gravity_state == Gravity.UP else Vector2.UP
	
#
#func _on_player_entered(body : Node) -> void:
	#freeze = true
#
#
#func _on_player_exited(body : Node) -> void:
	#pass
