class_name RealityAnchor extends StaticBody2D


@export var collision: CollisionPolygon2D
@export var sprite : Sprite2D
@export var area : Area2D


var original_shape : PackedVector2Array


func _ready() -> void:
	collision_layer = 0b0010_0000_0000
	area.area_entered.connect(_on_peeker_entered)
	area.area_exited.connect(_on_peeker_exited)
	original_shape = collision.polygon.duplicate()


func update_collision_polygon(area : Area2D) -> void:
	# create temporary arrays that take position into account
	var tmp : PackedVector2Array
	for v in original_shape:
		tmp.append(v + collision.global_position)
	
	var tmp_a : PackedVector2Array
	for a : Vector2 in area.get_child(0).polygon:
		tmp_a.append(a + area.global_position)
	
	var clipped := Geometry2D.clip_polygons(tmp, tmp_a)
	
	if clipped.size() == 0:
		collision.set_deferred("disabled", true)
		return
	
	collision.set_deferred("disabled", false)
	tmp.clear()
	# return clipped polygon back into relative values
	for c in clipped[0]:
		tmp.append(c - collision.global_position)
	
	collision.polygon = tmp
	print("final=%s" % [collision.polygon])


func _on_peeker_moved(area : Area2D) -> void:
	print("it moved")
	update_collision_polygon(area)


func _on_peeker_entered(area : Area2D) -> void:
	update_collision_polygon(area)
	area.get_parent().moved.connect(_on_peeker_moved)
	

func _on_peeker_exited(area : Area2D) -> void:
	print("exited")
	area.get_parent().moved.disconnect(_on_peeker_moved)
	collision.set_deferred("disabled", false)
	collision.polygon = original_shape
