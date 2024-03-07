class_name LockSwitch extends Area2D


@export var sprite : AnimatedSprite2D
@export var collider : CollisionShape2D


var locked : bool = true:
	set(value):
		locked = value
		sprite.animation = "locked" if locked else "unlock"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.animation = "off"


func _on_body_entered(body : Node) -> void:
	pass

