extends SceneTree

const DEFAULT_SOURCE_PATH := "res://authoring/scenes/spirit_sprawl_geometry.tscn"
const DEFAULT_OUTPUT_PATH := "res://authoring/scenes/spirit_sprawl_geometry_cubegrid_test.tscn"
const TERRAIN_GROUP_NAME := "FS_GROUP_地形"
const EPSILON := 0.0001
const EDGE_EPSILON := 0.015
const MIN_CUBE_SIDE := 0.72
const MAX_CUBE_SIDE := 4.5
const MIN_SQUARE_SIDE := 0.12
const MAX_SQUARES_PER_COMPONENT := 80
const MAX_ROWS_PER_COMPONENT := 18
const SIZE_CACHE_PRECISION := 10000.0

var _scene: Node3D
var _mesh_cache: Dictionary = {}
var _shape_cache: Dictionary = {}
var _stats := {
	"source_meshes": 0,
	"converted_meshes": 0,
	"removed_collisions": 0,
	"cube_nodes": 0,
	"stretched_exception_nodes": 0,
	"true_cube_nodes": 0,
	"distinct_cube_sizes": {},
	"smallest_cube_side": INF,
	"largest_cube_side": 0.0,
	"floor_cubes": 0,
	"platform_cubes": 0,
	"room_floor_cubes": 0,
	"bridge_deck_cubes": 0,
	"wall_cubes": 0,
	"kept_floorlike_exceptions": 0,
	"kept_world_walls": 0,
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source_path := DEFAULT_SOURCE_PATH
	var output_path := DEFAULT_OUTPUT_PATH
	var force_convert := false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--source="):
			source_path = argument.trim_prefix("--source=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
		elif argument == "--force":
			force_convert = true

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

	var terrain := _scene.get_node_or_null(TERRAIN_GROUP_NAME)
	if terrain == null:
		push_error("场景缺少地形分组：%s" % TERRAIN_GROUP_NAME)
		quit(1)
		return

	var candidates: Array[MeshInstance3D] = []
	_collect_candidates(terrain, candidates)
	for mesh_instance in candidates:
		_convert_candidate(mesh_instance, force_convert)

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

	print(
		"FS_CUBEIZE_GEOMETRY source_meshes=%d converted=%d cube_nodes=%d true_cubes=%d distinct_cube_sizes=%d cube_side_min=%.4f cube_side_max=%.4f exceptions=%d floors=%d platforms=%d room_floors=%d bridge_decks=%d walls=%d removed_collisions=%d kept_floorlike=%d kept_world_walls=%d output=%s errors=0" % [
			int(_stats["source_meshes"]),
			int(_stats["converted_meshes"]),
			int(_stats["cube_nodes"]),
			int(_stats["true_cube_nodes"]),
			(_stats["distinct_cube_sizes"] as Dictionary).size(),
			float(_stats["smallest_cube_side"]) if is_finite(float(_stats["smallest_cube_side"])) else 0.0,
			float(_stats["largest_cube_side"]),
			int(_stats["stretched_exception_nodes"]),
			int(_stats["floor_cubes"]),
			int(_stats["platform_cubes"]),
			int(_stats["room_floor_cubes"]),
			int(_stats["bridge_deck_cubes"]),
			int(_stats["wall_cubes"]),
			int(_stats["removed_collisions"]),
			int(_stats["kept_floorlike_exceptions"]),
			int(_stats["kept_world_walls"]),
			output_path,
		]
	)
	quit(0)


func _collect_candidates(p_node: Node, p_candidates: Array[MeshInstance3D]) -> void:
	if p_node is MeshInstance3D:
		var mesh_instance := p_node as MeshInstance3D
		if mesh_instance.mesh is BoxMesh:
			var group := _component_group(str(mesh_instance.name))
			if group != "OTHER":
				p_candidates.append(mesh_instance)
	for child in p_node.get_children():
		_collect_candidates(child, p_candidates)


func _convert_candidate(p_mesh_instance: MeshInstance3D, p_force_convert: bool) -> void:
	_stats["source_meshes"] = int(_stats["source_meshes"]) + 1
	if not p_force_convert and p_mesh_instance.has_meta("fivestar_shape_kind"):
		return
	var group := _component_group(str(p_mesh_instance.name))
	if group == "BLOCK" and _is_world_wall(p_mesh_instance):
		_stats["kept_world_walls"] = int(_stats["kept_world_walls"]) + 1
		return
	if group == "STAIR_STEP":
		_stats["kept_floorlike_exceptions"] = int(_stats["kept_floorlike_exceptions"]) + 1
		return
	var old_mesh := p_mesh_instance.mesh as BoxMesh
	var dimensions := _effective_dimensions(p_mesh_instance, old_mesh)
	var material := old_mesh.material
	var parent := p_mesh_instance.get_parent()
	var source_name := str(p_mesh_instance.name)
	var base_position := p_mesh_instance.position
	var rotation := p_mesh_instance.rotation
	var orientation := p_mesh_instance.transform.basis.orthonormalized()
	var collision := _remove_sibling_collision(p_mesh_instance)
	parent.remove_child(p_mesh_instance)
	p_mesh_instance.queue_free()
	if collision != null:
		collision.get_parent().remove_child(collision)
		collision.queue_free()
		_stats["removed_collisions"] = int(_stats["removed_collisions"]) + 1

	var pieces: Array[Dictionary] = []
	match group:
		"FLOOR", "PLATFORM_DECK", "ROOM_FLOOR", "BRIDGE_DECK", "DECK":
			pieces = _square_partition(dimensions.x, dimensions.z, source_name.hash())
		"BLOCK":
			pieces = _wall_cube_chain(dimensions)
		_:
			return

	var component_group := StaticBody3D.new()
	component_group.name = "FS_COMPONENT_%s" % source_name
	component_group.position = base_position
	component_group.rotation = rotation
	component_group.set_meta("fivestar_source_component", source_name)
	if parent is CollisionObject3D:
		var source_body := parent as CollisionObject3D
		component_group.collision_layer = source_body.collision_layer
		component_group.collision_mask = source_body.collision_mask
	parent.add_child(component_group)
	component_group.owner = _scene

	for piece_index in range(pieces.size()):
		var piece: Dictionary = pieces[piece_index]
		var piece_size: Vector3 = piece["size"]
		if group in ["FLOOR", "PLATFORM_DECK", "ROOM_FLOOR", "BRIDGE_DECK", "DECK"]:
			piece_size.y = maxf(piece_size.y, dimensions.y)
		var local_offset: Vector3 = piece["offset"]
		local_offset.y += dimensions.y * 0.5 - piece_size.y * 0.5
		var piece_name := "%s_CUBE_%02d" % [source_name, piece_index]
		_add_piece(
			component_group,
			piece_name,
			local_offset,
			piece_size,
			material,
			bool(piece.get("cube", true)),
			group
		)

	_stats["converted_meshes"] = int(_stats["converted_meshes"]) + 1


func _square_partition(p_width: float, p_depth: float, p_seed: int) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	var width := maxf(absf(p_width), 0.05)
	var depth := maxf(absf(p_depth), 0.05)
	_fill_square_region(
		Vector2(-width * 0.5, -depth * 0.5),
		width,
		depth,
		pieces,
		absi(p_seed)
	)
	return pieces


func _fill_square_region(
	p_origin: Vector2,
	p_width: float,
	p_depth: float,
	p_pieces: Array[Dictionary],
	_p_seed: int
) -> void:
	if p_pieces.size() >= MAX_SQUARES_PER_COMPONENT:
		return
	var width := maxf(p_width, 0.0)
	var depth := maxf(p_depth, 0.0)
	if width < MIN_SQUARE_SIDE or depth < MIN_SQUARE_SIDE:
		return

	var square_epsilon := maxf(MIN_SQUARE_SIDE * 0.5, 0.015)
	if absf(width - depth) <= square_epsilon:
		var side := (width + depth) * 0.5
		p_pieces.append(_cube_piece_at(
			Vector3(p_origin.x + width * 0.5, 0.0, p_origin.y + depth * 0.5),
			side
		))
		return

	if width > depth:
		var count := maxi(1, int(floor((width + square_epsilon) / depth)))
		for index in range(count):
			p_pieces.append(_cube_piece_at(
				Vector3(
					p_origin.x + depth * (float(index) + 0.5),
					0.0,
					p_origin.y + depth * 0.5
				),
				depth
			))
			if p_pieces.size() >= MAX_SQUARES_PER_COMPONENT:
				return
		_fill_square_region(
			Vector2(p_origin.x + depth * float(count), p_origin.y),
			width - depth * float(count),
			depth,
			p_pieces,
			_p_seed
		)
	else:
		var count := maxi(1, int(floor((depth + square_epsilon) / width)))
		for index in range(count):
			p_pieces.append(_cube_piece_at(
				Vector3(
					p_origin.x + width * 0.5,
					0.0,
					p_origin.y + width * (float(index) + 0.5)
				),
				width
			))
			if p_pieces.size() >= MAX_SQUARES_PER_COMPONENT:
				return
		_fill_square_region(
			Vector2(p_origin.x, p_origin.y + width * float(count)),
			width,
			depth - width * float(count),
			p_pieces,
			_p_seed
		)


func _wall_cube_chain(p_dimensions: Vector3) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	var longest_axis := 0
	if p_dimensions.y > p_dimensions.x and p_dimensions.y >= p_dimensions.z:
		longest_axis = 1
	elif p_dimensions.z > p_dimensions.x:
		longest_axis = 2
	var longest := p_dimensions[longest_axis]
	var second := p_dimensions[(longest_axis + 1) % 3]
	var third := p_dimensions[(longest_axis + 2) % 3]
	if longest <= 3.0:
		var short_side := maxf(longest, 0.05)
		return [_cube_piece(0.0, 0.0, short_side)]
	var side := clampf(maxf(maxf(longest * 0.45, second), third), 1.6, MAX_CUBE_SIDE)
	var count := maxi(1, int(ceil(longest / side)))
	var segment := longest / float(count)
	for index in range(count):
		var offset := Vector3.ZERO
		var axis_offset := -longest * 0.5 + segment * (float(index) + 0.5)
		match longest_axis:
			0:
				offset.x = axis_offset
			1:
				offset.y = axis_offset
			_:
				offset.z = axis_offset
		pieces.append(_cube_piece_at(offset, side))
	return pieces


func _oriented_piece(
	p_primary: float,
	p_secondary: float,
	p_size: Vector3,
	p_x_is_primary: bool,
	p_cube_side: float,
	p_is_cube: bool
) -> Dictionary:
	var size := Vector3.ONE * p_cube_side if p_is_cube else p_size
	return {
		"offset": Vector3(p_primary, 0.0, p_secondary) if p_x_is_primary else Vector3(p_secondary, 0.0, p_primary),
		"size": size,
		"cube": p_is_cube,
	}


func _cube_piece(p_x: float, p_z: float, p_side: float) -> Dictionary:
	return _cube_piece_at(Vector3(p_x, 0.0, p_z), p_side)


func _cube_piece_at(p_offset: Vector3, p_side: float) -> Dictionary:
	return {
		"offset": p_offset,
		"size": Vector3.ONE * maxf(p_side, 0.05),
		"cube": true,
	}


func _stretched_piece(p_x: float, p_z: float, p_size_xz: Vector3, p_height := 1.0) -> Dictionary:
	return {
		"offset": Vector3(p_x, 0.0, p_z),
		"size": Vector3(
			maxf(p_size_xz.x, 0.05),
			maxf(p_height, 0.05),
			maxf(p_size_xz.z, 0.05)
		),
		"cube": false,
	}


func _add_piece(
	p_parent: Node3D,
	p_name: String,
	p_position: Vector3,
	p_size: Vector3,
	p_material: Material,
	p_is_cube: bool,
	p_group: String
) -> void:
	var actual_size := p_size
	if p_is_cube:
		var side := _quantize_size(maxf(p_size.x, 0.05))
		actual_size = Vector3.ONE * side
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = p_name
	mesh_instance.position = p_position
	mesh_instance.mesh = _mesh_for_size(p_material, actual_size)
	mesh_instance.set_meta("fivestar_shape_kind", "cube" if p_is_cube else "stretched_exception")
	p_parent.add_child(mesh_instance)
	mesh_instance.owner = _scene

	var collision := CollisionShape3D.new()
	collision.name = "%s_COLLISION" % p_name
	collision.position = p_position
	collision.shape = _shape_for_size(actual_size)
	p_parent.add_child(collision)
	collision.owner = _scene

	if p_is_cube:
		_stats["cube_nodes"] = int(_stats["cube_nodes"]) + 1
		_stats["true_cube_nodes"] = int(_stats["true_cube_nodes"]) + 1
		var side_key := int(round(actual_size.x * SIZE_CACHE_PRECISION))
		var cube_sizes: Dictionary = _stats["distinct_cube_sizes"]
		cube_sizes[side_key] = int(cube_sizes.get(side_key, 0)) + 1
		_stats["smallest_cube_side"] = minf(float(_stats["smallest_cube_side"]), actual_size.x)
		_stats["largest_cube_side"] = maxf(float(_stats["largest_cube_side"]), actual_size.x)
		if p_group == "FLOOR":
			_stats["floor_cubes"] = int(_stats["floor_cubes"]) + 1
		elif p_group == "PLATFORM_DECK":
			_stats["platform_cubes"] = int(_stats["platform_cubes"]) + 1
		elif p_group == "ROOM_FLOOR":
			_stats["room_floor_cubes"] = int(_stats["room_floor_cubes"]) + 1
		elif p_group == "BRIDGE_DECK":
			_stats["bridge_deck_cubes"] = int(_stats["bridge_deck_cubes"]) + 1
		elif p_group == "BLOCK":
			_stats["wall_cubes"] = int(_stats["wall_cubes"]) + 1
	else:
		_stats["stretched_exception_nodes"] = int(_stats["stretched_exception_nodes"]) + 1


func _remove_sibling_collision(p_mesh_instance: MeshInstance3D) -> CollisionShape3D:
	var sibling_name := "%s_COLLISION" % str(p_mesh_instance.name)
	return p_mesh_instance.get_parent().get_node_or_null(NodePath(sibling_name)) as CollisionShape3D


func _mesh_for_size(p_material: Material, p_size: Vector3) -> BoxMesh:
	var material_key := 0
	if p_material != null:
		material_key = int(p_material.get_instance_id())
	var key := "%s|%d|%d|%d" % [
		material_key,
		int(round(p_size.x * SIZE_CACHE_PRECISION)),
		int(round(p_size.y * SIZE_CACHE_PRECISION)),
		int(round(p_size.z * SIZE_CACHE_PRECISION)),
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
		int(round(p_size.x * SIZE_CACHE_PRECISION)),
		int(round(p_size.y * SIZE_CACHE_PRECISION)),
		int(round(p_size.z * SIZE_CACHE_PRECISION)),
	]
	if _shape_cache.has(key):
		return _shape_cache[key] as BoxShape3D
	var shape := BoxShape3D.new()
	shape.size = p_size
	_shape_cache[key] = shape
	return shape


func _quantize_size(p_value: float) -> float:
	return roundf(p_value * SIZE_CACHE_PRECISION) / SIZE_CACHE_PRECISION


func _effective_dimensions(p_mesh_instance: MeshInstance3D, p_mesh: BoxMesh) -> Vector3:
	return Vector3(
		absf(p_mesh.size.x * p_mesh_instance.scale.x),
		absf(p_mesh.size.y * p_mesh_instance.scale.y),
		absf(p_mesh.size.z * p_mesh_instance.scale.z)
	)


func _component_group(p_name: String) -> String:
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
	return "OTHER"


func _is_world_wall(p_mesh_instance: MeshInstance3D) -> bool:
	var current := p_mesh_instance.get_parent()
	while current != null and current != _scene:
		if str(current.name).to_upper().begins_with("WALL_WORLD"):
			return true
		current = current.get_parent()
	return false
