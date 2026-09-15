extends SceneTree

const DEFAULT_SOURCE_PATH := "res://authoring/scenes/_fs_cubeize_source_clean.tscn"
const DEFAULT_OUTPUT_PATH := "res://authoring/scenes/spirit_sprawl_geometry_cubes_v3_test.tscn"
const TERRAIN_GROUP_NAME := "FS_GROUP_地形"
const EPSILON := 0.0001
const SIZE_PRECISION := 10000.0
const NEAR_SQUARE_RATIO := 1.05

const CONVERT_KINDS := [
	"FLOOR",
	"ROOM_FLOOR",
	"PLATFORM_DECK",
]

const PRESERVE_KINDS := [
	"BRIDGE_DECK",
	"DECK",
	"STAIR_STEP",
	"BLOCK",
	"RAIL",
	"WATER",
]

var _scene: Node3D
var _terrain: Node3D
var _mesh_cache: Dictionary = {}
var _shape_cache: Dictionary = {}
var _piece_counters: Dictionary = {}
var _stats := {
	"source_candidates": 0,
	"converted_sources": 0,
	"output_tiles": 0,
	"output_tiles_by_kind": {},
	"preserved_by_kind": {},
	"skipped_other": 0,
	"removed_meshes": 0,
	"removed_collisions": 0,
	"distinct_tile_sides": {},
	"max_footprint_error_x": 0.0,
	"max_footprint_error_z": 0.0,
	"max_centerline_error_x": 0.0,
	"max_centerline_error_z": 0.0,
	"world_min_x": INF,
	"world_max_x": -INF,
	"world_min_z": INF,
	"world_max_z": -INF,
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source_path := DEFAULT_SOURCE_PATH
	var output_path := DEFAULT_OUTPUT_PATH
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--source="):
			source_path = argument.trim_prefix("--source=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")

	var packed := ResourceLoader.load(source_path) as PackedScene
	if packed == null:
		push_error("无法加载源场景：%s" % source_path)
		quit(1)
		return
	_scene = packed.instantiate() as Node3D
	if _scene == null:
		push_error("源场景根节点不是 Node3D：%s" % source_path)
		quit(1)
		return
	root.add_child(_scene)
	_terrain = _scene.get_node_or_null(TERRAIN_GROUP_NAME) as Node3D
	if _terrain == null:
		push_error("场景缺少地形分组：%s" % TERRAIN_GROUP_NAME)
		quit(1)
		return

	var candidates: Array[MeshInstance3D] = []
	_collect_candidates(_terrain, candidates)
	for candidate in candidates:
		_convert_candidate(candidate)

	var repacked := PackedScene.new()
	var pack_error := repacked.pack(_scene)
	if pack_error != OK:
		push_error("场景打包失败：%s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(repacked, output_path)
	if save_error != OK:
		push_error("场景保存失败：%s (%s)" % [error_string(save_error), output_path])
		quit(1)
		return

	_print_stats(source_path, output_path)
	quit(0)


func _collect_candidates(p_node: Node, p_candidates: Array[MeshInstance3D]) -> void:
	if p_node is MeshInstance3D:
		var mesh_instance := p_node as MeshInstance3D
		if mesh_instance.mesh is BoxMesh:
			var kind := _kind(str(mesh_instance.name))
			if kind in CONVERT_KINDS:
				p_candidates.append(mesh_instance)
			elif kind in PRESERVE_KINDS:
				_increment_dictionary(_stats["preserved_by_kind"], kind)
			else:
				_stats["skipped_other"] = int(_stats["skipped_other"]) + 1
	for child in p_node.get_children():
		_collect_candidates(child, p_candidates)


func _convert_candidate(p_source_mesh: MeshInstance3D) -> void:
	if not is_instance_valid(p_source_mesh):
		return
	var kind := _kind(str(p_source_mesh.name))
	var source_aabb := _global_aabb(p_source_mesh)
	var dimensions := source_aabb.size.abs()
	var short_side := minf(dimensions.x, dimensions.z)
	var long_side := maxf(dimensions.x, dimensions.z)
	if short_side <= EPSILON or long_side <= EPSILON:
		push_warning("跳过无有效顶视面积的地块：%s" % p_source_mesh.name)
		return

	var is_near_square := long_side / short_side <= NEAR_SQUARE_RATIO
	var tile_side := short_side
	var count := maxi(1, int(ceil(long_side / short_side - EPSILON)))
	if is_near_square:
		tile_side = long_side
		count = 1
	var axis_is_x := dimensions.x >= dimensions.z
	var source_center := source_aabb.get_center()
	var top_y := source_aabb.position.y + source_aabb.size.y
	var height := dimensions.y
	var material: Material = (p_source_mesh.mesh as BoxMesh).material
	var parent := p_source_mesh.get_parent() as Node3D
	var source_name := str(p_source_mesh.name)
	var tile_size := Vector3(tile_side, height, tile_side)
	var first_center := 0.0
	var last_center := 0.0
	if axis_is_x:
		first_center = source_aabb.position.x + tile_side * 0.5
		last_center = source_aabb.position.x + source_aabb.size.x - tile_side * 0.5
	else:
		first_center = source_aabb.position.z + tile_side * 0.5
		last_center = source_aabb.position.z + source_aabb.size.z - tile_side * 0.5

	var tile_centers: Array[Vector3] = []
	for index in range(count):
		var center := source_center
		center.y = top_y - height * 0.5
		var axis_position := first_center
		if count > 1:
			axis_position = lerpf(first_center, last_center, float(index) / float(count - 1))
		if axis_is_x:
			center.x = axis_position
		else:
			center.z = axis_position
		tile_centers.append(center)

	_remove_source_mesh(p_source_mesh)
	for center in tile_centers:
		var tile_name := "%s_CUBE_%04d" % [
			kind,
			_next_piece_index(parent, kind),
		]
		_add_tile(parent, tile_name, kind, source_name, center, tile_size, material)

	_validate_source_footprint(
		source_aabb,
		tile_centers,
		tile_size,
		source_center,
		axis_is_x
	)
	_stats["source_candidates"] = int(_stats["source_candidates"]) + 1
	_stats["converted_sources"] = int(_stats["converted_sources"]) + 1
	_increment_dictionary(_stats["output_tiles_by_kind"], kind, count)
	var side_key := int(round(tile_side * SIZE_PRECISION))
	_increment_dictionary(_stats["distinct_tile_sides"], side_key, count)


func _add_tile(
	p_parent: Node3D,
	p_name: String,
	p_kind: String,
	p_source_name: String,
	p_world_center: Vector3,
	p_size: Vector3,
	p_material: Material
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = p_name
	mesh_instance.mesh = _mesh_for_size(p_material, p_size)
	mesh_instance.set_meta("fivestar_cube_role", "base_platform")
	mesh_instance.set_meta("fivestar_top_square", true)
	mesh_instance.set_meta("fivestar_cube_source_kind", p_kind)
	mesh_instance.set_meta("fivestar_cube_source_name", p_source_name)
	p_parent.add_child(mesh_instance)
	mesh_instance.owner = _scene
	mesh_instance.global_transform = Transform3D(Basis.IDENTITY, p_world_center)

	var collision := CollisionShape3D.new()
	collision.name = "%s_COLLISION" % p_name
	collision.shape = _shape_for_size(p_size)
	p_parent.add_child(collision)
	collision.owner = _scene
	collision.global_transform = Transform3D(Basis.IDENTITY, p_world_center)

	_stats["output_tiles"] = int(_stats["output_tiles"]) + 1
	_stats["world_min_x"] = minf(float(_stats["world_min_x"]), p_world_center.x - p_size.x * 0.5)
	_stats["world_max_x"] = maxf(float(_stats["world_max_x"]), p_world_center.x + p_size.x * 0.5)
	_stats["world_min_z"] = minf(float(_stats["world_min_z"]), p_world_center.z - p_size.z * 0.5)
	_stats["world_max_z"] = maxf(float(_stats["world_max_z"]), p_world_center.z + p_size.z * 0.5)


func _validate_source_footprint(
	p_source_aabb: AABB,
	p_tile_centers: Array[Vector3],
	p_tile_size: Vector3,
	p_source_center: Vector3,
	p_axis_is_x: bool
) -> void:
	var output_min_x := INF
	var output_max_x := -INF
	var output_min_z := INF
	var output_max_z := -INF
	for center in p_tile_centers:
		output_min_x = minf(output_min_x, center.x - p_tile_size.x * 0.5)
		output_max_x = maxf(output_max_x, center.x + p_tile_size.x * 0.5)
		output_min_z = minf(output_min_z, center.z - p_tile_size.z * 0.5)
		output_max_z = maxf(output_max_z, center.z + p_tile_size.z * 0.5)
	var source_min_x := p_source_aabb.position.x
	var source_max_x := p_source_aabb.position.x + p_source_aabb.size.x
	var source_min_z := p_source_aabb.position.z
	var source_max_z := p_source_aabb.position.z + p_source_aabb.size.z
	_stats["max_footprint_error_x"] = maxf(
		float(_stats["max_footprint_error_x"]),
		maxf(absf(output_min_x - source_min_x), absf(output_max_x - source_max_x))
	)
	_stats["max_footprint_error_z"] = maxf(
		float(_stats["max_footprint_error_z"]),
		maxf(absf(output_min_z - source_min_z), absf(output_max_z - source_max_z))
	)
	var output_center := Vector3(
		(output_min_x + output_max_x) * 0.5,
		p_source_center.y,
		(output_min_z + output_max_z) * 0.5
	)
	_stats["max_centerline_error_x"] = maxf(
		float(_stats["max_centerline_error_x"]),
		absf(output_center.x - p_source_center.x)
	)
	_stats["max_centerline_error_z"] = maxf(
		float(_stats["max_centerline_error_z"]),
		absf(output_center.z - p_source_center.z)
	)


func _remove_source_mesh(p_mesh: MeshInstance3D) -> void:
	var parent := p_mesh.get_parent()
	var collision := parent.get_node_or_null(NodePath("%s_COLLISION" % str(p_mesh.name))) as CollisionShape3D
	if collision != null:
		collision.get_parent().remove_child(collision)
		collision.queue_free()
		_stats["removed_collisions"] = int(_stats["removed_collisions"]) + 1
	parent.remove_child(p_mesh)
	p_mesh.queue_free()
	_stats["removed_meshes"] = int(_stats["removed_meshes"]) + 1


func _next_piece_index(p_parent: Node3D, p_kind: String) -> int:
	var key := "%s|%s" % [str(p_parent.get_path()), p_kind]
	var index := int(_piece_counters.get(key, 0))
	_piece_counters[key] = index + 1
	return index


func _mesh_for_size(p_material: Material, p_size: Vector3) -> BoxMesh:
	var material_key := 0
	if p_material != null:
		material_key = int(p_material.get_instance_id())
	var key := "%d|%d|%d|%d" % [
		material_key,
		int(round(p_size.x * SIZE_PRECISION)),
		int(round(p_size.y * SIZE_PRECISION)),
		int(round(p_size.z * SIZE_PRECISION)),
	]
	if _mesh_cache.has(key):
		return _mesh_cache[key] as BoxMesh
	var mesh := BoxMesh.new()
	mesh.size = p_size
	mesh.material = p_material
	_mesh_cache[key] = mesh
	return mesh


func _shape_for_size(p_size: Vector3) -> BoxShape3D:
	var key := "%d|%d|%d" % [
		int(round(p_size.x * SIZE_PRECISION)),
		int(round(p_size.y * SIZE_PRECISION)),
		int(round(p_size.z * SIZE_PRECISION)),
	]
	if _shape_cache.has(key):
		return _shape_cache[key] as BoxShape3D
	var shape := BoxShape3D.new()
	shape.size = p_size
	_shape_cache[key] = shape
	return shape


func _global_aabb(p_mesh: MeshInstance3D) -> AABB:
	return p_mesh.global_transform * p_mesh.get_aabb()


func _kind(p_name: String) -> String:
	var upper := p_name.to_upper()
	for prefix in [
		"PLATFORM_DECK",
		"STAIR_STEP",
		"ROOM_FLOOR",
		"BRIDGE_DECK",
		"FLOOR",
		"DECK",
		"BLOCK",
		"WATER",
		"RAIL",
	]:
		if upper.begins_with(prefix):
			return prefix
	return "OTHER"


func _increment_dictionary(p_dictionary: Dictionary, p_key: Variant, p_amount: int = 1) -> void:
	p_dictionary[p_key] = int(p_dictionary.get(p_key, 0)) + p_amount


func _print_stats(p_source_path: String, p_output_path: String) -> void:
	var size_keys: Array = _stats["distinct_tile_sides"].keys()
	size_keys.sort()
	var sizes: Array[String] = []
	for key in size_keys:
		sizes.append("%.4f:%d" % [float(key) / SIZE_PRECISION, int(_stats["distinct_tile_sides"][key])])
	print(
		"FS_CUBEIZE_V3 source=%s converted_sources=%d output_tiles=%d preserved=%d skipped_other=%d removed_meshes=%d removed_collisions=%d max_footprint_error_x=%.6f max_footprint_error_z=%.6f max_centerline_error_x=%.6f max_centerline_error_z=%.6f output=%s errors=0" % [
			p_source_path,
			int(_stats["converted_sources"]),
			int(_stats["output_tiles"]),
			_dictionary_total(_stats["preserved_by_kind"]),
			int(_stats["skipped_other"]),
			int(_stats["removed_meshes"]),
			int(_stats["removed_collisions"]),
			float(_stats["max_footprint_error_x"]),
			float(_stats["max_footprint_error_z"]),
			float(_stats["max_centerline_error_x"]),
			float(_stats["max_centerline_error_z"]),
			p_output_path,
		]
	)
	print("FS_CUBEIZE_V3_TILES_BY_KIND %s" % _format_counts(_stats["output_tiles_by_kind"]))
	print("FS_CUBEIZE_V3_PRESERVED_BY_KIND %s" % _format_counts(_stats["preserved_by_kind"]))
	print("FS_CUBEIZE_V3_TILE_SIDES %s" % ", ".join(sizes))
	print(
		"FS_CUBEIZE_V3_WORLD x=(%.2f..%.2f) z=(%.2f..%.2f)" % [
			float(_stats["world_min_x"]),
			float(_stats["world_max_x"]),
			float(_stats["world_min_z"]),
			float(_stats["world_max_z"]),
		]
	)


func _dictionary_total(p_dictionary: Dictionary) -> int:
	var total := 0
	for value in p_dictionary.values():
		total += int(value)
	return total


func _format_counts(p_dictionary: Dictionary) -> String:
	var parts: Array[String] = []
	var keys := p_dictionary.keys()
	keys.sort()
	for key in keys:
		parts.append("%s:%d" % [key, int(p_dictionary[key])])
	return ", ".join(parts)
