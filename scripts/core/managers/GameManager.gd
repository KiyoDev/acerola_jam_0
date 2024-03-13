extends Node

signal transitioned_in
signal transitioned_out
signal finished_transition

signal level_loaded
signal level_reloaded

signal switch_1
signal switch_2
signal switch_3
signal switch_4

signal player_jumped

const PLAYER_SCN : PackedScene = preload("res://assets/player/player.tscn")
const DOOR_CUTOUT : Texture2D = preload("res://assets/art/door_white.png")
const SLIME_CUTOUT : Texture2D = preload("res://assets/art/slime_cutout.png")

# "name": <path>
var levels := {
	# FIXME: change to scan folder for level scenes
}

@export var screen_transition : ColorRect
@export var transition_animator : AnimationPlayer
@export var floor_label : Label
@export var gem_label : Label

var gems := 0:
	set(value):
		gems = value
		gem_label.text = "x%d" % gems
var player : Player:
	set(value):
		player = value
var current_level : Level
var current_level_name : String

var transitioning := false
var reloading_level := false
var gem_collected := false

# global switch states
#var switch_1 : bool = false:
	#set(value):
		#switch_1 = value
		#switch_1_changed.emit(value)
#var switch_2 : bool = false:
	#set(value):
		#switch_2 = value
		#switch_2_changed.emit(value)
#var switch_3 : bool = false:
	#set(value):
		#switch_3 = value
		#switch_3_changed.emit(value)
#var switch_4 : bool = false:
	#set(value):
		#switch_4 = value
		#switch_4_changed.emit(value)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_physics_process(false)
	var window : Window = get_tree().root
	var os : String = OS.get_name()
	var size : Vector2i = Vector2(2560, 1440) if os == "macOS" else Vector2(1280, 720)
	window.size = size
	
	# center the window
	var screen : Vector2i = DisplayServer.screen_get_size()
	window.position = (screen / 2) - window.size / 2
	
	add_child(screen_transition)
	
	print("current_scene=%s" % get_tree().current_scene)
	get_levels()
	print("levels=%s" % [levels])
	reloading_level = false
	gem_label.text = "x%d" % gems
	

func load_player() -> void:
	if player != null:
		player.queue_free()
		player = null
	player = PLAYER_SCN.instantiate()
	player.death.connect(_on_player_death)
	player.collected_gem.connect(_on_gem_collected)
	add_child(player)


func register_level(level : Level) -> void:
	if current_level != level:
		current_level = level
		current_level.loaded.connect(_on_level_loaded)
		load_player()
		player.reparent(level)
		player.global_position = level.spawn_point.global_position
		transition_in(SLIME_CUTOUT if reloading_level else DOOR_CUTOUT)
		reloading_level = false
		floor_label.text = "%d" % current_level.floor


func get_next_level(name : String) -> void:
	var path := "res://levels/%s.tscn" % [name]
	if !levels.has(name):
		push_error("Path['%s'] to level '%s' doesn't exist" % [path, name])
		return
	
	await transition_out(DOOR_CUTOUT)
	
	# change scene while screen is faded
	get_tree().change_scene_to_file("res://levels/%s.tscn" % [name])
	current_level_name = name
	gem_collected = false


func transition_in(texture : Texture2D = null) -> void:
	if texture:
		screen_transition.material.set_shader_parameter("mask", texture)
	# set transition to be centered around player
	screen_transition.global_position = player.global_position - (screen_transition.get_rect().size / 2)
	transitioning = true
	transition_animator.play("fade_out")
	await transition_animator.animation_finished
	transitioned_in.emit()


func transition_out(texture : Texture2D = null) -> void:
	if texture:
		screen_transition.material.set_shader_parameter("mask", texture)
	# set transition to be centered around player
	screen_transition.global_position = player.global_position - (screen_transition.get_rect().size / 2)
	transitioning = true
	transition_animator.play("fade_in")
	await transition_animator.animation_finished
	transitioned_out.emit()


func reload_level() -> void:
	await transition_out(SLIME_CUTOUT)
	if gem_collected:
		gems -= 1
	gem_collected = false
	
	get_tree().reload_current_scene()
	reloading_level = true
	await get_tree().create_timer(0.1).timeout
	


func _on_player_death(player : Player) -> void:
	reload_level()


func _on_level_loaded() -> void:
	level_loaded.emit()


func _on_gem_collected() -> void:
	gems += 1
	gem_collected = true

#--------------------------------------
# Search directory for all levels
#--------------------------------------

func get_levels() -> void:
	search_dir("res://levels")
	
	
func search_dir(dir_path : String) -> void:
	var dir := DirAccess.open(dir_path)
	dir.list_dir_begin()
	
	var next := dir.get_next()
	#print_debug("next='%s', %s" % [next, dir.current_is_dir()])
	
	if next.is_empty(): return
	
	while !next.is_empty():
		# ignore files beginning with '.'
		if next.begins_with("."):
			next = dir.get_next()
		# next is directory, search directory for valid files
		elif dir.current_is_dir():
			#print_debug("'%s' is dir" % [next])
			search_dir(dir_path + "/" + next)
			next = dir.get_next()
		# leaf file
		else:
			# not a resource, go next
			if !next.ends_with(".tscn"):
				next = dir.get_next()
				continue
			var scn : PackedScene = load(dir_path + "/" + next)
			var node : Node = scn.instantiate()
			if !node is Level: 
				push_warning("Scene '%s' is not a Level...")
				next = dir.get_next()
				continue
			levels[next.trim_suffix(".tscn")] = dir_path + "/" + next
			next = dir.get_next()
