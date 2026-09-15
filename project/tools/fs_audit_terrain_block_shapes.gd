extends SceneTree

const SCENE_PATH := "res://authoring/scenes/spirit_sprawl_geometry.tscn"
const TERRAIN_GROUP_NAME := "FS_GROUP_地形"
const EPSILON := 0.0001
const BLOCK_PREFIXES := [
	"FLOOR",
	"BLOCK",
	"PLATFORM_DECK",
	"DECK",
	"STAIR_STEP",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_path := SCENE_PATH
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scene="):
			scene_path = argument.trim_prefix("--scene=")
	var packed := ResourceLoader.load(scene_path) as PackedScene
	if packed == null:
		push_error("无法加载场景：%s" % scene_path)
		quit(1)
		return
	var scene := packed.instantiate()
	if scene == null:
		push_error("场景实例化失败。")
		quit(1)
		return
	root.add_child(scene)

	var terrain := scene.get_node_or_null(TERRAIN_GROUP_NAME)
	if terrain == null:
		push_error("场景缺少分组：%s" % TERRAIN_GROUP_NAME)
		quit(1)
		return

	var stats := {}
	var samples := {}
	var centers := {}
	_collect(terrain, stats, samples, centers)
	print("CUBE_MESH_CLASS_EXISTS=%s" % ClassDB.class_exists("CubeMesh"))
	print("TERRAIN_BOX_AUDIT")
	for key in stats.keys():
		var row: Dictionary = stats[key]
		print(
			"%s total=%d block=%d cube=%d stretched=%d duplicate_centers=%d unit_mesh=%d uniform_scale=%d stretched_scale=%d min_dim=%.4f max_dim=%.4f" % [
				key,
				int(row["total"]),
				int(row["block"]),
				int(row["cube_shape"]),
				int(row["stretched"]),
				int(row["duplicate_centers"]),
				int(row["unit_mesh"]),
				int(row["uniform_scale"]),
				int(row["stretched_scale"]),
				float(row["min_dim"]),
				float(row["max_dim"]),
			]
		)
		var sample_values: Array = samples.get(key, [])
		if not sample_values.is_empty():
			print("  samples: %s" % " | ".join(sample_values))
	print("TERRAIN_BOX_AUDIT_DONE")
	quit(0)


func _collect(p_node: Node, p_stats: Dictionary, p_samples: Dictionary, p_centers: Dictionary) -> void:
	if p_node is MeshInstance3D:
		var mesh_instance := p_node as MeshInstance3D
		var mesh := mesh_instance.mesh
		if mesh is BoxMesh:
			var size := (mesh as BoxMesh).size
			var node_scale := mesh_instance.scale
			var dimensions := [
				absf(size.x * node_scale.x),
				absf(size.y * node_scale.y),
				absf(size.z * node_scale.z),
			]
			dimensions.sort()
			var min_dim := float(dimensions[0])
			var max_dim := float(dimensions[2])
			var is_unit_mesh := (
				absf(size.x - 1.0) <= EPSILON
				and absf(size.y - 1.0) <= EPSILON
				and absf(size.z - 1.0) <= EPSILON
			)
			var absolute_scale := [
				absf(node_scale.x),
				absf(node_scale.y),
				absf(node_scale.z),
			]
			absolute_scale.sort()
			var scale_is_uniform := (
				float(absolute_scale[0]) > 0.0
				and float(absolute_scale[2]) / float(absolute_scale[0]) <= 1.05
			)
			var shape_is_cube := min_dim > 0.0 and max_dim / min_dim <= 1.05
			var key := _shape_group(str(mesh_instance.name))
			var row: Dictionary = p_stats.get(key, {
				"total": 0,
				"block": 0,
				"cube_shape": 0,
				"stretched": 0,
				"duplicate_centers": 0,
				"unit_mesh": 0,
				"uniform_scale": 0,
				"stretched_scale": 0,
				"min_dim": INF,
				"max_dim": 0.0,
			})
			row["total"] = int(row["total"]) + 1
			if key != "OTHER":
				row["block"] = int(row["block"]) + 1
			if shape_is_cube:
				row["cube_shape"] = int(row["cube_shape"]) + 1
			else:
				row["stretched"] = int(row["stretched"]) + 1
			if key != "OTHER":
				var rounded_position := Vector3i(
					int(round(mesh_instance.global_position.x * 1000.0)),
					int(round(mesh_instance.global_position.y * 1000.0)),
					int(round(mesh_instance.global_position.z * 1000.0))
				)
				var center_key := "%s|%s" % [key, rounded_position]
				if p_centers.has(center_key):
					row["duplicate_centers"] = int(row["duplicate_centers"]) + 1
				else:
					p_centers[center_key] = true
			if is_unit_mesh:
				row["unit_mesh"] = int(row["unit_mesh"]) + 1
			if scale_is_uniform:
				row["uniform_scale"] = int(row["uniform_scale"]) + 1
			else:
				row["stretched_scale"] = int(row["stretched_scale"]) + 1
			row["min_dim"] = minf(float(row["min_dim"]), min_dim)
			row["max_dim"] = maxf(float(row["max_dim"]), max_dim)
			p_stats[key] = row

			var sample_values: Array = p_samples.get(key, [])
			if sample_values.size() < 6 and key != "OTHER":
				sample_values.append(
					"%s mesh=(%.2f,%.2f,%.2f) scale=(%.2f,%.2f,%.2f) effective=(%.2f,%.2f,%.2f)" % [
						str(mesh_instance.name),
						size.x,
						size.y,
						size.z,
						node_scale.x,
						node_scale.y,
						node_scale.z,
						dimensions[0],
						dimensions[1],
						dimensions[2],
					]
				)
				p_samples[key] = sample_values
	for child in p_node.get_children():
		_collect(child, p_stats, p_samples, p_centers)


func _shape_group(p_name: String) -> String:
	var upper := p_name.to_upper()
	if upper.begins_with("FLOOR"):
		return "FLOOR"
	if upper.begins_with("PLATFORM_DECK"):
		return "PLATFORM_DECK"
	if upper.begins_with("STAIR_STEP"):
		return "STAIR_STEP"
	if upper.begins_with("ROOM_FLOOR"):
		return "ROOM_FLOOR"
	if upper.begins_with("BRIDGE_DECK"):
		return "BRIDGE_DECK"
	if upper.begins_with("DECK"):
		return "DECK"
	if upper.begins_with("BLOCK"):
		return "BLOCK"
	if upper.begins_with("WATER"):
		return "WATER"
	if upper.begins_with("RAIL"):
		return "RAIL"
	if upper.begins_with("WALL"):
		return "WALL"
	if upper.begins_with("SPAWN"):
		return "SPAWN"
	return "OTHER"
