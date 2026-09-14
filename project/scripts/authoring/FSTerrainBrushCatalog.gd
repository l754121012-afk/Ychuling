class_name FSTerrainBrushCatalog
extends RefCounted

const GROUP_TERRAIN := "FS_GROUP_地形"
const GRID_MAP_NAME := "FS_TERRAIN_BRUSH_地形画笔"
const META_KEY := "__fs_terrain_brush_grid_map"
const GRID_SIZE := 1.0
const MIN_HEIGHT_LEVEL := -8
const MAX_HEIGHT_LEVEL := 24
const MIN_THICKNESS := 0.10
const MAX_THICKNESS := 2.00
const THICKNESS_STEP := 0.02
const MAX_CELL_PICK_DISTANCE := MAX_THICKNESS * 0.5 + 0.20
const META_VERSION := 2
const INVALID_ITEM := -1
const ERASER_ID := "eraser"

const TERRAINS := [
	{
		"id": "grass_platform",
		"label": "草地平台",
		"color": "#4d7a43",
		"accent": "#78a15d",
		"roughness": 0.92,
		"thickness": 0.24,
	},
	{
		"id": "floating_platform",
		"label": "浮空平台",
		"color": "#596f78",
		"accent": "#91b9c1",
		"roughness": 0.68,
		"thickness": 0.32,
	},
	{
		"id": "stone_ground",
		"label": "石质地面",
		"color": "#74797a",
		"accent": "#aeb2ae",
		"roughness": 0.86,
		"thickness": 0.38,
	},
	{
		"id": "road_ground",
		"label": "道路地面",
		"color": "#8b806f",
		"accent": "#b9aa91",
		"roughness": 0.94,
		"thickness": 0.18,
	},
	{
		"id": "wood_boardwalk",
		"label": "木桥 / 栈道",
		"color": "#815e3e",
		"accent": "#bd8c5e",
		"roughness": 0.82,
		"thickness": 0.2,
	},
]

const SHAPES := [
	{"id": "square", "label": "方形笔刷"},
	{"id": "circle", "label": "圆形笔刷"},
]

const SIZES := [
	{"id": "1", "label": "1 × 1 格", "value": 1},
	{"id": "3", "label": "3 × 3 格", "value": 3},
	{"id": "5", "label": "5 × 5 格", "value": 5},
	{"id": "7", "label": "7 × 7 格", "value": 7},
]


static func presets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in TERRAINS:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	result.append({
		"id": ERASER_ID,
		"label": "擦除画笔地形",
		"color": "#222222",
		"accent": "#dddddd",
		"roughness": 1.0,
		"thickness": GRID_SIZE,
	})
	return result


static func terrain_presets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in TERRAINS:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	return result


static func shapes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in SHAPES:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	return result


static func sizes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in SIZES:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	return result


static func brush_params(
	p_preset_id: String,
	p_shape_id: String,
	p_size: int,
	p_height_level: int,
	p_thickness: float = -1.0
) -> Dictionary:
	var preset := _find_preset(p_preset_id)
	if preset.is_empty():
		preset = TERRAINS[0] as Dictionary
	var shape_id := p_shape_id if p_shape_id in ["square", "circle"] else "square"
	var brush_size := p_size
	if brush_size not in [1, 3, 5, 7]:
		brush_size = 3
	return {
		"preset_id": str(preset.get("id", "grass_platform")),
		"preset_label": str(preset.get("label", "草地平台")),
		"item_id": _item_id_for_preset(str(preset.get("id", ""))),
		"is_eraser": str(preset.get("id", "")) == ERASER_ID,
		"thickness": (
			_normalize_thickness(p_thickness)
			if p_thickness > 0.0
			else default_thickness(str(preset.get("id", "")))
		),
		"shape_id": shape_id,
		"size": brush_size,
		"height_level": clampi(p_height_level, MIN_HEIGHT_LEVEL, MAX_HEIGHT_LEVEL),
		"grid_size": GRID_SIZE,
	}


