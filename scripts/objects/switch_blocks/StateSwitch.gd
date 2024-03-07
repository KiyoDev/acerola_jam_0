class_name StateSwitch extends Area2D

@export_enum("switch_1", "switch_2", "switch_3", "switch_4") var switch_state : String = "switch_1"
@export var sprite : AnimatedSprite2D
@export var collider : CollisionShape2D
@export var animator : AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	#GameManager.get("%s_changed" % switch_state).connect(_on_state_changed)
	sprite.animation = "off"
	collision_layer = 0b0100_0000
	if !animator and $AnimationPlayer:
		animator = $AnimationPlayer


func _on_body_entered(body : Node) -> void:
	print("%s entered" % body.name)
	GameManager.flip_switch(switch_state)
	_on_state_changed(GameManager.get(switch_state))


func _on_state_changed(on : bool) -> void:
	animator.play("bump_on" if on else "bump_off")
