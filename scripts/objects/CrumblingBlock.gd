class_name CrumblingBlock extends RigidBody2D


enum {
	IDLE,
	#WEIGHTED,
	SHAKING,
	FALLING
}


@export var sprite : Sprite2D
@export var collider : CollisionPolygon2D
@export var animator : AnimationPlayer
@export var area : Area2D
@export var area_collider : CollisionShape2D

@export var frames := 60

var state := IDLE
var time := 0

var original_pos : Vector2


func _ready() -> void:
	set_physics_process(false)
	#area.area_entered.connect(_on_area_enter)
	area.area_exited.connect(_on_area_exit)
	area.body_entered.connect(_on_player_enter)
	#area.body_exited.connect(_on_player_exit)
	gravity_scale = 0
	original_pos = global_position


func _physics_process(delta: float) -> void:
	if state == FALLING or state == IDLE:
		return
		
	time += 1
	if time == frames:
		state += 1
		time = 0
		
		match state:
			#WEIGHTED:
				#animator.play("shake")
				#global_position.y += 1
			#SHAKING:
				#animator.play("shake")
			FALLING:
				animator.play("RESET")
				#collider.disabled = true
				area_collider.disabled = true
				collider.set_deferred("disabled", true)
				area_collider.set_deferred("disabled", true)
				gravity_scale = 1
				set_physics_process(false)


func _on_player_enter(body : Node) -> void:
	if body is Player and body.on_floor():
		state = SHAKING
		time = 0
		set_physics_process(true)
		animator.play("shake")
		#body.reparent(self)


#func _on_player_exit(body : Node) -> void:
	#if collider.disabled: return
	#state = IDLE
	#time = 0
	#global_position = original_pos
	#animator.play("RESET")
	#set_physics_process(false)


func _on_area_exit(area : Area2D) -> void:
	if area.collision_layer == 0b0010_0000_0000_0000_0000 and !area_collider.disabled:
		queue_free()
