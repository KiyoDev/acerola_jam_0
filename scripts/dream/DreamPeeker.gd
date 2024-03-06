class_name DreamPeek extends SubViewportContainer


signal moved(area : Area2D)


@export var sub_viewport : SubViewport
@export var bg_viewport: SubViewport
@export var camera : Camera2D
@export var area : Area2D
@export var sub_area : Area2D


var pos : Vector2:
	set(value):
		pos = value
		_on_position_updated()
		moved.emit(area)


func _ready() -> void:
	#print("%dream_layer=", get_tree().get_first_node_in_group("dream_layer"))
	var dream_layer : Node2D = get_tree().get_first_node_in_group("dream_layer")
	var dream_bg : Node = get_tree().get_first_node_in_group("dream_bg")
	#print(dream_layer)
	var dup : Node2D = dream_layer.duplicate(0b0111)
	dream_layer.z_index = -1
	dup.z_index = 0
	#dup.global_position = dream_layer.global_position
	sub_viewport.add_child(dup)
	bg_viewport.add_child(dream_bg.duplicate(0b0111))
	#print(sub_viewport.get_children())
	#dream_layer.queue_free()
	dream_bg.queue_free()
	pivot_offset = size / 2
	#moved.connect(_on_position_updated)
	#area.body_entered.connect(_on_anchor_entered)


func _process(delta: float) -> void:
	if pos == global_position: return
	pos = global_position


func _on_position_updated() -> void:
	camera.global_position = pos + (size / 2)
	sub_area.global_position = pos + (size / 2)
	print("moved")


#func _on_anchor_entered(body : Node) -> void:
	#body.update_collision_polygon(area)
#
#
#func _on_anchor_exited(body : Node) -> void:
	#body.update_collision_polygon(area)
