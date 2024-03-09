class_name GateAuxiliaryBlock extends StaticBody2D


@export var sprite : Sprite2D
@export var frame : Sprite2D


func _ready() -> void:
	sprite = $Sprite2D
	frame = $Frame


func init_color(channel : int) -> void:
	sprite.modulate = Key.COLORS[channel]