static func ensure_grid_map(
	p_root: Node,
	p_owner: Node = null,
	p_preferred_node: Node = null
) -> Dictionary:
	if not (p_root is Node3D):
		return {"ok": false, "error": "实体地形画笔需要三维场景根节点。"}
	var root := p_root as Node3D
	var preferred_belongs_to_root := (
		p_preferred_node != null
		and (p_preferred_node == root or root.is_ancestor_of(p_preferred_node))
	)
	var preferred_parent := _preferred_brush_parent(root, p_preferred_node)
	var grid_map: GridMap = null
	if is_terrain_grid_map(p_preferred_node) and preferred_belongs_to_root:
		grid_map = p_preferred_node as GridMap
	if grid_map == null and preferred_parent != null:
		grid_map = _find_direct_terrain_grid_map(preferred_parent)
	if grid_map == null and preferred_belongs_to_root:
		grid_map = _find_first_terrain_grid_map(p_preferred_node)
	if grid_map == null and preferred_parent != null:
		grid_map = _find_first_terrain_grid_map(preferred_parent)
	if grid_map == null and p_preferred_node == null:
		grid_map = _find_first_terrain_grid_map(root)

	var terrain_parent: Node3D = null
	var created_parent := false
	if grid_map != null:
		terrain_parent = grid_map.get_parent() as Node3D
	else:
		if preferred_parent != null:
			terrain_parent = preferred_parent
		else:
			var existing_parent := root.get_node_or_null(GROUP_TERRAIN)
			if existing_parent == null:
				terrain_parent = Node3D.new()
				terrain_parent.name = GROUP_TERRAIN
				root.add_child(terrain_parent)
				created_parent = true
			elif existing_parent is Node3D:
				terrain_parent = existing_parent as Node3D
			else:
				return {
					"ok": false,
					"error": "%s 已存在，但不是 Node3D 容器。" % GROUP_TERRAIN,
				}
	if terrain_parent == null:
		return {"ok": false, "error": "无法确定实体地形画笔的父级。"}
	if grid_map == null:
		grid_map = terrain_parent.get_node_or_null(GRID_MAP_NAME) as GridMap
	if grid_map == null:
		if terrain_parent.has_node(GRID_MAP_NAME):
			return {"ok": false, "error": "%s 已存在，但不是 GridMap。" % GRID_MAP_NAME}
		grid_map = GridMap.new()
		grid_map.name = GRID_MAP_NAME
		terrain_parent.add_child(grid_map)
	var library := grid_map.mesh_library
	if library == null or not _is_terrain_library(library):
		library = build_mesh_library()
		grid_map.mesh_library = library
	grid_map.cell_size = Vector3.ONE * GRID_SIZE
	grid_map.collision_layer = 1
	grid_map.collision_mask = 1
	_ensure_palette(grid_map)
	var owner_for_scene := p_owner if p_owner != null else root
	if created_parent or terrain_parent.name == GROUP_TERRAIN:
		terrain_parent.owner = owner_for_scene
	grid_map.owner = owner_for_scene
	return {
		"ok": true,
		"grid_map": grid_map,
		"parent": terrain_parent,
		"mesh_library": library,
		"used_cells": grid_map.get_used_cells().size(),
	}


static func build_mesh_library() -> MeshLibrary:
	var library := MeshLibrary.new()
	library.resource_name = "FIVESTAR 实体地形画笔"
	library.resource_local_to_scene = true
	for index in range(TERRAINS.size()):
		var entry: Dictionary = TERRAINS[index]
		_configure_library_item(
			library,
			index,
			str(entry.get("id", "")),
			default_thickness(str(entry.get("id", "")))
		)
	return library


static func cell_for_world_position(
	p_grid_map: GridMap,
	p_world_position: Vector3,
	p_height_level: int
) -> Vector3i:
	if p_grid_map == null:
		return Vector3i.ZERO
	var local_position := (
		p_grid_map.global_transform.affine_inverse() * p_world_position
		if p_grid_map.is_inside_tree()
		else p_world_position
	)
	return Vector3i(
		roundi(local_position.x / GRID_SIZE),
		roundi(local_position.y / GRID_SIZE) + p_height_level,
		roundi(local_position.z / GRID_SIZE)
	)


