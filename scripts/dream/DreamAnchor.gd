class_name DreamAnchor extends StaticBody2D


@export var collision: CollisionPolygon2D
@export var sprite : Sprite2D
@export var area : Area2D

var original_shape : PackedVector2Array


func _ready() -> void:
	collision_layer = 0b0001_0000_0000
	area.area_entered.connect(_on_peeker_entered)
	area.area_exited.connect(_on_peeker_exited)
	original_shape = collision.polygon.duplicate()
	print("original_shape=", original_shape)
	#collision.set_deferred("disabled", true)


func update_collision_polygon(area : Area2D) -> void:
	print("area=%s, %s" % [collision.polygon, area.global_position])
	# create temporary arrays that take position into account
	var tmp : PackedVector2Array
	for v in original_shape:
		tmp.append(v + collision.global_position)
	print("tmp=%s" % [tmp])
	
	var tmp_a : PackedVector2Array
	for a : Vector2 in area.get_child(0).polygon:
		tmp_a.append(a + area.global_position)
	print("tmp_a=%s" % [tmp_a])
	
	var intersect := Geometry2D.intersect_polygons(tmp, tmp_a)
	print("intersect=%s" % [intersect])
	if intersect.size() == 0:
		collision.set_deferred("disabled", true)
		collision.disabled = true
		collision.polygon = []
		print("f%s" % [collision.disabled])
		return
	
	collision.set_deferred("disabled", false)
	collision.disabled = false
	tmp.clear()
	# return clipped polygon back into relative values
	for c in intersect[0]:
		tmp.append(c - collision.global_position)
	
	collision.polygon = tmp
	print("final=%s, %s" % [collision.polygon, collision.disabled])


func _on_peeker_moved(area : Area2D) -> void:
	print("it movedddd")
	update_collision_polygon(area)


func _on_peeker_entered(area : Area2D) -> void:
	await get_tree().create_timer(0.01).timeout
	collision.set_deferred("disabled", false)
	update_collision_polygon(area)
	area.get_parent().get_parent().moved.connect(_on_peeker_moved)
	

func _on_peeker_exited(area : Area2D) -> void:
	print("exited")
	area.get_parent().get_parent().moved.disconnect(_on_peeker_moved)
	collision.set_deferred("disabled", true)
	collision.polygon = []
