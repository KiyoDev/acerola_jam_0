@tool
class_name GravityFlipArea extends Area2D


@export var collider : CollisionShape2D
@export var color_rect : ColorRect
@export var size : Vector2i:
	set(value):
		size = value
		if collider and collider.shape is RectangleShape2D:
			collider.shape.size = value
			color_rect.size = value
			color_rect.anchors_preset = Control.LayoutPreset.PRESET_CENTER
		notify_property_list_changed()


func _ready() -> void:
	body_entered.connect(_on_player_enter)
	body_exited.connect(_on_player_exit)


func _on_player_enter(body : Node) -> void:
	if body.has_method("flip_gravity"):
		body.flip_gravity()


func _on_player_exit(body : Node) -> void:
	if body.has_method("flip_gravity"):
		body.flip_gravity()
