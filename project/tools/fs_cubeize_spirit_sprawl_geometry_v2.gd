extends SceneTree

const DEFAULT_SOURCE_PATH := "res://authoring/scenes/_fs_cubeize_source_clean.tscn"
const DEFAULT_OUTPUT_PATH := "res://authoring/scenes/spirit_sprawl_geometry_cubes_v2_test.tscn"
const TERRAIN_GROUP_NAME := "FS_GROUP_地形"
const BASE_CELL := 79.2 / 78.0
const WALL_CELL := BASE_CELL * 2.0
const MIN_COVER_RATIO := 0.18
const MAX_SQUARE_CELLS := 78
const SIZE_PRECISION := 10000.0
const EPSILON := 0.0001
const WORLD_RECT := Rect2(-120.0, -79.2, 240.0, 158.4)
const SURFACE_CELL_SIDES := [1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64, 78]

const SURFACE_KINDS := [
	"FLOOR",
	"ROOM_FLOOR",
	"BRIDGE_DECK",
	"DECK",
	"PLATFORM_DECK",
	"STAIR_STEP",
]

var _scene: Node3D
var _terrain: Node3D
var _groups: Dictionary = {}
var _out_of_bounds: Array[MeshInstance3D] = []
var _mesh_cache: Dictionary = {}
var _shape_cache: Dictionary = {}
var _stats := {
	"source_groups": 0,
	"source_surfaces": 0,
	"source_blocks": 0,
	"converted_groups": 0,
	"converted_surfaces": 0,
	"converted_blocks": 0,
	"output_pieces": 0,
	"output_surface_pieces": 0,
	"output_block_pieces": 0,
	"removed_meshes": 0,
	"removed_collisions": 0,
	"skipped_world_walls": 0,
	"skipped_water": 0,
	"skipped_rails": 0,
	"skipped_other": 0,
	"removed_out_of_bounds": 0,
	"distinct_sides": {},
	"coverage_samples": 0,
	"covered_samples": 0,
	"uncovered_samples": 0,
	"min_output_side": INF,
	"max_output_side": 0.0,
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

	_collect_groups(_terrain)
	for mesh_instance in _out_of_bounds:
		_remove_source_mesh(mesh_instance)
		_stats["removed_out_of_bounds"] = int(_stats["removed_out_of_bounds"]) + 1
	var group_keys := _groups.keys()
	group_keys.sort()
	for group_key in group_keys:
		var group: Dictionary = _groups[group_key]
		if str(group["mode"]) == "BLOCK":
			_convert_block_group(group)
		else:
			_convert_surface_group(group)

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

	var distinct_sides: Dictionary = _stats["distinct_sides"]
	var covered := int(_stats["covered_samples"])
	var samples := int(_stats["coverage_samples"])
	var coverage := 100.0 if samples == 0 else float(covered) * 100.0 / float(samples)
	print(
		"FS_CUBEIZE_V2 source_groups=%d source_surfaces=%d source_blocks=%d converted_groups=%d converted_surfaces=%d converted_blocks=%d output_pieces=%d surface_pieces=%d block_pieces=%d distinct_sides=%d min_side=%.4f max_side=%.4f coverage_samples=%d coverage=%.2f%% removed_meshes=%d removed_collisions=%d removed_out_of_bounds=%d skipped_world_walls=%d skipped_water=%d skipped_rails=%d skipped_other=%d world_x=(%.2f..%.2f) world_z=(%.2f..%.2f) output=%s errors=0" % [
			int(_stats["source_groups"]),
			int(_stats["source_surfaces"]),
			int(_stats["source_blocks"]),
			int(_stats["converted_groups"]),
			int(_stats["converted_surfaces"]),
			int(_stats["converted_blocks"]),
			int(_stats["output_pieces"]),
			int(_stats["output_surface_pieces"]),
			int(_stats["output_block_pieces"]),
			distinct_sides.size(),
			float(_stats["min_output_side"]) if is_finite(float(_stats["min_output_side"])) else 0.0,
			float(_stats["max_output_side"]),
			samples,
			coverage,
			int(_stats["removed_meshes"]),
			int(_stats["removed_collisions"]),
			int(_stats["removed_out_of_bounds"]),
			int(_stats["skipped_world_walls"]),
			int(_stats["skipped_water"]),
			int(_stats["skipped_rails"]),
			int(_stats["skipped_other"]),
			float(_stats["world_min_x"]),
			float(_stats["world_max_x"]),
			float(_stats["world_min_z"]),
			float(_stats["world_max_z"]),
			output_path,
		]
	)
	_print_side_histogram(distinct_sides)
	quit(0)


func _collect_groups(p_node: Node) -> void:
	if p_node is MeshInstance3D:
		var mesh_instance := p_node as MeshInstance3D
		if mesh_instance.mesh is BoxMesh:
			var kind := _kind(str(mesh_instance.name))
			if kind in SURFACE_KINDS or kind == "BLOCK":
				if _is_outside_world(mesh_instance):
					_out_of_bounds.append(mesh_instance)
				elif _is_world_wall(mesh_instance, kind):
					_stats["skipped_world_walls"] = int(_stats["skipped_world_walls"]) + 1
				else:
					_add_group_entry(mesh_instance, kind)
			elif kind == "WATER":
				_stats["skipped_water"] = int(_stats["skipped_water"]) + 1
			elif kind == "RAIL":
				_stats["skipped_rails"] = int(_stats["skipped_rails"]) + 1
			else:
				_stats["skipped_other"] = int(_stats["skipped_other"]) + 1
	for child in p_node.get_children():
		_collect_groups(child)


func _add_group_entry(p_mesh: MeshInstance3D, p_kind: String) -> void:
	var group_parent := _group_parent(p_mesh)
	var group_key := str(_scene.get_path_to(group_parent))
	var group: Dictionary = _groups.get(group_key, {
		"parent": group_parent,
		"entries": [],
		"kinds": {},
		"mode": "BLOCK" if p_kind == "BLOCK" else "SURFACE",
	})
	var entries: Array = group["entries"]
	var global_aabb := _global_aabb(p_mesh)
	entries.append({
		"node": p_mesh,
		"kind": p_kind,
		"aabb": global_aabb,
		"material": (p_mesh.mesh as BoxMesh).material,
	})
	var kinds: Dictionary = group["kinds"]
	kinds[p_kind] = int(kinds.get(p_kind, 0)) + 1
	_groups[group_key] = group
	if p_kind == "BLOCK":
		_stats["source_blocks"] = int(_stats["source_blocks"]) + 1
	else:
		_stats["source_surfaces"] = int(_stats["source_surfaces"]) + 1


func _convert_surface_group(p_group: Dictionary) -> void:
	_stats["source_groups"] = int(_stats["source_groups"]) + 1
	var entries: Array = p_group["entries"]
	if entries.is_empty():
		return
	var occupancy := _build_occupancy(entries)
	if occupancy.is_empty():
		return
	var pieces := _greedy_square_cover(occupancy)
	if pieces.is_empty():
		return

	var parent := p_group["parent"] as Node3D
	var material: Material = null
	var top_y := -INF
	var height := 0.0
	var representative_kind := "FLOOR"
	for entry in entries:
		var entry_material: Material = entry["material"]
		if material == null and entry_material != null:
			material = entry_material
		var aabb: AABB = entry["aabb"]
		top_y = maxf(top_y, aabb.position.y + aabb.size.y)
		height = maxf(height, aabb.size.y)
		if str(entry["kind"]) == "PLATFORM_DECK":
			representative_kind = "PLATFORM_DECK"

	for entry in entries:
		_remove_source_mesh(entry["node"] as MeshInstance3D)

	for piece_index in range(pieces.size()):
		var piece: Vector4i = pieces[piece_index]
		var cell_x := piece.x
		var cell_z := piece.y
		var side_cells := piece.z
		var side := float(side_cells) * BASE_CELL
		var world_center := Vector3(
			(float(cell_x) + float(side_cells) * 0.5) * BASE_CELL,
			top_y - height * 0.5,
			(float(cell_z) + float(side_cells) * 0.5) * BASE_CELL
		)
		_add_piece(
			parent,
			"%s_CUBE_%03d" % [representative_kind, piece_index],
			world_center,
			Vector3(side, height, side),
			material,
			"surface"
		)

	_validate_group_coverage(entries, pieces, top_y)
	_stats["converted_groups"] = int(_stats["converted_groups"]) + 1
	_stats["converted_surfaces"] = int(_stats["converted_surfaces"]) + entries.size()


func _convert_block_group(p_group: Dictionary) -> void:
	_stats["source_groups"] = int(_stats["source_groups"]) + 1
	var entries: Array = p_group["entries"]
	if entries.is_empty():
		return
	var parent := p_group["parent"] as Node3D
	for entry in entries:
		var mesh_instance := entry["node"] as MeshInstance3D
		var aabb: AABB = entry["aabb"]
		var dimensions := aabb.size.abs()
		var material: Material = entry["material"]
		var world_center := aabb.get_center()
		_remove_source_mesh(mesh_instance)
		_add_block_cubes(
			parent,
			str(mesh_instance.name),
			world_center,
			dimensions,
			material
		)
		_stats["converted_blocks"] = int(_stats["converted_blocks"]) + 1
	_stats["converted_groups"] = int(_stats["converted_groups"]) + 1


func _add_block_cubes(
	p_parent: Node3D,
	p_source_name: String,
	p_center: Vector3,
	p_dimensions: Vector3,
	p_material: Material
) -> void:
	var long_axis := 0
	var long_length := p_dimensions.x
	if p_dimensions.z > long_length:
		long_axis = 2
		long_length = p_dimensions.z
	if long_length <= WALL_CELL * 1.1:
		var side := _bounded_square_side(
			p_center,
			maxf(p_dimensions.x, p_dimensions.z),
			WALL_CELL
		)
		if side <= EPSILON:
			return
		_add_piece(
			p_parent,
			"BLOCK_CUBE_000",
			p_center,
			Vector3(side, p_dimensions.y, side),
			p_material,
			"block"
		)
		return
	var side := WALL_CELL
	var count := maxi(1, int(ceil(long_length / side)))
	var long_min := p_center.x - p_dimensions.x * 0.5 if long_axis == 0 else p_center.z - p_dimensions.z * 0.5
	var long_max := p_center.x + p_dimensions.x * 0.5 if long_axis == 0 else p_center.z + p_dimensions.z * 0.5
	var first_center := minf(long_max - side * 0.5, long_min + side * 0.5)
	var last_center := maxf(long_min + side * 0.5, long_max - side * 0.5)
	for index in range(count):
		var axis_position := first_center
		if count > 1:
			axis_position = lerpf(first_center, last_center, float(index) / float(count - 1))
		var piece_center := p_center
		if long_axis == 0:
			piece_center.x = axis_position
		else:
			piece_center.z = axis_position
		var piece_side := _bounded_square_side(piece_center, side, side)
		if piece_side <= EPSILON:
			continue
		_add_piece(
			p_parent,
			"%s_CUBE_%03d" % [p_source_name, index],
			piece_center,
			Vector3(piece_side, p_dimensions.y, piece_side),
			p_material,
			"block"
		)


func _bounded_square_side(
	p_center: Vector3,
	p_requested_side: float,
	p_max_side: float
) -> float:
	var available_x := minf(
		p_center.x - WORLD_RECT.position.x,
		WORLD_RECT.position.x + WORLD_RECT.size.x - p_center.x
	)
	var available_z := minf(
		p_center.z - WORLD_RECT.position.y,
		WORLD_RECT.position.y + WORLD_RECT.size.y - p_center.z
	)
	return minf(
		p_requested_side,
		minf(p_max_side, minf(available_x, available_z) * 2.0)
	)


func _build_occupancy(p_entries: Array) -> Dictionary:
	var occupancy := {}
	var bounds_min := Vector2(INF, INF)
	var bounds_max := Vector2(-INF, -INF)
	for entry in p_entries:
		var aabb: AABB = entry["aabb"]
		bounds_min.x = minf(bounds_min.x, aabb.position.x)
		bounds_min.y = minf(bounds_min.y, aabb.position.z)
		bounds_max.x = maxf(bounds_max.x, aabb.position.x + aabb.size.x)
		bounds_max.y = maxf(bounds_max.y, aabb.position.z + aabb.size.z)

	var min_cell_x := int(floor(bounds_min.x / BASE_CELL - EPSILON))
	var max_cell_x := int(ceil(bounds_max.x / BASE_CELL + EPSILON)) - 1
	var min_cell_z := int(floor(bounds_min.y / BASE_CELL - EPSILON))
	var max_cell_z := int(ceil(bounds_max.y / BASE_CELL + EPSILON)) - 1
	for entry in p_entries:
		var aabb: AABB = entry["aabb"]
		var rect_min_x := aabb.position.x
		var rect_max_x := aabb.position.x + aabb.size.x
		var rect_min_z := aabb.position.z
		var rect_max_z := aabb.position.z + aabb.size.z
		var entry_min_cell_x := maxi(min_cell_x, int(floor(rect_min_x / BASE_CELL - EPSILON)))
		var entry_max_cell_x := mini(max_cell_x, int(ceil(rect_max_x / BASE_CELL + EPSILON)) - 1)
		var entry_min_cell_z := maxi(min_cell_z, int(floor(rect_min_z / BASE_CELL - EPSILON)))
		var entry_max_cell_z := mini(max_cell_z, int(ceil(rect_max_z / BASE_CELL + EPSILON)) - 1)
		for cell_x in range(entry_min_cell_x, entry_max_cell_x + 1):
			var cell_min_x := float(cell_x) * BASE_CELL
			var cell_max_x := cell_min_x + BASE_CELL
			var overlap_x := maxf(0.0, minf(rect_max_x, cell_max_x) - maxf(rect_min_x, cell_min_x))
			if overlap_x <= EPSILON:
				continue
			for cell_z in range(entry_min_cell_z, entry_max_cell_z + 1):
				var cell_min_z := float(cell_z) * BASE_CELL
				var cell_max_z := cell_min_z + BASE_CELL
				var overlap_z := maxf(0.0, minf(rect_max_z, cell_max_z) - maxf(rect_min_z, cell_min_z))
				if overlap_z <= EPSILON:
					continue
				var ratio := overlap_x * overlap_z / (BASE_CELL * BASE_CELL)
				if ratio + EPSILON >= MIN_COVER_RATIO:
					occupancy[Vector2i(cell_x, cell_z)] = true
	return occupancy


func _greedy_square_cover(p_occupancy: Dictionary) -> Array[Vector4i]:
	var pieces: Array[Vector4i] = []
	var used := {}
	var keys := p_occupancy.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i):
		if a.y != b.y:
			return a.y < b.y
		return a.x < b.x
	)
	for key in keys:
		var origin: Vector2i = key
		if used.has(origin):
			continue
		var side := _largest_free_square(origin, p_occupancy, used)
		if side <= 0:
			continue
		for offset_x in range(side):
			for offset_z in range(side):
				used[Vector2i(origin.x + offset_x, origin.y + offset_z)] = true
		pieces.append(Vector4i(origin.x, origin.y, side, 0))
	return pieces


