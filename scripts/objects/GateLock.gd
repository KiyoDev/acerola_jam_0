class_name GateLock extends StaticBody2D


signal unlocked


@export var collision : CollisionPolygon2D
@export var area : Area2D
@export var sprite : Sprite2D
@export var frame : Sprite2D


var original_shape : PackedVector2Array
var channel : int = 1


func _ready() -> void:
	area.body_entered.connect(_on_key_enter)
	original_shape = collision.polygon.duplicate()


func init_color(channel : int) -> void:
	self.channel = channel
	sprite.modulate = Key.COLORS[channel]


func update_collision_polygon(area : Area2D) -> void:
	print("gate-lock area=%s, %s" % [collision.polygon, self.area.get_parent().get_parent()])
	# create temporary arrays that take position into account
	# temporary array for self polygon points
	var tmp : PackedVector2Array
	for v in original_shape:
		tmp.append(v + collision.global_position)
		
	# temporary array for peeker area points
	var tmp_a : PackedVector2Array
	for a : Vector2 in area.get_child(0).polygon:
		tmp_a.append(a + area.global_position)
	
	# check for intersects between peeker and self
	var intersect := Geometry2D.intersect_polygons(tmp, tmp_a)
	if intersect.size() == 0:
		#collision.set_deferred("disabled", true)
		collision.disabled = true
		collision.polygon = []
		return
	
	#collision.set_deferred("disabled", false)
	collision.disabled = false
	tmp.clear()
	# return clipped polygon back into relative values
	for c in intersect[0]:
		tmp.append(c - collision.global_position)
	
	collision.polygon = tmp
	

func _on_key_enter(body : Node) -> void:
	if !body is Key or !body.held or body.channel != channel: return
	body.consume()
	unlocked.emit()
