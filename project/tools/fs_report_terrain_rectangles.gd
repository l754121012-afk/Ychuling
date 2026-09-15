extends SceneTree

const DEFAULT_SCENE_PATH := "res://authoring/scenes/_fs_cubeize_source_clean.tscn"
const TERRAIN_GROUP_NAME := "FS_GROUP_地形"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_path := DEFAULT_SCENE_PATH
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scene="):
			scene_path = argument.trim_prefix("--scene=")
	var packed := ResourceLoader.load(scene_path) as PackedScene
	if packed == null:
		push_error("无法加载场景：%s" % scene_path)
		quit(1)
		return
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	var terrain := scene.get_node_or_null(TERRAIN_GROUP_NAME)
	if terrain == null:
		push_error("场景缺少地形分组：%s" % TERRAIN_GROUP_NAME)
		quit(1)
		return

	var groups := {}
	var kind_stats := {}
	_collect(terrain, groups, kind_stats)
	print("TERRAIN_RECTANGLE_REPORT scene=%s groups=%d" % [scene_path, groups.size()])
	var group_keys := groups.keys()
	group_keys.sort_custom(func(a, b): return int(groups[a]["count"]) > int(groups[b]["count"]))
	for key in group_keys:
		var row: Dictionary = groups[key]
		print(
			"%s count=%d kind_counts=%s bounds=(%.2f..%.2f, %.2f..%.2f) area=%.1f dims=(%.3f..%.3f, %.3f..%.3f)" % [
				key,
				int(row["count"]),
				_format_counts(row["kinds"]),
				float(row["min_x"]),
				float(row["max_x"]),
				float(row["min_z"]),
				float(row["max_z"]),
				float(row["area"]),
				float(row["min_x_size"]),
				float(row["max_x_size"]),
				float(row["min_z_size"]),
				float(row["max_z_size"]),
			]
		)
	print("TERRAIN_RECTANGLE_KINDS")
	for kind in kind_stats.keys():
		print("%s %s" % [kind, _format_counts(kind_stats[kind])])
	print("TERRAIN_RECTANGLE_REPORT_DONE")
	quit(0)


func _collect(p_node: Node, p_groups: Dictionary, p_kind_stats: Dictionary) -> void:
	if p_node is MeshInstance3D:
		var mesh_instance := p_node as MeshInstance3D
		if mesh_instance.mesh is BoxMesh:
			var box := mesh_instance.mesh as BoxMesh
			var dimensions := Vector3(
				absf(box.size.x * mesh_instance.scale.x),
				absf(box.size.y * mesh_instance.scale.y),
				absf(box.size.z * mesh_instance.scale.z)
			)
			var global_position := mesh_instance.global_position
			var kind := _kind(str(mesh_instance.name))
			var group_key := _group_key(mesh_instance)
			var row: Dictionary = p_groups.get(group_key, {
				"count": 0,
				"kinds": {},
				"min_x": INF,
				"max_x": -INF,
				"min_z": INF,
				"max_z": -INF,
				"area": 0.0,
				"min_x_size": INF,
				"max_x_size": 0.0,
				"min_z_size": INF,
				"max_z_size": 0.0,
			})
			row["count"] = int(row["count"]) + 1
			var kinds: Dictionary = row["kinds"]
			kinds[kind] = int(kinds.get(kind, 0)) + 1
			row["min_x"] = minf(float(row["min_x"]), global_position.x - dimensions.x * 0.5)
			row["max_x"] = maxf(float(row["max_x"]), global_position.x + dimensions.x * 0.5)
			row["min_z"] = minf(float(row["min_z"]), global_position.z - dimensions.z * 0.5)
			row["max_z"] = maxf(float(row["max_z"]), global_position.z + dimensions.z * 0.5)
			row["area"] = float(row["area"]) + dimensions.x * dimensions.z
			row["min_x_size"] = minf(float(row["min_x_size"]), dimensions.x)
			row["max_x_size"] = maxf(float(row["max_x_size"]), dimensions.x)
			row["min_z_size"] = minf(float(row["min_z_size"]), dimensions.z)
			row["max_z_size"] = maxf(float(row["max_z_size"]), dimensions.z)
			p_groups[group_key] = row

			var kind_row: Dictionary = p_kind_stats.get(kind, {})
			var size_key := "%.3fx%.3fx%.3f" % [dimensions.x, dimensions.y, dimensions.z]
			kind_row[size_key] = int(kind_row.get(size_key, 0)) + 1
			p_kind_stats[kind] = kind_row
	for child in p_node.get_children():
		_collect(child, p_groups, p_kind_stats)


func _group_key(p_mesh: MeshInstance3D) -> String:
	var current := p_mesh.get_parent()
	while current != null and current.name != TERRAIN_GROUP_NAME:
		if current is CollisionObject3D:
			return str(current.get_path())
		current = current.get_parent()
	return str(p_mesh.get_parent().get_path())


func _kind(p_name: String) -> String:
	var upper := p_name.to_upper()
	for prefix in [
		"FLOOR",
		"PLATFORM_DECK",
		"STAIR_STEP",
		"ROOM_FLOOR",
		"BRIDGE_DECK",
		"DECK",
		"BLOCK",
		"WATER",
		"RAIL",
		"WALL",
	]:
		if upper.begins_with(prefix):
			return prefix
	return "OTHER"


func _format_counts(p_counts: Dictionary) -> String:
	var parts: Array[String] = []
	var keys := p_counts.keys()
	keys.sort()
	for key in keys:
		parts.append("%s:%d" % [key, int(p_counts[key])])
	return ",".join(parts)
