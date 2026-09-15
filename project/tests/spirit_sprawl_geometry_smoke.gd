extends SceneTree

const SCENE_PATH := "res://authoring/scenes/spirit_sprawl_geometry.tscn"
const DATA_PATH := "res://authoring/data/spirit_sprawl_v12_a_connectivity.json"
const SURFACE_PATH := "FS_GROUP_地形/FS_ZONE_北中分叉陆区_NORTH_KNOT/SURFACE_NORTH_KNOT"

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
const SURFACE_EPSILON := 0.002
const SUPPORT_EPSILON := 0.04
const LEGACY_CLEAR_TOP_MAX := 0.65
const GRID_EPSILON := 0.002


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var data := _load_json(DATA_PATH)
	ok = _expect(not data.is_empty(), "v12-A connectivity data must load: %s" % DATA_PATH) and ok
	var packed := ResourceLoader.load(SCENE_PATH) as PackedScene
	ok = _expect(packed != null, "Geometry scene must load: %s" % SCENE_PATH) and ok
	if data.is_empty() or packed == null:
		quit(1)
		return

	var scene := packed.instantiate() as Node3D
	ok = _expect(scene != null, "Geometry scene root must be Node3D") and ok
	if scene == null:
		quit(1)
		return
	root.add_child(scene)
	await physics_frame
	await physics_frame

	var cells: Array = data.get("cells", [])
	var rooms: Array = data.get("rooms", [])
	var edges: Array = data.get("edges", [])
	var source_components: Array = data.get("source_components", [])
	ok = _expect(cells.size() == EXPECTED_CELLS, "JSON cell count mismatch: %d" % cells.size()) and ok
	ok = _expect(rooms.size() == EXPECTED_ROOMS, "JSON room count mismatch: %d" % rooms.size()) and ok
	ok = _expect(edges.size() == EXPECTED_EDGES, "JSON edge count mismatch: %d" % edges.size()) and ok
	ok = _expect(
		source_components.size() == EXPECTED_SOURCE_COMPONENTS,
		"JSON source component count mismatch: %d" % source_components.size()
	) and ok
	var legacy_clear_cells: Array = data.get("legacy_clear_cells", [])
	ok = _expect(
		legacy_clear_cells.size() == EXPECTED_LEGACY_CLEAR_CELLS,
		"JSON legacy clear cell count mismatch: %d" % legacy_clear_cells.size()
	) and ok

	var surface := scene.get_node_or_null(SURFACE_PATH) as Node
	ok = _expect(surface != null, "Missing terrain surface: %s" % SURFACE_PATH) and ok
	if surface == null:
		scene.queue_free()
		quit(1)
		return

	var component_nodes := {}
	for child in surface.get_children():
		var source := str(child.get_meta("fivestar_source_component", ""))
		if not source.is_empty():
			component_nodes[source] = child
	ok = _expect(
		component_nodes.size() == EXPECTED_SOURCE_COMPONENTS,
		"Scene source component count mismatch: %d" % component_nodes.size()
	) and ok

	var expected_per_source := {}
	for raw_cell in cells:
		if not raw_cell is Dictionary:
			continue
		var cell := raw_cell as Dictionary
		var source := str(cell.get("s", ""))
		expected_per_source[source] = int(expected_per_source.get(source, 0)) + 1

	var cell_result := {
		"meshes": 0,
		"collisions": 0,
		"top_errors": 0,
		"per_source": {},
	}
	_walk_cells(scene, cell_result)
	var cell_meshes := int(cell_result.get("meshes", 0))
	var cell_collisions := int(cell_result.get("collisions", 0))
	var top_errors := int(cell_result.get("top_errors", 0))
	var legacy_overlap_count := _legacy_floor_overlap_count(scene, surface, data)
	var actual_per_source: Dictionary = cell_result.get("per_source", {})
	ok = _expect(cell_meshes == EXPECTED_CELLS, "Cell mesh count mismatch: %d" % cell_meshes) and ok
	ok = _expect(cell_collisions == EXPECTED_CELLS, "Cell collision count mismatch: %d" % cell_collisions) and ok
	ok = _expect(top_errors == 0, "Cells with non-zero world surface: %d" % top_errors) and ok
	ok = _expect(legacy_overlap_count == 0, "Legacy floor overlaps remaining: %d" % legacy_overlap_count) and ok

	var source_count_errors := 0
	for source in source_components:
		var source_id := str(source)
		var expected_count := int(expected_per_source.get(source_id, 0))
		var actual_count := int(actual_per_source.get(source_id, 0))
		if actual_count != expected_count:
			source_count_errors += 1
			push_error("Source %s cell count mismatch: %d != %d" % [source_id, actual_count, expected_count])
	ok = _expect(source_count_errors == 0, "Source cell count mismatches: %d" % source_count_errors) and ok

	var method_counts := {"bridge": 0, "jump": 0, "dash": 0, "special": 0}
	var edge_errors := 0
	var room_parent := {}
	for room_id in range(1, EXPECTED_ROOMS + 1):
		room_parent[room_id] = room_id
	for raw_edge in edges:
		if not raw_edge is Dictionary:
			edge_errors += 1
			continue
		var edge := raw_edge as Dictionary
		var method := str(edge.get("method", ""))
		if method_counts.has(method):
			method_counts[method] = int(method_counts[method]) + 1
		else:
			edge_errors += 1
		var room_a := int(edge.get("a", 0))
		var room_b := int(edge.get("b", 0))
		if room_a <= 0 or room_b <= 0:
			edge_errors += 1
			continue
		_union(room_parent, room_a, room_b)
	for method in EXPECTED_COUNTS:
		ok = _expect(
			int(method_counts.get(method, 0)) == int(EXPECTED_COUNTS[method]),
			"Method count mismatch for %s: %d != %d"
				% [method, int(method_counts.get(method, 0)), int(EXPECTED_COUNTS[method])]
		) and ok
	ok = _expect(edge_errors == 0, "Invalid connectivity edges: %d" % edge_errors) and ok
	var roots := {}
	for room_id in range(1, EXPECTED_ROOMS + 1):
		roots[_find_root(room_parent, room_id)] = true
	var graph_component_count := roots.size()
	ok = _expect(graph_component_count == 1, "JSON room graph components: %d" % graph_component_count) and ok

	print(
		"SPIRIT_SPRAWL_GEOMETRY_V12_A components=%d cells=%d cell_meshes=%d cell_collisions=%d legacy_overlaps=%d edges=%d bridge=%d jump=%d dash=%d special=%d graph_components=%d top_errors=%d errors=%d"
		% [
			component_nodes.size(),
			cells.size(),
			cell_meshes,
			cell_collisions,
			legacy_overlap_count,
			edges.size(),
			int(method_counts.get("bridge", 0)),
			int(method_counts.get("jump", 0)),
			int(method_counts.get("dash", 0)),
			int(method_counts.get("special", 0)),
			graph_component_count,
			top_errors,
			0 if ok else 1,
		]
	)
	scene.queue_free()
	quit(0 if ok else 1)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing JSON file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not parsed is Dictionary:
		push_error("Invalid JSON dictionary: %s" % path)
		return {}
	return parsed as Dictionary


