class_name Player extends CharacterBody2D

signal death
signal collected_gem

enum Gravity {
	DOWN,
	UP,
	LEFT,
	RIGHT
}


const SPEED := 90
const JUMP_VELOCITY := -280
const MAX_VELOCITY := 400
const MIN_VELOCITY := -500
const COYOTE_FRAMES := 4
const JUMP_BUFFER_FRAMES := 5
const CORNER_CORRECTION := Vector2(6, 1)
const HOLD_DELAY := 20


@export var floor_cast : RayCast2D
@export var body_collision : CollisionShape2D 
@export var body_area : Area2D
@export var hands_area : Area2D
@export var hands_collision : CollisionShape2D

@export var sprite : Sprite2D
@export var animator : AnimationPlayer
#@onready var skills : Node = $Skills # used for abilities?


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")

# states
var dead := false

var facing_direction := 1
var crouching := false

# physics
var jumping := false
var jumping_down := false # TODO: used if want to jump down 1-way platforms
var released_jump := false
var coyote := false
var jump_buffered := false
var can_buffer := false
var last_floor := false
var sliding := false
var speed_modifier := 1.0
var gravity_multiplier := 0.8

# timers
var coyote_t := 0
var jump_buffer_t := 0
var hold_t := 0

var gravity_state : Gravity = Gravity.DOWN

# item
var released_item := false
var target_item : HeldItem:
	set(value):
		print("TARGET_)CHJANGE=%s" % [value])
		target_item = value
var held_item : HeldItem
var door : Door
var interactable : Node


func _ready() -> void:
	body_area.area_entered.connect(_on_area_entered_body)
	body_area.area_exited.connect(_on_area_exited_body)
	hands_area.area_entered.connect(_on_held_item_entered)
	hands_area.area_exited.connect(_on_held_item_exited)
	
	set_physics_process(false)
	set_process_unhandled_input(false)
	body_collision.set_deferred("disabled", true)
	
	animator.play("spawning")
	animator.animation_finished.connect(_ready_idle)
	
	GameManager.transitioned_in.connect(func() -> void: 
		set_physics_process(true)
		set_process_unhandled_input(true)
		body_collision.set_deferred("disabled", false))
	# physics


func _ready_idle(name : String) -> void:
	animator.play("idle")
	animator.animation_finished.disconnect(_ready_idle)


func _unhandled_input(event : InputEvent) -> void:
	if !event.is_action_type() or (!(event is InputEventAction) and !(event is InputEventKey) and !(event is InputEventJoypadButton) and !(event is InputEventJoypadMotion)): return
	
	var consumed := false
	
	# Don't jump if inside a solid tile
	#if !inside_tile:
	# prevent input from doing anything if input was already consumed
	consumed = jump(consumed)
	consumed = release_jump(consumed)
	
	if Input.is_action_just_pressed("input_up") and on_floor():
		if door:
			# get rect w/ global position to check if position is within the area rect
			var rect : Rect2 = Rect2(door.global_position - (door.collider.shape.get_rect().size / 2), door.collider.shape.get_rect().size)
			var inside : bool = rect.has_point(global_position)
			if inside:
				set_physics_process(false)
				set_process_unhandled_input(false)
				body_collision.set_deferred("disabled", true)
				velocity = Vector2.ZERO
				
				GameManager.play_sfx("next")
				door.enter()
	elif Input.is_action_just_pressed("hold") and interactable:
		interactable._interact(self)
	elif Input.is_action_just_pressed("reset"):
		GameManager.reload_level()
		freeze()


func _physics_process(delta: float) -> void:
	tick_timers()
	handle_item_hold() 
	
	sprite.flip_v = gravity_state == Gravity.UP
	# flip sprite and colliders
	if sprite.flip_v:
		if body_collision.rotation == 0:
			body_collision.rotation = PI / 2
			body_area.rotation = PI / 2
	else:
		if body_collision.rotation > 0:
			body_collision.rotation = 0
			body_area.rotation = 0
	
	handle_gravity(delta)
	
	# Start coyote time
	#print("on_floor()=%s" % [on_floor()])
	if !on_floor() and last_floor and !jumping:
		coyote = true
	
	last_floor = on_floor()
	
	# reset jupming state
	if !last_floor and jumping:
		jumping = false
	
	# reset jumping down state (from jumping down one-way platforms)
	if !last_floor and jumping_down and !coyote:
		jumping_down = false
	move_and_slide()


func face_direction(face_right : bool) -> void:
	facing_direction = 1 if face_right else -1
	sprite.flip_h = !face_right
	hands_collision.position.x = hands_area.position.x + (5 if face_right else -5)


func gravity_modifier() -> int:
	return 1 if gravity_state == Gravity.DOWN else -1


func handle_item_hold() -> void:
	if Input.is_action_pressed("hold") and !released_item:
		print_debug("target_item=%s, %s" % [target_item, held_item])
		grab_item(target_item)
		#if target_item and !held_item:
			#released_item = false
			#held_item = target_item
			#held_item.pickup(hands_collision)
			##held_item.reparent(hands_collision)
			##held_item.global_position = hands_collision.global_position
			#held_item.consumed.connect(func() -> void: held_item = null)
			#held_item.grabbed.connect(func() -> void: held_item = null)
		target_item = null
	elif Input.is_action_just_released("hold"):
		if held_item:
			released_item = true
			#if velocity.x == 0:
			held_item.consumed.disconnect(remove_held_item)
			held_item.grabbed.disconnect(remove_held_item)
			held_item.drop(velocity, facing_direction)
			#else:
				#held_item.throw(facing_direction)
			held_item = null


func grab_item(item : HeldItem) -> void:
	print_debug("item=%s" % [item])
	if item and !held_item:
		held_item = item
		held_item.pickup(hands_collision)
		print_debug("grab held_item=%s" % [held_item])
		#held_item.reparent(hands_collision)
		#held_item.global_position = hands_collision.global_position
		held_item.consumed.connect(remove_held_item)
		held_item.grabbed.connect(remove_held_item)
		released_item = false
		#target_item = null


func remove_held_item() -> void: 
	released_item = true
	if held_item:
		held_item.consumed.disconnect(remove_held_item)
		held_item.grabbed.disconnect(remove_held_item)
	held_item = null
	target_item = null


