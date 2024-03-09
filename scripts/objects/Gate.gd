class_name Gate extends Node2D


@export_enum("1:1", "2:2", "3:3", "4:4", "5:5", "6:6", "7:7") var channel : int = 1


func _ready() -> void:
	for child in get_children():
		if child.has_method("init_color"):
			child.init_color(channel)
			if child is GateLock: 
				child.unlocked.connect(_on_unlocked)


func _on_unlocked() -> void:
	for child in get_children():
		child.queue_free()
	queue_free()