func _walk_cells(node: Node, result: Dictionary) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if str(mesh_instance.get_meta("fivestar_shape_kind", "")) == "v12_a_cell":
			result["meshes"] = int(result["meshes"]) + 1
			var source := str(mesh_instance.get_meta("fivestar_source_component", ""))
			var per_source: Dictionary = result["per_source"]
			per_source[source] = int(per_source.get(source, 0)) + 1
			result["per_source"] = per_source
			if mesh_instance.mesh != null:
				var top_y := _mesh_top_y(mesh_instance)
				if absf(top_y) > SURFACE_EPSILON:
					result["top_errors"] = int(result["top_errors"]) + 1
	if node is CollisionShape3D:
		if str(node.get_meta("fivestar_shape_kind", "")) == "v12_a_cell_collision":
			result["collisions"] = int(result["collisions"]) + 1
	for child in node.get_children():
		_walk_cells(child, result)


func _mesh_top_y(mesh_instance: MeshInstance3D) -> float:
	var aabb := mesh_instance.mesh.get_aabb()
	var top_y := -INF
	for x_index in range(2):
		for y_index in range(2):
			for z_index in range(2):
				var corner := Vector3(
					aabb.position.x + aabb.size.x * float(x_index),
					aabb.position.y + aabb.size.y * float(y_index),
					aabb.position.z + aabb.size.z * float(z_index)
				)
				top_y = maxf(top_y, (mesh_instance.global_transform * corner).y)
	return top_y


func _legacy_floor_overlap_count(scene: Node3D, surface: Node, data: Dictionary) -> int:
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
	var count := 0
	_collect_legacy_floor_overlaps(terrain, surface, lookup, [count])
	return count


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
	count_holder: Array
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
				count_holder[0] = int(count_holder[0]) + 1
		_collect_legacy_floor_overlaps(child, surface, lookup, count_holder)


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


func _collect_markers(node: Node, markers: Array) -> void:
	if bool(node.get_meta("v12_a_edge_marker", false)):
		markers.append(node)
	for child in node.get_children():
		_collect_markers(child, markers)


func _collect_special_steps(node: Node, steps: Array) -> void:
	if bool(node.get_meta("special_step", false)):
		steps.append(node)
	for child in node.get_children():
		_collect_special_steps(child, steps)


func _marker_component_count(markers: Array) -> int:
	var parent := {}
	for room_id in range(1, EXPECTED_ROOMS + 1):
		parent[room_id] = room_id
	for raw_marker in markers:
		var marker := raw_marker as Node
		_union(parent, int(marker.get_meta("room_a", 0)), int(marker.get_meta("room_b", 0)))
	var roots := {}
	for room_id in range(1, EXPECTED_ROOMS + 1):
		roots[_find_root(parent, room_id)] = true
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


func _has_surface_support(physics: PhysicsDirectSpaceState3D, x: float, z: float) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(x, 3.0, z),
		Vector3(x, -3.0, z)
	)
	query.collide_with_areas = false
	var hit := physics.intersect_ray(query)
	if hit.is_empty():
		return false
	return absf(float(hit.get("position", Vector3(0.0, INF, 0.0)).y)) <= SUPPORT_EPSILON


func _dictionary_meta(node: Node, key: String) -> Dictionary:
	var value: Variant = node.get_meta(key, {})
	if value is Dictionary:
		return value as Dictionary
	return {}


func _dictionary_value(source: Dictionary, key: String) -> Dictionary:
	var value: Variant = source.get(key, {})
	if value is Dictionary:
		return value as Dictionary
	return {}


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition
