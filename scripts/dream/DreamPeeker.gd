class_name DreamPeek extends SubViewportContainer


signal moved(area : Area2D)


@export var sub_viewport : SubViewport
@export var bg_viewport: SubViewport
@export var camera : Camera2D
@export var area : Area2D


var pos : Vector2:
	set(value):
		pos = value
		_on_position_updated()
		moved.emit(area)

var original_dream_layer : Node2D


func _ready() -> void:
	#print("%dream_layer=", get_tree().get_first_node_in_group("dream_layer"))
	var dream_layer : Node2D = get_tree().get_first_node_in_group("dream_layer")
	var dream_bg : Node = get_tree().get_first_node_in_group("dream_bg")
	# duplicate dream layer
	var dup : Node2D = dream_layer.duplicate()
	dream_layer.z_index = -1
	dup.z_index = 0
	# add dream duplicate for rendering purposes
	sub_viewport.add_child(dup)
	bg_viewport.add_child(dream_bg.duplicate(0b0111))
	dream_bg.queue_free()
	pivot_offset = size / 2


func _process(delta: float) -> void:
	if pos == global_position: return
	pos = global_position


func _on_position_updated() -> void:
	camera.global_position = pos + (size / 2)
	print("moved")
