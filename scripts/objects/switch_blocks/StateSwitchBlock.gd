class_name StateSwitchBlock extends StaticBody2D

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var collider : CollisionShape2D = $CollisionShape2D

@export_enum("switch_1", "switch_2", "switch_3", "switch_4") var switch_state : String = "switch_1"


func _ready() -> void:
	GameManager.get("%s_changed" % switch_state).connect(_on_state_changed)
	_on_state_changed(GameManager.get(switch_state))
	collider.disabled = !GameManager.get(switch_state)
	collision_layer = 0b0000_0100


func _on_state_changed(on : bool) -> void:
	sprite.animation = "on" if on else "off"
	collider.set_deferred("disabled", !on)
