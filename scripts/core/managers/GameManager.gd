extends Node


signal restart_level
signal switch_1_changed(on : bool)
signal switch_2_changed(on : bool)
signal switch_3_changed(on : bool)
signal switch_4_changed(on : bool)


const PLAYER_SCN : PackedScene = preload("res://assets/player/player.tscn")

# "name": <path>
var levels := {
	# FIXME: change to scan folder for level scenes
}

@export var screen_transition : ColorRect
@export var transition_animator : AnimationPlayer

var player : Player
var current_level : String

var transitioning := false

# global switch states
var switch_1 : bool = false:
	set(value):
		switch_1 = value
		switch_1_changed.emit(value)
var switch_2 : bool = false:
	set(value):
		switch_2 = value
		switch_2_changed.emit(value)
var switch_3 : bool = false:
	set(value):
		switch_3 = value
		switch_3_changed.emit(value)
var switch_4 : bool = false:
	set(value):
		switch_4 = value
		switch_4_changed.emit(value)


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



func get_next_level(name : String) -> void:
	var path := "res://levels/%s.tscn" % [name]
	if !levels.has(name):
		push_error("Path['%s'] to level '%s' doesn't exist" % [path, name])
		return
	
	# set transition to be centered around player
	screen_transition.global_position = player.global_position - (screen_transition.get_rect().size / 2)
	transitioning = true
	transition_animator.play("fade_in")
	get_tree().paused = true
	await transition_animator.animation_finished
	
	# change scene while screen is faded
	get_tree().change_scene_to_file("res://levels/%s.tscn" % [name])
	await get_tree().create_timer(0.1).timeout
	current_level = name
	
	# set transition to be centered around player
	screen_transition.global_position = player.global_position - (screen_transition.get_rect().size / 2)
	transitioning = true
	transition_animator.play("fade_out")
	await transition_animator.animation_finished
	get_tree().paused = false


func flip_switch(name : String) -> void:
	set(name, !get(name))


func _on_player_death() -> void:
	get_tree().reload_current_scene()
	
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
