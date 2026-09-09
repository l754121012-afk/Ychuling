class_name V2Breakable
extends StaticBody3D

@export var breakable_id := ""


func _ready() -> void:
	if get_child_count() == 0:
		var shape := SphereShape3D.new()
		shape.radius = 0.55
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position.y = 0.55
		add_child(collision)
	_build_visible_jar()


# 可击破物目前只有碰撞球、没有可见网格，玩家在场景里看不见罐子。这里补一个占位罐体，
# 让“可击破罐”成为可读的实体（颜色/形状后续可直接换美术，不影响判定）。
func _build_visible_jar() -> void:
	if get_node_or_null("JarBody") != null:
		return
	var body := PlaceholderKit.box("JarBody", Color("#b08d5f"), Vector3(0.62, 0.78, 0.62))
	body.position.y = 0.42
	add_child(body)
	var rim := PlaceholderKit.box("JarRim", Color("#c9a05e"), Vector3(0.42, 0.26, 0.42))
	rim.position.y = 0.96
	rim.material_override = PlaceholderKit.emissive_material(Color("#c9a05e"), 1.0)
	add_child(rim)


func on_cleaned(_p_by: Node, _p_is_sweep: bool = false, _p_damage: int = 1) -> void:
	_break_apart()


func _break_apart() -> void:
	if not is_inside_tree():
		return
	var parent := get_parent()
	for index in range(4):
		var fragment := PlaceholderKit.box("art_key_v2_breakable_fragment_%s_%d" % [breakable_id, index], Color("#9a8368"), Vector3(0.2, 0.2, 0.2))
		parent.add_child(fragment)
		fragment.global_position = global_position + Vector3(0.0, 0.8, 0.0)
		var direction := Vector3(randf_range(-1.0, 1.0), randf_range(0.3, 1.0), randf_range(-1.0, 1.0)).normalized()
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(fragment, "global_position", fragment.global_position + direction * 2.0, 0.35)
		tween.tween_property(fragment, "rotation_degrees", Vector3(randf_range(120.0, 300.0), randf_range(120.0, 300.0), randf_range(120.0, 300.0)), 0.35)
		tween.chain().tween_callback(fragment.queue_free)
	queue_free()