func _largest_free_square(
	p_origin: Vector2i,
	p_occupancy: Dictionary,
	p_used: Dictionary
) -> int:
	var side := 1
	while side < MAX_SQUARE_CELLS:
		var next := side + 1
		var fits := true
		for offset_x in range(next):
			for offset_z in range(next):
				var key := Vector2i(p_origin.x + offset_x, p_origin.y + offset_z)
				if not p_occupancy.has(key) or p_used.has(key):
					fits = false
					break
			if not fits:
				break
		if not fits:
			break
		side = next
	return _snap_surface_side(side)


func _snap_surface_side(p_side: int) -> int:
	var snapped := 1
	for candidate in SURFACE_CELL_SIDES:
		if int(candidate) <= p_side:
			snapped = int(candidate)
	return snapped


func _add_piece(
	p_parent: Node3D,
	p_name: String,
	p_world_center: Vector3,
	p_size: Vector3,
	p_material: Material,
	p_role: String
) -> void:
	var side := maxf(p_size.x, p_size.z)
	var center := Vector3(
		clampf(
			p_world_center.x,
			WORLD_RECT.position.x,
			WORLD_RECT.position.x + WORLD_RECT.size.x
		),
		p_world_center.y,
		clampf(
			p_world_center.z,
			WORLD_RECT.position.y,
			WORLD_RECT.position.y + WORLD_RECT.size.y
		)
	)
	var available_x := minf(
		center.x - WORLD_RECT.position.x,
		WORLD_RECT.position.x + WORLD_RECT.size.x - center.x
	)
	var available_z := minf(
		center.z - WORLD_RECT.position.y,
		WORLD_RECT.position.y + WORLD_RECT.size.y - center.z
	)
	side = minf(side, minf(available_x, available_z) * 2.0)
	if side <= EPSILON:
		return
	var output_size := Vector3(side, p_size.y, side)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = p_name
	mesh_instance.mesh = _mesh_for_size(p_material, output_size)
	mesh_instance.set_meta("fivestar_cube_role", p_role)
	mesh_instance.set_meta("fivestar_top_square", true)
	p_parent.add_child(mesh_instance)
	mesh_instance.owner = _scene
	mesh_instance.global_position = center
	mesh_instance.global_rotation = Vector3.ZERO

	var collision := CollisionShape3D.new()
	collision.name = "%s_COLLISION" % p_name
	collision.shape = _shape_for_size(output_size)
	p_parent.add_child(collision)
	collision.owner = _scene
	collision.global_position = center
	collision.global_rotation = Vector3.ZERO

	var side_key := int(round(side * SIZE_PRECISION))
	var sides: Dictionary = _stats["distinct_sides"]
	sides[side_key] = int(sides.get(side_key, 0)) + 1
	_stats["min_output_side"] = minf(float(_stats["min_output_side"]), side)
	_stats["max_output_side"] = maxf(float(_stats["max_output_side"]), side)
	_stats["output_pieces"] = int(_stats["output_pieces"]) + 1
	if p_role == "surface":
		_stats["output_surface_pieces"] = int(_stats["output_surface_pieces"]) + 1
	else:
		_stats["output_block_pieces"] = int(_stats["output_block_pieces"]) + 1
	for limit in ["x", "z"]:
		var center_value := center.x if limit == "x" else center.z
		var half_value := side * 0.5
		if limit == "x":
			_stats["world_min_x"] = minf(float(_stats["world_min_x"]), center_value - half_value)
			_stats["world_max_x"] = maxf(float(_stats["world_max_x"]), center_value + half_value)
		else:
			_stats["world_min_z"] = minf(float(_stats["world_min_z"]), center_value - half_value)
			_stats["world_max_z"] = maxf(float(_stats["world_max_z"]), center_value + half_value)


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


