class_name StateSwitchBlock extends StaticBody2D

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var collider : CollisionShape2D = $CollisionShape2D

@export_enum("switch_1", "switch_2", "switch_3", "switch_4") var switch_state : String = "switch_1"
@export var on := false


func _ready() -> void:
	print("switch=%s" % [switch_state])
	GameManager.get(switch_state).connect(_on_state_changed)
	sprite.animation = "on" if on else "off"
	collider.set_deferred("disabled", !on)
	#_on_state_changed()
	#collider.disabled = !on
	#_on_state_changed(GameManager.get(switch_state))
	#collider.disabled = !GameManager.get(switch_state)
	collision_layer = 0b0000_0100


func _on_state_changed() -> void:
	GameManager.play_sfx("hit_block")
	on = !on
	print("%s[%s]=%s" % [name, switch_state, on])
	sprite.animation = "on" if on else "off"
	collider.set_deferred("disabled", !on)
	#if on:
		#print("on")
		#sprite.animation = "on" if on else "off"
		#collider.set_deferred("disabled", !on)
	#else:
		#print("off")
		#sprite.animation = "off" if on else "on"
		#collider.set_deferred("disabled", on)
