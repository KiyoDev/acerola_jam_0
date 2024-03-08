class_name Gate extends Node2D


func _ready() -> void:
	for child in get_children():
		if !child is GateLock: continue
		child.unlocked.connect(_on_unlocked)


func _on_unlocked() -> void:
	for child in get_children():
		child.queue_free()
	queue_free()