func _validate_group_coverage(
	p_entries: Array,
	p_pieces: Array[Vector4i],
	p_top_y: float
) -> void:
	for entry in p_entries:
		var aabb: AABB = entry["aabb"]
		for sample_x in range(5):
			for sample_z in range(5):
				var x := lerpf(aabb.position.x, aabb.position.x + aabb.size.x, (float(sample_x) + 0.5) / 5.0)
				var z := lerpf(aabb.position.z, aabb.position.z + aabb.size.z, (float(sample_z) + 0.5) / 5.0)
				_stats["coverage_samples"] = int(_stats["coverage_samples"]) + 1
				if _point_in_piece(x, z, p_pieces):
					_stats["covered_samples"] = int(_stats["covered_samples"]) + 1
				else:
					_stats["uncovered_samples"] = int(_stats["uncovered_samples"]) + 1


func _point_in_piece(p_x: float, p_z: float, p_pieces: Array[Vector4i]) -> bool:
	for raw_piece in p_pieces:
		var piece: Vector4i = raw_piece
		var side := float(piece.z) * BASE_CELL
		var min_x := float(piece.x) * BASE_CELL
		var min_z := float(piece.y) * BASE_CELL
		if (
			p_x + EPSILON >= min_x
			and p_x - EPSILON <= min_x + side
			and p_z + EPSILON >= min_z
			and p_z - EPSILON <= min_z + side
		):
			return true
	return false


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


