class_name DreamPeekerHolder extends Area2D


@export var collider : CollisionShape2D
@export var point : Marker2D

var can_hold := true
var holding := false
var peeker : HeldItem


func _ready() -> void:
	body_entered.connect(_on_peeker_entered)
	body_exited.connect(_on_peeker_exited)


func _interact(player : Player) -> void:
	if holding:
		player.grab_item(peeker)
		peeker.enable_area()
		peeker = null
		holding = false
		get_tree().create_timer(2).timeout.connect(func() -> void: can_hold = true)


func _on_peeker_entered(body : Node) -> void:
	if body is HeldItem and body.get_meta("dream_peeker") and !holding and can_hold:
		can_hold = false
		holding = true
		peeker = body
		peeker.disable_area()
		peeker.pickup(point)
		print("PEEKER ENTERED=%s, %s, %s" % [peeker, peeker.collider.disabled, peeker.area.collision_layer])


func _on_peeker_exited(body : Node) -> void:
	pass