static func apply_stamp(
	p_grid_map: GridMap,
	p_center_cell: Vector3i,
	p_params: Dictionary
) -> Dictionary:
	if p_grid_map == null:
		return {"ok": false, "error": "没有可写入的实体地形 GridMap。"}
	var offsets := brush_offsets(
		int(p_params.get("size", 3)),
		str(p_params.get("shape_id", "square"))
	)
	var erase := bool(p_params.get("is_eraser", false))
	var item_id := INVALID_ITEM
	if not erase:
		item_id = resolve_item_id(
			p_grid_map,
			str(p_params.get("preset_id", "")),
			float(p_params.get("thickness", -1.0))
		)
		if item_id < 0:
			return {"ok": false, "error": "实体地形笔刷项目无效。"}
	var added := 0
	var replaced := 0
	var erased := 0
	var unchanged := 0
	for offset in offsets:
		var cell := p_center_cell + offset
		var previous := p_grid_map.get_cell_item(cell)
		if erase:
			if previous == INVALID_ITEM:
				unchanged += 1
				continue
			p_grid_map.set_cell_item(cell, INVALID_ITEM)
			erased += 1
			continue
		if previous == item_id:
			unchanged += 1
			continue
		if previous == INVALID_ITEM:
			added += 1
		else:
			replaced += 1
		p_grid_map.set_cell_item(cell, item_id)
	return {
		"ok": true,
		"added": added,
		"replaced": replaced,
		"erased": erased,
		"unchanged": unchanged,
		"changed": added + replaced + erased,
		"used_cells": p_grid_map.get_used_cells().size(),
	}


static func resolve_item_id(
	p_grid_map: GridMap,
	p_preset_id: String,
	p_thickness: float = -1.0
) -> int:
	if p_grid_map == null:
		return INVALID_ITEM
	var terrain_index := _terrain_index_for_preset(p_preset_id)
	if terrain_index < 0:
		return INVALID_ITEM
	var thickness := _normalize_thickness(
		p_thickness if p_thickness > 0.0 else default_thickness(p_preset_id)
	)
	if _same_thickness(thickness, default_thickness(p_preset_id)):
		return terrain_index
	var meta := _ensure_palette(p_grid_map)
	var palette: Dictionary = meta.get("item_palette", {})
	for key in palette.keys():
		var entry = palette.get(key, {})
		if (
			entry is Dictionary
			and str(entry.get("preset_id", "")) == p_preset_id
			and _same_thickness(float(entry.get("thickness", -1.0)), thickness)
		):
			return int(key)
	return _create_variant_item(p_grid_map, p_preset_id, thickness)


static func get_cell_info(p_grid_map: GridMap, p_cell: Vector3i) -> Dictionary:
	if p_grid_map == null:
		return {"ok": false, "error": "没有实体地形网格。"}
	var item_id := p_grid_map.get_cell_item(p_cell)
	if item_id == INVALID_ITEM:
		return {
			"ok": false,
			"error": "该格没有实体地形。",
			"cell": p_cell,
		}
	var meta := _ensure_palette(p_grid_map)
	var palette: Dictionary = meta.get("item_palette", {})
	var entry = palette.get(str(item_id), {})
	if not (entry is Dictionary) or entry.is_empty():
		return {
			"ok": false,
			"error": "该格的地形类型记录缺失。",
			"cell": p_cell,
		}
	var preset_id := str(entry.get("preset_id", ""))
	var preset := _find_preset(preset_id)
	return {
		"ok": true,
		"cell": p_cell,
		"item_id": item_id,
		"terrain_index": int(entry.get("terrain_index", -1)),
		"preset_id": preset_id,
		"preset_label": str(preset.get("label", preset_id)),
		"thickness": float(entry.get("thickness", default_thickness(preset_id))),
		"height_level": p_cell.y,
	}


