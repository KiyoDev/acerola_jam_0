class_name HeldItem extends RigidBody2D


signal consumed


# Solid collision
@export var collider : CollisionPolygon2D
# Used to detect if player is within range to pick up the key
@export var area : Area2D
@export var animator : AnimationPlayer
@export var sprite : Sprite2D


var held : bool = false

var original_parent : Node
var released : bool = false
var gravity_down : bool = true


func _ready() -> void:
	original_parent = get_parent()
	#area.body_entered.connect(_on_player_entered)
	#area.body_exited.connect(_on_player_exited)
	print(collision_layer)


func _physics_process(delta: float) -> void:
	if !held and linear_velocity == Vector2.ZERO:
		if collision_layer & 0b0100 == 0:
			collision_layer |= 0b0100
		released = false
	#else:
		#if collision_mask & 1 > 0:
			#collision_mask &= ~0b1


func consume() -> void:
	consumed.emit()
	queue_free()


func pickup() -> void:
	held = true
	collision_layer &= ~0b0100
	freeze = true
	if animator:
		animator.play("held")


func drop(velocity : Vector2, direction : int) -> void:
	held = false
	reparent(original_parent)
	linear_velocity = Vector2(80 * direction + velocity.x, -10)
	released = true
	freeze = false
	if animator:
		animator.play("loose")


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
