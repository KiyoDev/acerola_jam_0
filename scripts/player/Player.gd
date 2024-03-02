class_name Player extends CharacterBody2D


enum Gravity {
	DOWN,
	UP,
	LEFT,
	RIGHT
}


const SPEED := 120
const JUMP_VELOCITY := -340
const MAX_VELOCITY := 400
const MIN_VELOCITY := -500
const COYOTE_FRAMES := 4
const JUMP_BUFFER_FRAMES := 6
const CORNER_CORRECTION := Vector2(6, 1)


@export var floor_cast : RayCast2D
@export var body_collision : CollisionShape2D 
@export var body_area : Area2D

@export var sprite : Sprite2D
@export var animator : AnimationPlayer
#@onready var skills : Node = $Skills # used for abilities?


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")

var coins := 0

var facing_direction := 1
var crouching := false
var jumping := false
var jumping_down := false # TODO: used if want to jump down 1-way platforms
var released_jump := false
var coyote := false
var jump_buffered := false
var can_buffer := false
var last_floor := false

var speed_modifier := 1.0
var coyote_t := 0
var jump_buffer_t := 0

var gravity_state : Gravity = Gravity.DOWN


func _ready() -> void:
	body_area.area_entered.connect(_on_area_entered_body)
	
	# physics


func _unhandled_input(event : InputEvent) -> void:
	if !event.is_action_type() or (!(event is InputEventAction) and !(event is InputEventKey) and !(event is InputEventJoypadButton) and !(event is InputEventJoypadMotion)): return
	
	var consumed := false
	
	# Don't jump if inside a solid tile
	#if !inside_tile:
	# prevent input from doing anything if input was already consumed
	consumed = jump(consumed)
	consumed = release_jump(consumed)

	var just_pressed := event.is_pressed() and not event.is_echo()
	if Input.is_key_pressed(KEY_1) and just_pressed:
		gravity_state = Gravity.DOWN
	elif Input.is_key_pressed(KEY_2) and just_pressed:
		gravity_state = Gravity.UP


func _physics_process(delta: float) -> void:
	sprite.flip_v = gravity_state == Gravity.UP
	tick_timers()
	handle_gravity(delta)
	
	# Start coyote time
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


func gravity_modifier() -> int:
	return 1 if gravity_state == Gravity.DOWN else -1


func handle_gravity(delta : float) -> void:
	# Add the gravity.
	if not on_floor():
		velocity.y += gravity * gravity_modifier() * delta / 2
	
	if not on_floor():
		crouching = false
		var grav := gravity * gravity_modifier()
		if coyote:
			grav = 0
		# let player hang a little more towards the peak of jump by reducing grav near peak
		elif !jumping and -100 < velocity.y and velocity.y < 100:
			grav = gravity * gravity_modifier() / 2
		
		velocity.y += grav * delta
	
	buffered_jump() # try to perform buffered jump when holding jump right before landing
	
	# Handle normal jump
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY  * gravity_modifier()
	
	# Get directional inputs
	var direction := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down").round()
	var sign := direction.sign()
	# use sign instead of direction if theres a joystick with drift messing with axis input
	# should only flip sprite if getting inputs; means should account for forced movement
	if sign.x != 0:
		velocity.x = sign.x * roundi(SPEED * speed_modifier)
		facing_direction = sign.x
		if sign.x < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
		#animator.play(&"walking")
		crouching = false
	else:
		if on_floor():
			# Handle animations
			if sign.y > 0 and !crouching:
				#animator.play(&"crouch")
				crouching = true
			elif sign.y <= 0:
				crouching = false
				#if animator.current_animation != &"idle":
					#animator.play(&"idle")
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
	elif velocity.y > 0: # falling
		#animator.play(&"falling")
		# Clamp velocity so doesn't infinitely accelerate
		velocity.y = clamp(velocity.y, MIN_VELOCITY, MAX_VELOCITY) * gravity_modifier()


func rising() -> bool:
	return (velocity.y < 0 and gravity_state == Gravity.DOWN) or (velocity.y > 0 and gravity_state == Gravity.UP)


## Handles ticking timers for various physics routines; ex. coyote time and jump buffering
func tick_timers() -> void:
	if jump_buffered:
		jump_buffer_t += 1
		if jump_buffer_t == JUMP_BUFFER_FRAMES:
			jump_buffered = false
			jump_buffer_t = 0
	
	if coyote:
		coyote_t += 1
		if coyote_t == COYOTE_FRAMES:
			coyote = false
			coyote_t = 0


func jump(consumed : bool) -> bool:
	if !consumed and Input.is_action_just_pressed(&"jump") and !jumping_down and (on_floor() or coyote):
		#print_debug("is_on_floor() or coyote=%s, %s, %s" % [is_on_floor(), coyote, jumping_down])
		jumping = true
		#jump_sfx()
		velocity.y = (JUMP_VELOCITY- (velocity.y if coyote else 0)) * gravity_modifier()
		#animator.play(&"jump_up")
		return true
	return false


## Force player to start falling if they release jump; ties jump height to duration of holding input
func release_jump(consumed : bool) -> bool:
	if !consumed and Input.is_action_just_released(&"jump") and !on_floor() and rising():
		velocity.y *= 0.5
		released_jump = true
		return true
	return false


# FIXME: for some reason can buffer jump while still holding jump button from inital jump
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
			#animator.play(&"jump_up")
	return false


func on_floor() -> bool:
	return is_on_floor() if gravity_state == Gravity.DOWN else is_on_ceiling()


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
	print_debug("vel_y=%s, %s, %s" % [vel.y, transform, dir_flags])
	return dir_flags


func set_gravity(state : int) -> void:
	gravity_state = clampi(state, Gravity.DOWN, Gravity.UP)


func flip_gravity() -> void:
	gravity_state = Gravity.DOWN if gravity_state == Gravity.UP else Gravity.UP


func _on_area_entered_body(area : Area2D) -> void:
	# collectible collision layer
	if(area.collision_layer & 0b0000_0000_0000_1000) > 0:
		# TODO: handle collection
		pass


func _on_coyote_timer_timeout() -> void:
	coyote = false


func _on_jump_buffer_timer_timeout() -> void:
	jump_buffered = false
	can_buffer = false