static func pick_cell_at_world_position(
	p_grid_map: GridMap,
	p_world_position: Vector3,
	p_max_distance: float = MAX_CELL_PICK_DISTANCE
) -> Dictionary:
	if p_grid_map == null:
		return {"ok": false, "error": "没有实体地形网格。"}
	var local_position := (
		p_grid_map.global_transform.affine_inverse() * p_world_position
		if p_grid_map.is_inside_tree()
		else p_world_position
	)
	var cell_size := p_grid_map.cell_size
	var half_grid_x := maxf(cell_size.x * 0.5, 0.001)
	var half_grid_z := maxf(cell_size.z * 0.5, 0.001)
	var center_y := roundi(local_position.y / maxf(cell_size.y, 0.001))
	var best_cell := Vector3i.ZERO
	var best_info: Dictionary = {}
	var best_distance := INF
	# Custom thickness can move the visible top face away from the cell origin,
	# so inspect nearby levels and compare against each cell's actual AABB.
	for y_offset in range(-4, 5):
		for z_offset in range(-1, 2):
			for x_offset in range(-1, 2):
				var cell := Vector3i(
					roundi(local_position.x / maxf(cell_size.x, 0.001)) + x_offset,
					center_y + y_offset,
					roundi(local_position.z / maxf(cell_size.z, 0.001)) + z_offset
				)
				var info := get_cell_info(p_grid_map, cell)
				if not bool(info.get("ok", false)):
					continue
				var thickness := float(info.get("thickness", 0.0))
				var center := Vector3(
					float(cell.x) * cell_size.x,
					float(cell.y) * cell_size.y,
					float(cell.z) * cell_size.z
				)
				var minimum := Vector3(
					center.x - half_grid_x,
					center.y - thickness * 0.5,
					center.z - half_grid_z
				)
				var maximum := Vector3(
					center.x + half_grid_x,
					center.y + thickness * 0.5,
					center.z + half_grid_z
				)
				var closest := Vector3(
					clampf(local_position.x, minimum.x, maximum.x),
					clampf(local_position.y, minimum.y, maximum.y),
					clampf(local_position.z, minimum.z, maximum.z)
				)
				var distance := closest.distance_to(local_position)
				if distance < best_distance:
					best_distance = distance
					best_cell = cell
					best_info = info
	if best_info.is_empty() or best_distance > p_max_distance:
		return {
			"ok": false,
			"error": "没有选中实体地形格；请点击已有画笔格。",
			"distance": best_distance,
		}
	best_info["pick_distance"] = best_distance
	return best_info


static func remove_cell(p_grid_map: GridMap, p_cell: Vector3i) -> Dictionary:
	if p_grid_map == null:
		return {"ok": false, "error": "没有实体地形网格。"}
	var previous := p_grid_map.get_cell_item(p_cell)
	if previous == INVALID_ITEM:
		return {
			"ok": true,
			"removed": 0,
			"used_cells": p_grid_map.get_used_cells().size(),
		}
	p_grid_map.set_cell_item(p_cell, INVALID_ITEM)
	return {
		"ok": true,
		"removed": 1,
		"used_cells": p_grid_map.get_used_cells().size(),
	}


static func default_thickness(p_preset_id: String) -> float:
	var index := _terrain_index_for_preset(p_preset_id)
	if index < 0:
		return _normalize_thickness(
			float((TERRAINS[0] as Dictionary).get("thickness", 0.24))
		)
	return _normalize_thickness(
		float((TERRAINS[index] as Dictionary).get("thickness", 0.24))
	)


static func _normalize_thickness(p_thickness: float) -> float:
	return snappedf(
		clampf(p_thickness, MIN_THICKNESS, MAX_THICKNESS),
		THICKNESS_STEP
	)


static func _same_thickness(p_a: float, p_b: float) -> bool:
	return absf(p_a - p_b) <= 0.001


static func _ensure_palette(p_grid_map: GridMap) -> Dictionary:
	var current = p_grid_map.get_meta(META_KEY, {})
	var meta: Dictionary = current.duplicate(true) if current is Dictionary else {}
	var current_palette = meta.get("item_palette", {})
	var palette: Dictionary = (
		current_palette.duplicate(true)
		if current_palette is Dictionary
		else {}
	)
	for index in range(TERRAINS.size()):
		var entry: Dictionary = TERRAINS[index]
		var preset_id := str(entry.get("id", ""))
		if not palette.has(str(index)):
			palette[str(index)] = {
				"preset_id": preset_id,
				"terrain_index": index,
				"thickness": default_thickness(preset_id),
			}
	var next_item_id := TERRAINS.size()
	for key in palette.keys():
		next_item_id = maxi(next_item_id, int(str(key)) + 1)
	next_item_id = maxi(next_item_id, int(meta.get("next_item_id", TERRAINS.size())))
	meta["version"] = META_VERSION
	meta["grid_size"] = GRID_SIZE
	meta["preset_ids"] = _terrain_ids()
	meta["item_palette"] = palette
	meta["next_item_id"] = next_item_id
	p_grid_map.set_meta(META_KEY, meta)
	return meta


static func _create_variant_item(
	p_grid_map: GridMap,
	p_preset_id: String,
	p_thickness: float
) -> int:
	var library := p_grid_map.mesh_library
	if library == null:
		return INVALID_ITEM
	var meta := _ensure_palette(p_grid_map)
	var item_id := int(meta.get("next_item_id", TERRAINS.size()))
	var used_items := library.get_item_list()
	while used_items.has(item_id):
		item_id += 1
	_configure_library_item(library, item_id, p_preset_id, p_thickness)
	var palette: Dictionary = meta.get("item_palette", {})
	palette[str(item_id)] = {
		"preset_id": p_preset_id,
		"terrain_index": _terrain_index_for_preset(p_preset_id),
		"thickness": p_thickness,
	}
	meta["item_palette"] = palette
	meta["next_item_id"] = item_id + 1
	meta["version"] = META_VERSION
	p_grid_map.set_meta(META_KEY, meta)
	return item_id


static func _configure_library_item(
	p_library: MeshLibrary,
	p_item_id: int,
	p_preset_id: String,
	p_thickness: float
) -> void:
	var entry := _find_preset(p_preset_id)
	if entry.is_empty():
		entry = TERRAINS[0] as Dictionary
	var thickness := _normalize_thickness(p_thickness)
	var visual_size := Vector3(GRID_SIZE * 0.98, thickness, GRID_SIZE * 0.98)
	var collision_size := Vector3(GRID_SIZE, thickness, GRID_SIZE)
	var mesh := BoxMesh.new()
	mesh.size = visual_size
	mesh.material = _make_material(entry)
	var shape := BoxShape3D.new()
	shape.size = collision_size
	if not p_library.get_item_list().has(p_item_id):
		p_library.create_item(p_item_id)
	p_library.set_item_name(
		p_item_id,
		"%s · %.2fm" % [str(entry.get("label", "")), thickness]
	)
	p_library.set_item_mesh(p_item_id, mesh)
	p_library.set_item_mesh_transform(p_item_id, Transform3D.IDENTITY)
	p_library.set_item_shapes(p_item_id, [shape])


static func apply_line(
	p_grid_map: GridMap,
	p_from_cell: Vector3i,
	p_to_cell: Vector3i,
	p_params: Dictionary
) -> Dictionary:
	var added := 0
	var replaced := 0
	var erased := 0
	var unchanged := 0
	var stamps := 0
	var touched := {}
	var offsets := brush_offsets(
		int(p_params.get("size", 3)),
		str(p_params.get("shape_id", "square"))
	)
	for stamp_cell in interpolate_cells(p_from_cell, p_to_cell):
		stamps += 1
		for offset in offsets:
			touched[stamp_cell + offset] = true
		var result := apply_stamp(p_grid_map, stamp_cell, p_params)
		if not bool(result.get("ok", false)):
			return result
		added += int(result.get("added", 0))
		replaced += int(result.get("replaced", 0))
		erased += int(result.get("erased", 0))
		unchanged += int(result.get("unchanged", 0))
	return {
		"ok": true,
		"added": added,
		"replaced": replaced,
		"erased": erased,
		"unchanged": unchanged,
		"changed": added + replaced + erased,
		"stamps": stamps,
		"touched_cells": touched.size(),
		"used_cells": p_grid_map.get_used_cells().size(),
	}


static func brush_offsets(p_size: int, p_shape_id: String) -> Array[Vector3i]:
	var size_value := p_size if p_size in [1, 3, 5, 7] else 1
	var radius := int(size_value / 2)
	var result: Array[Vector3i] = []
	for z_offset in range(-radius, radius + 1):
		for x_offset in range(-radius, radius + 1):
			if (
				p_shape_id == "circle"
				and Vector2(x_offset, z_offset).length() > float(radius) + 0.35
			):
				continue
			result.append(Vector3i(x_offset, 0, z_offset))
	return result


static func interpolate_cells(
	p_from_cell: Vector3i,
	p_to_cell: Vector3i
) -> Array[Vector3i]:
	var delta := p_to_cell - p_from_cell
	var steps := maxi(abs(delta.x), maxi(abs(delta.y), abs(delta.z)))
	var result: Array[Vector3i] = []
	if steps <= 0:
		result.append(p_to_cell)
		return result
	for step in range(steps + 1):
		var weight := float(step) / float(steps)
		result.append(Vector3i(
			roundi(lerpf(float(p_from_cell.x), float(p_to_cell.x), weight)),
			roundi(lerpf(float(p_from_cell.y), float(p_to_cell.y), weight)),
			roundi(lerpf(float(p_from_cell.z), float(p_to_cell.z), weight))
		))
	return result


static func clear_terrain(p_grid_map: GridMap) -> Dictionary:
	if p_grid_map == null:
		return {"ok": true, "removed": 0}
	var removed := p_grid_map.get_used_cells().size()
	p_grid_map.clear()
	return {"ok": true, "removed": removed}


static func duplicate_grid_map(p_source: GridMap, p_owner: Node) -> Dictionary:
	if p_source == null:
		return {"ok": false, "error": "没有可复制的实体地形网格。"}
	if p_owner == null:
		return {"ok": false, "error": "复制实体地形需要有效的场景根节点。"}
	var source_cells := p_source.get_used_cells()
	if source_cells.is_empty():
		return {"ok": false, "error": "实体地形网格没有可复制的格子。"}
	var parent := p_source.get_parent()
	if parent == null:
		return {"ok": false, "error": "实体地形网格不在场景树中，无法复制。"}
	var source_library := p_source.mesh_library
	if source_library == null:
		return {"ok": false, "error": "实体地形网格缺少 MeshLibrary。"}
	var duplicate := GridMap.new()
	duplicate.name = _unique_copy_name(parent)
	parent.add_child(duplicate)
	duplicate.owner = p_owner
	duplicate.cell_size = p_source.cell_size
	duplicate.collision_layer = p_source.collision_layer
	duplicate.collision_mask = p_source.collision_mask
	duplicate.mesh_library = source_library.duplicate(true) as MeshLibrary
	duplicate.transform = p_source.transform
	var min_x := source_cells[0].x
	var max_x := source_cells[0].x
	for cell in source_cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		duplicate.set_cell_item(
			cell,
			p_source.get_cell_item(cell),
			p_source.get_cell_item_orientation(cell)
		)
	var source_meta = p_source.get_meta(META_KEY, {})
	duplicate.set_meta(
		META_KEY,
		source_meta.duplicate(true) if source_meta is Dictionary else {}
	)
	var span_x := float(max_x - min_x + 1) * p_source.cell_size.x
	var gap := maxf(GRID_SIZE, p_source.cell_size.x)
	duplicate.position = p_source.position + Vector3(span_x + gap, 0.0, 0.0)
	return {
		"ok": true,
		"grid_map": duplicate,
		"used_cells": duplicate.get_used_cells().size(),
		"offset_x": span_x + gap,
	}


static func is_terrain_grid_map(p_node: Node) -> bool:
	return p_node is GridMap and p_node.has_meta(META_KEY)