func handle_gravity(delta : float) -> void:
	# Add the gravity.
	if not on_floor():
		velocity.y += gravity * gravity_multiplier * gravity_modifier() * delta / 2
	
	if not on_floor():
		crouching = false
		var grav := gravity * gravity_multiplier * gravity_modifier()
		if coyote:
			grav = 0
		# let player hang a little more towards the peak of jump by reducing grav near peak
		elif !jumping and -100 < velocity.y and velocity.y < 100:
			grav = gravity * gravity_multiplier * gravity_modifier() / 2
		
		velocity.y += grav * delta
	
	buffered_jump() # try to perform buffered jump when holding jump right before landing
	
	# Handle normal jump
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY  * gravity_modifier()
	
	# Get directional inputs
	var direction := Input.get_vector("input_left", "input_right", "input_up", "input_down").round()
	var sign := direction.sign()
	# use sign instead of direction if theres a joystick with drift messing with axis input
	# should only flip sprite if getting inputs; means should account for forced movement
	if sign.x != 0:
		velocity.x = sign.x * roundi(SPEED * speed_modifier)
		face_direction(sign.x > 0)
		#facing_direction = sign.x
		#if sign.x < 0:
			#sprite.flip_h = true
			#hands_collision.position.x = hands_area.position.x - 5
		#else:
			#sprite.flip_h = false
			#hands_collision.position.x = hands_area.position.x + 5
		animator.play(&"walking")
		crouching = false
	else:
		if on_floor():
			# Handle animations
			if sign.y > 0 and !crouching:
				animator.play(&"crouching")
				crouching = true
			elif sign.y <= 0:
				crouching = false
				if animator.current_animation != &"idle":
					animator.play(&"idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if rising(): # rising up
		animator.play(&"rising")
		var test_vel := Vector2(0, velocity.y * delta)
		if test_move(transform, test_vel):
			# Check if head is getting blocked from left or right side when jumping
			# left = 0b01, right = 0b10
			var dir_flags := corner_correction_direciton(delta, test_vel)
			# If blocked in left or right direction, try to correct position
			if 0 < dir_flags and dir_flags < 0b11:
				# While player is blocked when trying to move in that direction, move 1 pixel out
				var tmp_pos := position
				while test_move(transform, test_vel):
					position.x = roundi(position.x) + (1 if dir_flags == 0b01 else -1)
					# if trying to move more than correction, then reset position to not teleport
					if abs(tmp_pos.x - position.x) > 8:
						position = tmp_pos
						break
	elif falling():
		animator.play(&"falling")
		# Clamp velocity so doesn't infinitely accelerate
		velocity.y = clamp(velocity.y, MIN_VELOCITY, MAX_VELOCITY)


func rising() -> bool:
	return (velocity.y < 0 and gravity_state == Gravity.DOWN) or (velocity.y > 0 and gravity_state == Gravity.UP)


func falling() -> bool:
	return (velocity.y > 0 and gravity_state == Gravity.DOWN) or (velocity.y < 0 and gravity_state == Gravity.UP)


## Handles ticking timers for various physics routines; ex. coyote time and jump buffering
func tick_timers() -> void:
	if jump_buffered:
		jump_buffer_t += 1
		if jump_buffer_t == JUMP_BUFFER_FRAMES:
			jump_buffered = false
			can_buffer = false
			jump_buffer_t = 0
	
	if coyote:
		coyote_t += 1
		if coyote_t == COYOTE_FRAMES:
			coyote = false
			coyote_t = 0
	
	if released_item:
		hold_t += 1
		if hold_t == HOLD_DELAY:
			released_item = false
			hold_t = 0
		


func jump(consumed : bool) -> bool:
	if !consumed and Input.is_action_just_pressed("jump") and !jumping_down and (on_floor() or coyote):
		#print_debug("is_on_floor() or coyote=%s, %s, %s" % [is_on_floor(), coyote, jumping_down])
		jumping = true
		#jump_sfx()
		velocity.y = (JUMP_VELOCITY - (velocity.y if coyote else 0)) * gravity_modifier()
		animator.play(&"jump_up")
		GameManager.player_jumped.emit()
		GameManager.player_sfx("jump")
		return true
	return false


## Force player to start falling if they release jump; ties jump height to duration of holding input
func release_jump(consumed : bool) -> bool:
	if !consumed and Input.is_action_just_released("jump") and !on_floor() and rising():
		velocity.y *= 0.5
		released_jump = true
		return true
	return false


## Try to perform buffered jump when holding jump right before landing
func buffered_jump() -> bool:
	# Prepare to buffer jump when in air
	if Input.is_action_just_pressed("jump") and !jumping:
		can_buffer = true
	elif Input.is_action_pressed("jump") and !jumping and can_buffer:
		# If holding jump when can buffer
		if !on_floor() and !jump_buffered:
			jump_buffered = true
		# If holding jump when hit ground within buffer timer, perform jump right as land
		elif on_floor() and jump_buffered:
			#jump_sfx()
			jumping = true
			can_buffer = false # finished buffer
			velocity.y = JUMP_VELOCITY * gravity_modifier()
			animator.play(&"jump_up")
			GameManager.player_jumped.emit()
			GameManager.player_sfx("jump")
	return false


func on_floor() -> bool:
	return is_on_floor()


## Return which side of the player is trying to go into the ceiling
func corner_correction_direciton(delta : float, vel : Vector2) -> int:
	var dir_flags := 0 # left=0b01, right=0b10
	# check corners from furthest correction towards base position
	# check left
	for l in range(-CORNER_CORRECTION.x, 0):
		var t := transform
		t.origin.x += l
		if test_move(t, vel):
			dir_flags |= 0b01
		else: # not blocked at some point along the path, so will not be blocked when corrected; break out of loop
			dir_flags &= 0b10
			break
	# check right
	for r in range(CORNER_CORRECTION.x, 0, -1):
		var t := transform
		t.origin.x += r
		if test_move(t, vel):
			dir_flags |= 0b10
		else: # not blocked at some point along the path, so will not be blocked when corrected; break out of loop
			dir_flags &= 0b01
			break
	#print_debug("vel_y=%s, %s, %s" % [vel.y, transform, dir_flags])
	return dir_flags


func set_gravity(state : int) -> void:
	gravity_state = clampi(state, Gravity.DOWN, Gravity.UP)


func flip_gravity() -> void:
	gravity_state = Gravity.DOWN if gravity_state == Gravity.UP else Gravity.UP
	# swap which direction is up so built-in physics methods calculate correctly (like move_and_slide())
	up_direction = Vector2.UP if gravity_state == Gravity.DOWN else Vector2.DOWN if gravity_state == Gravity.UP else Vector2.UP


func freeze() -> void:
	set_physics_process(false)
	set_process_unhandled_input(false)
	body_collision.set_deferred("disabled", true)


func do_death() -> void:
	GameManager.player_sfx("death")
	freeze()
	dead = true
	animator.play("death")
	await animator.animation_finished
	death.emit(self)


func _on_area_entered_body(area : Area2D) -> void:
	# door layer
	if (area.collision_layer & 0b0100_0000_0000_0000) > 0:
		door = area
	# hazard layer
	elif (area.collision_layer & 0b1000_0000_0000_0000) > 0 and !dead:
		do_death()
	# collectible layer
	elif area is Gem:
		GameManager.play_sfx("gem")
		area.collect()
		collected_gem.emit()
	# interactible layer
	elif (area.collision_layer & 0b0010_0000_0000_0000) > 0:
		interactable = area


func _on_area_exited_body(area : Area2D) -> void:
	# door layer
	if (area.collision_layer & 0b0100_0000_0000_0000) > 0:
		door = null
	# interactible layer
	elif (area.collision_layer & 0b0010_0000_0000_0000) > 0:
		interactable = null


func _on_held_item_entered(item_area : Area2D) -> void:
	if target_item: return
	target_item = item_area.get_parent()
	print_debug("t entered=%s, %s, %s" % [target_item, target_item.collider.disabled, item_area.collision_layer])


func _on_held_item_exited(item_area : Area2D) -> void:
	target_item = null