func _group_parent(p_mesh: MeshInstance3D) -> Node3D:
	var current := p_mesh.get_parent()
	while current != null and current != _terrain:
		if current is CollisionObject3D:
			return current as Node3D
		current = current.get_parent()
	return p_mesh.get_parent() as Node3D


func _is_world_wall(p_mesh: MeshInstance3D, p_kind: String) -> bool:
	if p_kind != "BLOCK":
		return false
	var aabb := _global_aabb(p_mesh)
	if aabb.size.x > 100.0 or aabb.size.z > 100.0:
		return true
	var current: Node = p_mesh
	while current != null and current != _terrain:
		if str(current.name).to_upper().begins_with("WALL_WORLD"):
			return true
		current = current.get_parent()
	return false


func _is_outside_world(p_mesh: MeshInstance3D) -> bool:
	var aabb := _global_aabb(p_mesh)
	var min_x := aabb.position.x
	var max_x := aabb.position.x + aabb.size.x
	var min_z := aabb.position.z
	var max_z := aabb.position.z + aabb.size.z
	return (
		min_x < WORLD_RECT.position.x - EPSILON
		or max_x > WORLD_RECT.position.x + WORLD_RECT.size.x + EPSILON
		or min_z < WORLD_RECT.position.y - EPSILON
		or max_z > WORLD_RECT.position.y + WORLD_RECT.size.y + EPSILON
	)


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


func _print_side_histogram(p_sides: Dictionary) -> void:
	print("FS_CUBEIZE_V2_SIDES")
	var keys := p_sides.keys()
	keys.sort()
	for key in keys:
		print("side=%.4f count=%d" % [float(key) / SIZE_PRECISION, int(p_sides[key])])