static func find_grid_map(p_root: Node, p_preferred_node: Node = null) -> GridMap:
	if p_root == null:
		return null
	var context_grid := _find_context_terrain_grid_map(p_root, p_preferred_node)
	if context_grid != null:
		return context_grid
	var terrain_parent := p_root.get_node_or_null(GROUP_TERRAIN)
	if terrain_parent != null:
		var legacy_grid := terrain_parent.get_node_or_null(GRID_MAP_NAME)
		if is_terrain_grid_map(legacy_grid):
			return legacy_grid as GridMap
	return _find_first_terrain_grid_map(p_root)


static func _find_context_terrain_grid_map(
	p_root: Node,
	p_preferred_node: Node
) -> GridMap:
	if (
		is_terrain_grid_map(p_preferred_node)
		and p_root != null
		and (p_preferred_node == p_root or p_root.is_ancestor_of(p_preferred_node))
	):
		return p_preferred_node as GridMap
	if (
		p_root == null
		or p_preferred_node == null
		or p_preferred_node == p_root
		or not p_root.is_ancestor_of(p_preferred_node)
	):
		return null
	var preferred_parent := _preferred_brush_parent(p_root as Node3D, p_preferred_node)
	if preferred_parent != null:
		var direct := _find_direct_terrain_grid_map(preferred_parent)
		if direct != null:
			return direct
	var nested := _find_first_terrain_grid_map(p_preferred_node)
	if nested != null:
		return nested
	if preferred_parent != null:
		return _find_first_terrain_grid_map(preferred_parent)
	return null


static func _preferred_brush_parent(p_root: Node3D, p_preferred_node: Node) -> Node3D:
	if p_root == null or p_preferred_node == null or p_preferred_node == p_root:
		return null
	if not p_root.is_ancestor_of(p_preferred_node):
		return null
	var parent := p_preferred_node.get_parent()
	while parent != null and parent != p_root:
		if parent is Node3D:
			return parent as Node3D
		parent = parent.get_parent()
	return p_root


static func _find_direct_terrain_grid_map(p_parent: Node) -> GridMap:
	if p_parent == null:
		return null
	for child in p_parent.get_children():
		if is_terrain_grid_map(child):
			return child as GridMap
	return null


static func _find_first_terrain_grid_map(p_node: Node) -> GridMap:
	if p_node == null:
		return null
	for child in p_node.get_children():
		if is_terrain_grid_map(child):
			return child as GridMap
	for child in p_node.get_children():
		var nested := _find_first_terrain_grid_map(child)
		if nested != null:
			return nested
	return null


static func _find_preset(p_preset_id: String) -> Dictionary:
	for entry in presets():
		if str(entry.get("id", "")) == p_preset_id:
			return entry
	return {}


static func _item_id_for_preset(p_preset_id: String) -> int:
	return _terrain_index_for_preset(p_preset_id)


static func _terrain_index_for_preset(p_preset_id: String) -> int:
	for index in range(TERRAINS.size()):
		if str(TERRAINS[index].get("id", "")) == p_preset_id:
			return index
	return INVALID_ITEM


static func _terrain_ids() -> Array[String]:
	var result: Array[String] = []
	for entry in TERRAINS:
		result.append(str(entry.get("id", "")))
	return result


static func _is_terrain_library(p_library: MeshLibrary) -> bool:
	if p_library == null:
		return false
	var items := p_library.get_item_list()
	for item_id in range(TERRAINS.size()):
		if (
			not items.has(item_id)
			or p_library.get_item_mesh(item_id) == null
			or p_library.get_item_shapes(item_id).is_empty()
		):
			return false
	return true


static func _unique_copy_name(p_parent: Node) -> String:
	var index := 1
	while true:
		var candidate := "FS_TERRAIN_BRUSH_COPY_%02d" % index
		if not p_parent.has_node(candidate):
			return candidate
		index += 1
	return "FS_TERRAIN_BRUSH_COPY"


static func _make_material(p_entry: Dictionary) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.from_string(
		str(p_entry.get("color", "#777777")),
		Color.WHITE
	)
	material.roughness = clampf(float(p_entry.get("roughness", 0.8)), 0.0, 1.0)
	material.metallic = 0.0
	return material


static func _assign_owner(p_node: Node, p_owner: Node) -> void:
	if p_node == null or p_owner == null:
		return
	p_node.owner = p_owner
