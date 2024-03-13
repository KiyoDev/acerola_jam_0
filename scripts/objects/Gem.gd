class_name Gem extends Area2D


const COLLECT_FX := preload("res://assets/collect_fx.tscn")

@export var sprite : Sprite2D


func collect() -> void:
	sprite.hide()
	var fx : AnimatedSprite2D = COLLECT_FX.instantiate()
	add_child(fx)
	fx.animation_finished.connect(func() -> void: queue_free())
