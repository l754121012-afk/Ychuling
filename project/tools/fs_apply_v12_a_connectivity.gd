extends SceneTree

const DATA_PATH := "res://authoring/data/spirit_sprawl_v12_a_connectivity.json"
const SCENE_PATH := "res://authoring/scenes/spirit_sprawl_geometry.tscn"
const SURFACE_PATH := "FS_GROUP_地形/FS_ZONE_北中分叉陆区_NORTH_KNOT/SURFACE_NORTH_KNOT"
const CONNECTIVITY_GROUP_NAME := "FS_GROUP_连通修正"

const EXPECTED_ROOMS := 180
const EXPECTED_EDGES := 179
const EXPECTED_CELLS := 1125
const EXPECTED_SOURCE_COMPONENTS := 29
const EXPECTED_LEGACY_CLEAR_CELLS := 2608
const EXPECTED_COUNTS := {
	"bridge": 108,
	"jump": 54,
	"dash": 15,
	"special": 2,
}

const BRIDGE_WIDTH := 0.78
const BRIDGE_HEIGHT := 0.14
const SPECIAL_STEP_SIZE := 1.08
const SPECIAL_STEP_HEIGHT := 0.20
const SPECIAL_STEP_SPACING := 5.60
const LEGACY_CLEAR_TOP_MAX := 0.65
const GRID_EPSILON := 0.002


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var data := _load_json(DATA_PATH)
	if data.is_empty():
		quit(1)
		return
	var validation_error := _validate_data(data)
	if not validation_error.is_empty():
		push_error("v12-A 数据校验失败：%s" % validation_error)
		quit(1)
		return

	var packed := ResourceLoader.load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("无法加载正式场景：%s" % SCENE_PATH)
		quit(1)
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		push_error("正式场景根节点必须是 Node3D：%s" % SCENE_PATH)
		quit(1)
		return
	root.add_child(scene)

	var surface := scene.get_node_or_null(SURFACE_PATH) as StaticBody3D
	if surface == null:
		push_error("找不到北中分叉地表组件父节点：%s" % SURFACE_PATH)
		quit(1)
		return

	var components := _component_nodes_by_source(surface)
	if components.size() != EXPECTED_SOURCE_COMPONENTS:
		push_error(
			"北中分叉组件数量不匹配：actual=%d expected=%d"
			% [components.size(), EXPECTED_SOURCE_COMPONENTS]
		)
		quit(1)
		return

	var legacy_cleared := _clear_overlapping_legacy_floor(scene, surface, data)
	var material := _capture_material(components)
	var cell_mesh := BoxMesh.new()
	cell_mesh.size = Vector3(
		float(data.get("cell_edge_x", 1.523075103759765)),
		float(data.get("floor_thickness", 0.6)),
		float(data.get("cell_edge_z", 1.523075103759765))
	)
	cell_mesh.material = material
	var cell_shape := BoxShape3D.new()
	cell_shape.size = cell_mesh.size

	var rebuilt_cells := _rebuild_cells(
		scene,
		components,
		data.get("cells", []),
		cell_mesh,
		cell_shape,
		float(data.get("floor_thickness", 0.6))
	)
	if rebuilt_cells != EXPECTED_CELLS:
		push_error("重建地块数量不匹配：actual=%d expected=%d" % [rebuilt_cells, EXPECTED_CELLS])
		quit(1)
		return

	var existing_group := scene.get_node_or_null(CONNECTIVITY_GROUP_NAME)
	if existing_group != null:
		scene.remove_child(existing_group)
		existing_group.free()
	var connectivity_group := Node3D.new()
	connectivity_group.name = CONNECTIVITY_GROUP_NAME
	scene.add_child(connectivity_group)
	_assign_owner_recursive(connectivity_group, scene)

	var edge_counts := _add_connectivity_geometry(
		connectivity_group,
		scene,
		data.get("edges", []),
		material
	)
	for method in EXPECTED_COUNTS:
		if int(edge_counts.get(method, 0)) != int(EXPECTED_COUNTS[method]):
			push_error(
				"连接方式数量不匹配：method=%s actual=%d expected=%d"
				% [method, int(edge_counts.get(method, 0)), int(EXPECTED_COUNTS[method])]
			)
			quit(1)
			return

	var stats := _build_stats(data, rebuilt_cells, edge_counts, legacy_cleared)
	_apply_connectivity_metadata(scene, surface, stats)
	_assign_owner_recursive(connectivity_group, scene)

	var output := PackedScene.new()
	var pack_error := output.pack(scene)
	if pack_error != OK:
		push_error("正式场景打包失败：%s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(output, SCENE_PATH)
	if save_error != OK:
		push_error("正式场景保存失败：%s" % error_string(save_error))
		quit(1)
		return

	print(
		"FS_APPLY_V12_A_CONNECTIVITY path=%s cells=%d legacy_cleared=%d rooms=%d edges=%d bridge=%d jump=%d dash=%d special=%d components=%d errors=0"
		% [
			SCENE_PATH,
			rebuilt_cells,
			legacy_cleared,
			int(stats.get("room_count", 0)),
			int(stats.get("edge_count", 0)),
			int(edge_counts.get("bridge", 0)),
			int(edge_counts.get("jump", 0)),
			int(edge_counts.get("dash", 0)),
			int(edge_counts.get("special", 0)),
			int(stats.get("connected_component_count", 0)),
		]
	)
	scene.queue_free()
	quit(0)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("找不到 v12-A 数据：%s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not parsed is Dictionary:
		push_error("v12-A 数据 JSON 无效：%s" % path)
		return {}
	return parsed as Dictionary


func _validate_data(data: Dictionary) -> String:
	var cells: Array = data.get("cells", [])
	var rooms: Array = data.get("rooms", [])
	var edges: Array = data.get("edges", [])
	if cells.size() != EXPECTED_CELLS:
		return "cells=%d expected=%d" % [cells.size(), EXPECTED_CELLS]
	if rooms.size() != EXPECTED_ROOMS:
		return "rooms=%d expected=%d" % [rooms.size(), EXPECTED_ROOMS]
	if edges.size() != EXPECTED_EDGES:
		return "edges=%d expected=%d" % [edges.size(), EXPECTED_EDGES]
	var source_components: Array = data.get("source_components", [])
	if source_components.size() != EXPECTED_SOURCE_COMPONENTS:
		return "source_components=%d expected=%d" % [source_components.size(), EXPECTED_SOURCE_COMPONENTS]
	var legacy_clear_cells: Array = data.get("legacy_clear_cells", [])
	if legacy_clear_cells.size() != EXPECTED_LEGACY_CLEAR_CELLS:
		return "legacy_clear_cells=%d expected=%d" % [legacy_clear_cells.size(), EXPECTED_LEGACY_CLEAR_CELLS]
	var counts := _count_edges(edges)
	for method in EXPECTED_COUNTS:
		if int(counts.get(method, 0)) != int(EXPECTED_COUNTS[method]):
			return "method=%s actual=%d expected=%d" % [
				method,
				int(counts.get(method, 0)),
				int(EXPECTED_COUNTS[method]),
			]
	if _connected_component_count(rooms, edges) != 1:
		return "rooms are not connected by the declared edge set"
	return ""


func _component_nodes_by_source(surface: Node) -> Dictionary:
	var result := {}
	for child in surface.get_children():
		var source := str(child.get_meta("fivestar_source_component", ""))
		if source.is_empty():
			continue
		result[source] = child
	return result


func _capture_material(components: Dictionary) -> Material:
	for key in components:
		var component := components[key] as Node
		for child in component.get_children():
			if child is MeshInstance3D:
				var mesh_instance := child as MeshInstance3D
				if mesh_instance.mesh != null and mesh_instance.mesh.material != null:
					return mesh_instance.mesh.material
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.4745098, 0.54509807, 1.0)
	material.roughness = 0.9
	return material


func _clear_overlapping_legacy_floor(scene: Node3D, surface: Node, data: Dictionary) -> int:
	var lookup := _build_legacy_clear_lookup(
		data.get("legacy_clear_cells", []),
		float(data.get("cell_edge_x", 1.523075103759765)),
		float(data.get("cell_edge_z", 1.523075103759765))
	)
	if lookup.is_empty():
		return 0
	var terrain := scene.get_node_or_null("FS_GROUP_地形")
	if terrain == null:
		return 0
	var overlaps: Array[Node] = []
	_collect_legacy_floor_overlaps(terrain, surface, lookup, overlaps)
	var removed := 0
	for node in overlaps:
		if not is_instance_valid(node) or node.get_parent() == null:
			continue
		node.get_parent().remove_child(node)
		node.free()
		removed += 1
	return removed


func _build_legacy_clear_lookup(raw_cells: Array, edge_x: float, edge_z: float) -> Dictionary:
	if raw_cells.is_empty() or edge_x <= 0.0 or edge_z <= 0.0:
		return {}
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for raw_cell in raw_cells:
		if not raw_cell is Dictionary:
			continue
		var cell := raw_cell as Dictionary
		var x := float(cell.get("x", 0.0))
		var z := float(cell.get("z", 0.0))
		min_x = minf(min_x, x)
		max_x = maxf(max_x, x)
		min_z = minf(min_z, z)
		max_z = maxf(max_z, z)
	if not is_finite(min_x) or not is_finite(max_x) or not is_finite(min_z) or not is_finite(max_z):
		return {}
	var keys := {}
	for raw_cell in raw_cells:
		if not raw_cell is Dictionary:
			continue
		var cell := raw_cell as Dictionary
		var x := float(cell.get("x", 0.0))
		var z := float(cell.get("z", 0.0))
		var ix := int(round((x - min_x) / edge_x))
		var iz := int(round((z - min_z) / edge_z))
		keys["%d,%d" % [ix, iz]] = true
	return {
		"keys": keys,
		"min_x": min_x,
		"max_x": max_x,
		"min_z": min_z,
		"max_z": max_z,
		"edge_x": edge_x,
		"edge_z": edge_z,
	}


func _collect_legacy_floor_overlaps(
	node: Node,
	surface: Node,
	lookup: Dictionary,
	overlaps: Array[Node]
) -> void:
	if node == surface:
		return
	for child in node.get_children():
		if child == surface or surface.is_ancestor_of(child):
			continue
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			if (
				mesh_instance.mesh != null
				and _aabb_overlaps_clear_cells(_mesh_world_aabb(mesh_instance), lookup)
			):
				if not overlaps.has(mesh_instance):
					overlaps.append(mesh_instance)
				var parent := mesh_instance.get_parent()
				var collision := parent.get_node_or_null("%s_COLLISION" % mesh_instance.name)
				if collision != null and not overlaps.has(collision):
					overlaps.append(collision)
		_collect_legacy_floor_overlaps(child, surface, lookup, overlaps)


func _mesh_world_aabb(mesh_instance: MeshInstance3D) -> AABB:
	var local_aabb := mesh_instance.mesh.get_aabb()
	var min_point := Vector3(INF, INF, INF)
	var max_point := Vector3(-INF, -INF, -INF)
	for x_index in range(2):
		for y_index in range(2):
			for z_index in range(2):
				var corner := Vector3(
					local_aabb.position.x + local_aabb.size.x * float(x_index),
					local_aabb.position.y + local_aabb.size.y * float(y_index),
					local_aabb.position.z + local_aabb.size.z * float(z_index)
				)
				var world_point := mesh_instance.global_transform * corner
				min_point.x = minf(min_point.x, world_point.x)
				min_point.y = minf(min_point.y, world_point.y)
				min_point.z = minf(min_point.z, world_point.z)
				max_point.x = maxf(max_point.x, world_point.x)
				max_point.y = maxf(max_point.y, world_point.y)
				max_point.z = maxf(max_point.z, world_point.z)
	return AABB(min_point, max_point - min_point)


func _aabb_overlaps_clear_cells(bounds: AABB, lookup: Dictionary) -> bool:
	var top_y := bounds.position.y + bounds.size.y
	if top_y > LEGACY_CLEAR_TOP_MAX:
		return false
	var edge_x := float(lookup.get("edge_x", 0.0))
	var edge_z := float(lookup.get("edge_z", 0.0))
	if edge_x <= 0.0 or edge_z <= 0.0:
		return false
	var min_x := float(lookup.get("min_x", 0.0))
	var min_z := float(lookup.get("min_z", 0.0))
	var min_ix := floori((bounds.position.x - min_x) / edge_x + 0.5 - GRID_EPSILON / edge_x)
	var max_ix := ceili(((bounds.position.x + bounds.size.x) - min_x) / edge_x - 0.5 + GRID_EPSILON / edge_x)
	var min_iz := floori((bounds.position.z - min_z) / edge_z + 0.5 - GRID_EPSILON / edge_z)
	var max_iz := ceili(((bounds.position.z + bounds.size.z) - min_z) / edge_z - 0.5 + GRID_EPSILON / edge_z)
	var keys: Dictionary = lookup.get("keys", {})
	for ix in range(min_ix, max_ix + 1):
		for iz in range(min_iz, max_iz + 1):
			if keys.has("%d,%d" % [ix, iz]):
				return true
	return false


func _rebuild_cells(
	scene: Node3D,
	components: Dictionary,
	raw_cells: Array,
	cell_mesh: BoxMesh,
	cell_shape: BoxShape3D,
	floor_thickness: float
) -> int:
	for key in components:
		var component := components[key] as Node
		for child in component.get_children():
			component.remove_child(child)
			child.free()

	var rebuilt := 0
	for raw_cell in raw_cells:
		if not raw_cell is Dictionary:
			continue
		var cell := raw_cell as Dictionary
		var source := str(cell.get("s", ""))
		var component := components.get(source) as Node3D
		if component == null:
			continue
		var world_center := Vector3(
			float(cell.get("x", 0.0)),
			-floor_thickness * 0.5,
			float(cell.get("z", 0.0))
		)
		var local_center := component.to_local(world_center)
		var index := rebuilt
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "CELL_%04d" % index
		mesh_instance.mesh = cell_mesh
		mesh_instance.position = local_center
		mesh_instance.set_meta("fivestar_shape_kind", "v12_a_cell")
		mesh_instance.set_meta("fivestar_source_component", source)
		mesh_instance.set_meta("fivestar_surface_y", 0.0)
		component.add_child(mesh_instance)
		_assign_owner_recursive(mesh_instance, scene)

		var collision := CollisionShape3D.new()
		collision.name = "CELL_%04d_COLLISION" % index
		collision.shape = cell_shape
		collision.position = local_center
		collision.set_meta("fivestar_shape_kind", "v12_a_cell_collision")
		collision.set_meta("fivestar_source_component", source)
		component.add_child(collision)
		_assign_owner_recursive(collision, scene)
		rebuilt += 1
	return rebuilt


func _add_connectivity_geometry(
	parent: Node3D,
	scene: Node3D,
	raw_edges: Array,
	material: Material
) -> Dictionary:
	var counts := {
		"bridge": 0,
		"jump": 0,
		"dash": 0,
		"special": 0,
	}
	var edge_index := 0
	for raw_edge in raw_edges:
		if not raw_edge is Dictionary:
			continue
		var edge := raw_edge as Dictionary
		var method := str(edge.get("method", ""))
		if not counts.has(method):
			continue
		var marker: Node3D
		if method == "bridge":
			marker = _add_bridge(parent, edge, edge_index, material)
		elif method == "special":
			marker = _add_special_route(parent, edge, edge_index, material)
		else:
			marker = _add_gap_marker(parent, edge, edge_index)
		_assign_owner_recursive(marker, scene)
		counts[method] = int(counts[method]) + 1
		edge_index += 1
	return counts


func _add_bridge(parent: Node3D, edge: Dictionary, edge_index: int, material: Material) -> Node3D:
	var from := _edge_point(edge, "from")
	var to := _edge_point(edge, "to")
	var horizontal_from := Vector3(from.x, -BRIDGE_HEIGHT * 0.5, from.z)
	var horizontal_to := Vector3(to.x, -BRIDGE_HEIGHT * 0.5, to.z)
	var distance := horizontal_from.distance_to(horizontal_to)
	var midpoint := (horizontal_from + horizontal_to) * 0.5
	var body := StaticBody3D.new()
	body.name = "FS_BRIDGE_%d_%d" % [int(edge.get("a", 0)), int(edge.get("b", 0))]
	parent.add_child(body)
	body.position = midpoint
	if distance > 0.001:
		body.look_at(horizontal_to, Vector3.UP)
	_set_edge_metadata(body, edge, edge_index, true)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "BRIDGE_SURFACE"
	var bridge_mesh := BoxMesh.new()
	bridge_mesh.size = Vector3(BRIDGE_WIDTH, BRIDGE_HEIGHT, distance + 0.14)
	bridge_mesh.material = material
	mesh_instance.mesh = bridge_mesh
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	collision.name = "BRIDGE_COLLISION"
	var bridge_shape := BoxShape3D.new()
	bridge_shape.size = bridge_mesh.size
	collision.shape = bridge_shape
	body.add_child(collision)
	return body


func _add_gap_marker(parent: Node3D, edge: Dictionary, edge_index: int) -> Node3D:
	var from := _edge_point(edge, "from")
	var to := _edge_point(edge, "to")
	var marker := Node3D.new()
	marker.name = "FS_EDGE_%s_%d_%d" % [
		str(edge.get("method", "")).to_upper(),
		int(edge.get("a", 0)),
		int(edge.get("b", 0)),
	]
	parent.add_child(marker)
	marker.position = Vector3((from.x + to.x) * 0.5, 0.0, (from.z + to.z) * 0.5)
	_set_edge_metadata(marker, edge, edge_index, true)
	return marker


func _add_special_route(parent: Node3D, edge: Dictionary, edge_index: int, material: Material) -> Node3D:
	var from := _edge_point(edge, "from")
	var to := _edge_point(edge, "to")
	var route := Node3D.new()
	route.name = "FS_SPECIAL_ROUTE_%d_%d" % [int(edge.get("a", 0)), int(edge.get("b", 0))]
	parent.add_child(route)
	_set_edge_metadata(route, edge, edge_index, true)

	var distance := Vector2(from.x, from.z).distance_to(Vector2(to.x, to.z))
	var segment_count := maxi(2, ceili(distance / SPECIAL_STEP_SPACING))
	var internal_step_count := segment_count - 1
	route.set_meta("special_segment_count", segment_count)
	route.set_meta("special_internal_step_count", internal_step_count)
	for step_index in range(1, internal_step_count + 1):
		var t := float(step_index) / float(segment_count)
		var world_center := from.lerp(to, t)
		world_center.y = -SPECIAL_STEP_HEIGHT * 0.5
		var step := StaticBody3D.new()
		step.name = "SPECIAL_STEP_%02d" % step_index
		route.add_child(step)
		step.position = world_center
		step.set_meta("connection_method", "special")
		step.set_meta("special_step", true)
		step.set_meta("route_a", int(edge.get("a", 0)))
		step.set_meta("route_b", int(edge.get("b", 0)))
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "STEP_SURFACE"
		var step_mesh := BoxMesh.new()
		step_mesh.size = Vector3(SPECIAL_STEP_SIZE, SPECIAL_STEP_HEIGHT, SPECIAL_STEP_SIZE)
		step_mesh.material = material
		mesh_instance.mesh = step_mesh
		step.add_child(mesh_instance)
		var collision := CollisionShape3D.new()
		collision.name = "STEP_COLLISION"
		var step_shape := BoxShape3D.new()
		step_shape.size = step_mesh.size
		collision.shape = step_shape
		step.add_child(collision)
	return route


func _set_edge_metadata(node: Node3D, edge: Dictionary, edge_index: int, is_marker: bool) -> void:
	node.set_meta("v12_a_edge_marker", is_marker)
	node.set_meta("edge_index", edge_index)
	node.set_meta("connection_method", str(edge.get("method", "")))
	node.set_meta("connection_gap", float(edge.get("gap", 0.0)))
	node.set_meta("room_a", int(edge.get("a", 0)))
	node.set_meta("room_b", int(edge.get("b", 0)))
	node.set_meta("connection_from", _edge_point(edge, "from"))
	node.set_meta("connection_to", _edge_point(edge, "to"))


func _edge_point(edge: Dictionary, prefix: String) -> Vector3:
	return Vector3(
		float(edge.get("%sX" % prefix, 0.0)),
		0.0,
		float(edge.get("%sZ" % prefix, 0.0))
	)


func _build_stats(
	data: Dictionary,
	rebuilt_cells: int,
	edge_counts: Dictionary,
	legacy_cleared: int
) -> Dictionary:
	var rooms: Array = data.get("rooms", [])
	var edges: Array = data.get("edges", [])
	var total := maxi(edges.size(), 1)
	return {
		"schema_version": 1,
		"source": str(data.get("source", "")),
		"seed": int(data.get("seed", 0)),
		"cell_count": rebuilt_cells,
		"source_component_count": int(data.get("source_components", []).size()),
		"legacy_cleared_nodes": legacy_cleared,
		"room_count": rooms.size(),
		"edge_count": edges.size(),
		"method_counts": edge_counts.duplicate(true),
		"ratios": {
			"bridge": float(edge_counts.get("bridge", 0)) / float(total),
			"jump": float(edge_counts.get("jump", 0)) / float(total),
			"dash": float(edge_counts.get("dash", 0)) / float(total),
			"special": float(edge_counts.get("special", 0)) / float(total),
		},
		"connected_component_count": _connected_component_count(rooms, edges),
		"jump_safe_distance": float(data.get("jump_safe_distance", 0.0)),
		"dash_safe_distance": float(data.get("dash_safe_distance", 0.0)),
	}


func _apply_connectivity_metadata(scene: Node3D, surface: Node, stats: Dictionary) -> void:
	scene.set_meta("fivestar_connectivity_v12_a", stats)
	surface.set_meta("fivestar_connectivity_v12_a", stats)
	var semantic_variant: Variant = scene.get_meta("fivestar_semantic", {})
	if semantic_variant is Dictionary:
		var semantic := (semantic_variant as Dictionary).duplicate(true)
		var params_variant: Variant = semantic.get("params", {})
		var params := (params_variant as Dictionary).duplicate(true) if params_variant is Dictionary else {}
		params["v12_a_connectivity"] = stats.duplicate(true)
		var counts_variant: Variant = params.get("structure_counts", {})
		var counts := (counts_variant as Dictionary).duplicate(true) if counts_variant is Dictionary else {}
		counts["v12_a_cells"] = int(stats.get("cell_count", 0))
		counts["v12_a_rooms"] = int(stats.get("room_count", 0))
		counts["v12_a_edges"] = int(stats.get("edge_count", 0))
		params["structure_counts"] = counts
		semantic["params"] = params
		scene.set_meta("fivestar_semantic", semantic)


func _count_edges(edges: Array) -> Dictionary:
	var counts := {"bridge": 0, "jump": 0, "dash": 0, "special": 0}
	for raw_edge in edges:
		if not raw_edge is Dictionary:
			continue
		var method := str((raw_edge as Dictionary).get("method", ""))
		if counts.has(method):
			counts[method] = int(counts[method]) + 1
	return counts


func _connected_component_count(rooms: Array, edges: Array) -> int:
	var room_ids := {}
	for raw_room in rooms:
		if raw_room is Dictionary:
			room_ids[int((raw_room as Dictionary).get("id", 0))] = true
	var parent := {}
	for room_id in room_ids:
		parent[room_id] = room_id
	for raw_edge in edges:
		if not raw_edge is Dictionary:
			continue
		var edge := raw_edge as Dictionary
		_union(parent, int(edge.get("a", 0)), int(edge.get("b", 0)))
	var roots := {}
	for room_id in room_ids:
		roots[_find_root(parent, int(room_id))] = true
	return roots.size()


func _find_root(parent: Dictionary, value: int) -> int:
	var current := value
	while int(parent.get(current, current)) != current:
		current = int(parent.get(current, current))
	while int(parent.get(value, value)) != value:
		var next := int(parent.get(value, value))
		parent[value] = current
		value = next
	return current


func _union(parent: Dictionary, a: int, b: int) -> void:
	if not parent.has(a) or not parent.has(b):
		return
	var root_a := _find_root(parent, a)
	var root_b := _find_root(parent, b)
	if root_a != root_b:
		parent[root_b] = root_a


func _assign_owner_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_assign_owner_recursive(child, owner)
