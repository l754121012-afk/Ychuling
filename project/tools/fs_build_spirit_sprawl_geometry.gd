extends SceneTree

const Schema := preload("res://scripts/authoring/FSAuthoringSchema.gd")

const GENERATED_OUTPUT_PATH := "user://spirit_sprawl_geometry_6x_generated.tscn"
const REGION_ID := "spirit_sprawl_geometry"
const DISPLAY_NAME := "雨城灵潮六倍扩区审核"
const EXPANSION_FACTOR := 6
const FLOOR_THICKNESS := 0.6
const BRIDGE_THICKNESS := 0.5
const SHORE_HEIGHT := 0.9
const SHORE_THICKNESS := 0.28
const WORLD_WALL_HEIGHT := 2.6
const PLATFORM_SIDE_CELLS := 5
const STAIR_RISE := 0.12
const STAIR_RUN := 0.72
const PLATFORM_HEIGHT := STAIR_RISE * 2.0
const PLATFORM_HEIGHT_CELLS := 4
const PLATFORM_WIDTH_CELLS := 5
const ROOM_BUDGET_BASE := 3
const PLATFORM_BUDGET_BASE := 2
const PLATFORM_TARGET_COLUMNS := 2
const STRUCTURE_CELL_MARGIN := 1
const ROOM_WATER_GAP_CELLS := 2
const ROOM_MIN_RADIUS_CELLS := 5
const ROOM_MAX_RADIUS_CELLS := 20
const ROOM_BORDER_CELLS := 3
const SPAWN_CELL := Vector2i(68, 144)
const WORLD_X_MIN := -120.0
const WORLD_X_MAX := 120.0
const WORLD_Z_MIN := -79.2
const WORLD_Z_MAX := 79.2
const GRID_COLUMNS := 240
const GRID_ROWS := 156
const GRID_CELL_SIZE := Vector2(
	(WORLD_X_MAX - WORLD_X_MIN) / float(GRID_COLUMNS),
	(WORLD_Z_MAX - WORLD_Z_MIN) / float(GRID_ROWS)
)

# 行、列均按顶视图参考图换算。每个 Vector3i 表示“行、起始列、结束列”。
const ISLAND_DEFINITIONS := {
	"north_knot": {
		"display_name": "北中分叉陆区",
		"zone_id": "water_city_north_center",
		"color": "#66798b",
		"spans": [
			Vector3i(0, 18, 21),
			Vector3i(1, 18, 20),
			Vector3i(2, 18, 20),
			Vector3i(3, 18, 20),
			Vector3i(4, 15, 21),
			Vector3i(5, 14, 15),
			Vector3i(5, 20, 21),
			Vector3i(6, 14, 15),
			Vector3i(6, 20, 21),
			Vector3i(6, 24, 25),
			Vector3i(7, 14, 15),
			Vector3i(7, 18, 27),
			Vector3i(8, 14, 16),
			Vector3i(8, 18, 19),
			Vector3i(8, 22, 26),
			Vector3i(9, 15, 27),
			Vector3i(10, 16, 18),
			Vector3i(10, 22, 26),
			Vector3i(11, 23, 27),
			Vector3i(12, 25, 27),
			Vector3i(13, 26, 26),
			Vector3i(14, 26, 26),
			Vector3i(15, 26, 26),
			Vector3i(16, 25, 27),
			Vector3i(17, 25, 27),
			Vector3i(18, 24, 27),
			Vector3i(19, 24, 28),
			Vector3i(20, 24, 26),
			Vector3i(21, 25, 26),
		],
	},
	"east_mainland": {
		"display_name": "东岸连续主陆区",
		"zone_id": "water_city_east",
		"color": "#6d7d8d",
		"spans": [
			Vector3i(7, 35, 35),
			Vector3i(8, 32, 39),
			Vector3i(9, 28, 39),
			Vector3i(10, 27, 39),
			Vector3i(11, 30, 39),
			Vector3i(12, 29, 36),
			Vector3i(12, 38, 39),
			Vector3i(13, 30, 34),
		],
	},
	"northeast_lobe": {
		"display_name": "东北离岸枝块",
		"zone_id": "water_city_north_east",
		"color": "#778594",
		"spans": [
			Vector3i(0, 36, 39),
			Vector3i(1, 34, 39),
			Vector3i(2, 33, 36),
			Vector3i(2, 38, 39),
			Vector3i(3, 33, 36),
			Vector3i(4, 33, 36),
			Vector3i(5, 35, 36),
		],
	},
}

const BRIDGE_DEFINITIONS := {
	"br_north_east": {
		"display_name": "北东五格长桥",
		"zone_id": "water_city_north_center",
		"axis": "x",
		"cells": [Vector3i(8, 27, 31)],
		"links": ["north_knot", "east_mainland"],
	},
	"br_northeast_east": {
		"display_name": "东北双格竖桥",
		"zone_id": "water_city_north_east",
		"axis": "z",
		"cells": [Vector3i(6, 35, 35), Vector3i(7, 35, 35)],
		"links": ["northeast_lobe", "east_mainland"],
	},
}

const ROOM_SHAPE_PATTERNS := [
	[
		Vector2i(-2, -3), Vector2i(-2, -2), Vector2i(-2, 2),
		Vector2i(-1, -3), Vector2i(-1, -2), Vector2i(-1, 1), Vector2i(-1, 2),
		Vector2i(0, -3), Vector2i(0, -2), Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, -3), Vector2i(1, -1), Vector2i(1, 1),
		Vector2i(2, -3), Vector2i(2, -2), Vector2i(2, -1), Vector2i(2, 1),
	],
	[
		Vector2i(-2, -1), Vector2i(-2, 0), Vector2i(-2, 1), Vector2i(-2, 2),
		Vector2i(-1, -2), Vector2i(-1, -1), Vector2i(-1, 2),
		Vector2i(0, -3), Vector2i(0, -2), Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, -3), Vector2i(1, -2), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2),
		Vector2i(2, -3), Vector2i(2, -1), Vector2i(2, 0),
	],
	[
		Vector2i(-2, -2), Vector2i(-2, -1), Vector2i(-2, 0), Vector2i(-2, 1),
		Vector2i(-1, -3), Vector2i(-1, -2), Vector2i(-1, 1), Vector2i(-1, 2),
		Vector2i(0, -3), Vector2i(0, -2), Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, -3), Vector2i(1, -2), Vector2i(1, -1), Vector2i(1, 2),
		Vector2i(2, -2), Vector2i(2, -1), Vector2i(2, 1), Vector2i(2, 2),
	],
	[
		Vector2i(-1, -3), Vector2i(-1, -2), Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(-1, 2), Vector2i(-1, 3),
		Vector2i(0, -3), Vector2i(0, -2), Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3),
		Vector2i(1, -2), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2),
		Vector2i(2, -1), Vector2i(2, 0), Vector2i(2, 1),
	],
]

var scene_root: Node3D
var island_count := 0
var bridge_count := 0
var room_bridge_count := 0
var shore_segment_count := 0
var room_count := 0
var room_validation_error_count := 0
var platform_count := 0
var stair_step_count := 0
var cell_kinds := {}
var island_hosts := {}
var island_cells_by_id := {}
var island_boundaries_by_id := {}
var room_cells_by_id := {}
var island_structure_counts := {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	scene_root = Node3D.new()
	scene_root.name = "FS_REGION_SPIRIT_SPRAWL_GEOMETRY"
	root.add_child(scene_root)
	_mark_region_root()
	_build_water()
	_build_islands()
	_build_bridges()
	_build_interior_structures()
	_build_shore_walls()
	_build_world_walls()
	_build_spawn_marker()
	_refresh_region_metadata()
	_assign_owner(scene_root, scene_root)

	var packed := PackedScene.new()
	var pack_error := packed.pack(scene_root)
	if pack_error != OK:
		push_error("基础几何场景打包失败：%s" % error_string(pack_error))
		scene_root.free()
		quit(1)
		return
	var save_error := ResourceSaver.save(packed, GENERATED_OUTPUT_PATH)
	scene_root.free()
	if save_error != OK:
		push_error("基础几何场景保存失败：%s" % error_string(save_error))
		quit(1)
		return

	print(
		"FS_SPIRIT_SPRAWL_GEOMETRY path=%s expansion=%d islands=%d bridges=%d room_bridges=%d rooms=%d platforms=%d stair_steps=%d shore_walls=%d room_validation_errors=%d world_walls=4 errors=%d" % [
			GENERATED_OUTPUT_PATH,
			EXPANSION_FACTOR,
			island_count,
			bridge_count,
			room_bridge_count,
			room_count,
			platform_count,
			stair_step_count,
			shore_segment_count,
			room_validation_error_count,
			room_validation_error_count,
		]
	)
	print("FS_SPIRIT_SPRAWL_GEOMETRY_DISTRIBUTION %s" % _distribution_summary())
	quit(1 if room_validation_error_count > 0 else 0)


func _distribution_summary() -> String:
	var parts: Array[String] = []
	for raw_island_id in ISLAND_DEFINITIONS:
		var island_id := str(raw_island_id)
		var counts: Dictionary = island_structure_counts.get(island_id, {})
		parts.append("%s=rooms:%d,platforms:%d" % [
			island_id,
			int(counts.get("rooms", 0)),
			int(counts.get("platforms", 0)),
		])
	return " ".join(parts)


func _mark_region_root() -> void:
	var data := Schema.make(
		REGION_ID,
		"region",
		"none",
		REGION_ID,
		["base_geometry", "topology", "confirmed_top_view", "water_city"],
		[],
		{
			"source_image": "G:/好简历/项目原画/Snipaste_2026-09-12_12-52-19.png",
			"source_size_px": Vector2(521.0, 344.0),
			"world_bounds": [WORLD_X_MIN, WORLD_X_MAX, WORLD_Z_MIN, WORLD_Z_MAX],
			"authoring_scene": "res://authoring/scenes/spirit_sprawl_geometry.tscn",
			"scope": "islands_water_bridges_shore_walls_rooms_platforms_world_walls",
			"generation": {
				"expansion_factor": EXPANSION_FACTOR,
				"grid_columns": GRID_COLUMNS,
				"grid_rows": GRID_ROWS,
			},
		},
		DISPLAY_NAME
	)
	Schema.apply_to_node(scene_root, data)


func _build_water() -> void:
	var bed_size := Vector3(
		GRID_COLUMNS * GRID_CELL_SIZE.x - 0.2,
		0.12,
		GRID_ROWS * GRID_CELL_SIZE.y - 0.2
	)
	var surface_size := Vector3(bed_size.x - 0.2, 0.05, bed_size.z - 0.2)
	var host := _add_semantic_host(
		scene_root,
		"canal_water",
		"雨城水道",
		"decor",
		"none",
		REGION_ID,
		["topology", "water", "visual_only", "blocked"],
		[],
		{
			"walkable": false,
			"surface_y": -1.18,
			"shape": "full_world_base_carved_by_land",
		}
	)
	_add_box_visual(
		host,
		"WATER_BED",
		Vector3(0.0, -1.35, 0.0),
		bed_size,
		Color("#101820")
	)
	_add_box_visual(
		host,
		"WATER_SURFACE",
		Vector3(0.0, -1.18, 0.0),
		surface_size,
		Color(0.08, 0.18, 0.24, 0.78),
		true,
		0.18
	)


func _build_islands() -> void:
	for raw_island_id in ISLAND_DEFINITIONS:
		var island_id := str(raw_island_id)
		var definition: Dictionary = ISLAND_DEFINITIONS[island_id]
		var boxes: Array = []
		var cells := {}
		for raw_span in definition.get("spans", []):
			var span := _expand_span(raw_span)
			boxes.append(_flat_box_from_span(span))
			_mark_cells(span.x, span.y, span.z, island_id)
			for row in range(span.x, span.x + EXPANSION_FACTOR):
				for column in range(span.y, span.z + 1):
					cells[Vector2i(row, column)] = true
		island_cells_by_id[island_id] = cells
		island_boundaries_by_id[island_id] = _boundary_cells(cells)
		_add_island(
			island_id,
			str(definition.get("display_name", island_id)),
			str(definition.get("zone_id", REGION_ID)),
			Color(str(definition.get("color", "#66798b"))),
			boxes
		)


func _build_bridges() -> void:
	for raw_bridge_id in BRIDGE_DEFINITIONS:
		var bridge_id := str(raw_bridge_id)
		var definition: Dictionary = BRIDGE_DEFINITIONS[bridge_id]
		var cells: Array = definition.get("cells", [])
		if cells.is_empty():
			push_error("桥 %s 没有 cell 定义" % bridge_id)
			continue
		var min_col := 2147483647
		var max_col := -2147483648
		var min_row := 2147483647
		var max_row := -2147483648
		for raw_cell in cells:
			var cell := _expand_bridge_cell(raw_cell)
			min_col = mini(min_col, cell.y)
			max_col = maxi(max_col, cell.z)
			min_row = mini(min_row, cell.x)
			max_row = maxi(max_row, cell.x)
			_mark_cells(cell.x, cell.y, cell.z, bridge_id)
		var span_x := float(max_col - min_col + 1) * GRID_CELL_SIZE.x
		var span_z := float(max_row - min_row + 1) * GRID_CELL_SIZE.y
		var center := Vector3(
			WORLD_X_MIN + (float(min_col) + float(max_col + 1)) * 0.5 * GRID_CELL_SIZE.x,
			0.0,
			WORLD_Z_MIN + (float(min_row) + float(max_row + 1)) * 0.5 * GRID_CELL_SIZE.y
		)
		_add_bridge(
			bridge_id,
			str(definition.get("display_name", bridge_id)),
			str(definition.get("zone_id", REGION_ID)),
			center,
			Vector2(span_x, span_z),
			str(definition.get("axis", "x")),
			definition.get("links", [])
		)


func _build_interior_structures() -> void:
	_build_platforms()
	_build_offshore_rooms()
	_validate_room_separation()
	_build_room_bridges()
	_validate_room_connections()


func _build_platforms() -> void:
	var platform_budget := PLATFORM_BUDGET_BASE * EXPANSION_FACTOR
	for raw_island_id in ISLAND_DEFINITIONS:
		var island_id := str(raw_island_id)
		var definition: Dictionary = ISLAND_DEFINITIONS[island_id]
		var cells := _cells_from_spans(_expanded_spans(definition))
		if cells.is_empty():
			continue
		var zone_id := str(definition.get("zone_id", REGION_ID))
		var plan := _plan_island_platforms(cells, platform_budget)
		var platforms: Array = plan.get("platforms", [])
		for index in range(platforms.size()):
			_add_platform(island_id, index + 1, platforms[index], zone_id)
		island_structure_counts[island_id] = {
			"rooms": 0,
			"platforms": platforms.size(),
		}


func _plan_island_platforms(
	p_cells: Dictionary,
	p_platform_budget: int
) -> Dictionary:
	var bounds := _cell_bounds(p_cells)
	var platform_candidates := _rectangle_candidates(
		p_cells,
		PLATFORM_HEIGHT_CELLS,
		PLATFORM_WIDTH_CELLS,
		2,
		3,
		2,
		1
	)
	var platform_targets := _structure_targets(p_platform_budget, PLATFORM_TARGET_COLUMNS)
	var occupied := {}
	var platforms: Array[Dictionary] = []
	for index in range(platform_targets.size()):
		var platform_candidate := _pick_candidate(
			platform_candidates,
			_fraction_cell(bounds, platform_targets[index]),
			occupied
		)
		if platform_candidate.is_empty():
			continue
		platforms.append(platform_candidate)
		_occupy_rect(platform_candidate, occupied, STRUCTURE_CELL_MARGIN, 2)
	return {"platforms": platforms}


func _structure_targets(p_count: int, p_columns: int) -> Array[Vector2]:
	var targets: Array[Vector2] = []
	if p_count <= 0:
		return targets
	var columns := maxi(p_columns, 1)
	var rows := int(ceil(float(p_count) / float(columns)))
	var jitter := [
		Vector2(0.03, -0.02),
		Vector2(-0.03, 0.03),
		Vector2(0.02, 0.04),
		Vector2(-0.02, -0.03),
	]
	for index in range(p_count):
		var row := index / columns
		var column := index % columns
		var fraction := Vector2(
			(float(column) + 0.5) / float(columns),
			(float(row) + 0.5) / float(rows)
		)
		targets.append(fraction + jitter[index % jitter.size()])
	return targets


func _expand_span(p_span: Vector3i) -> Vector3i:
	return Vector3i(
		p_span.x * EXPANSION_FACTOR,
		p_span.y * EXPANSION_FACTOR,
		p_span.z * EXPANSION_FACTOR + EXPANSION_FACTOR - 1
	)


func _expand_bridge_cell(p_cell: Vector3i) -> Vector3i:
	return _expand_span(p_cell)


func _expanded_spans(p_definition: Dictionary) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for raw_span in p_definition.get("spans", []):
		var span: Vector3i = raw_span
		result.append(_expand_span(span))
	return result


func _cells_from_spans(p_spans: Array[Vector3i]) -> Dictionary:
	var cells := {}
	for span in p_spans:
		for row in range(span.x, span.x + EXPANSION_FACTOR):
			for column in range(span.y, span.z + 1):
				cells[Vector2i(row, column)] = true
	return cells


func _cell_bounds(p_cells: Dictionary) -> Dictionary:
	var row_min := 2147483647
	var row_max := -2147483648
	var column_min := 2147483647
	var column_max := -2147483648
	for raw_cell in p_cells:
		var cell: Vector2i = raw_cell
		row_min = mini(row_min, cell.x)
		row_max = maxi(row_max, cell.x)
		column_min = mini(column_min, cell.y)
		column_max = maxi(column_max, cell.y)
	return {
		"row_min": row_min,
		"row_max": row_max,
		"column_min": column_min,
		"column_max": column_max,
	}


func _rectangle_candidates(
	p_cells: Dictionary,
	p_rows: int,
	p_columns: int,
	p_step_rows: int,
	p_step_columns: int,
	p_extra_rows: int = 0,
	p_extra_column_inset: int = 0
) -> Array[Dictionary]:
	var bounds := _cell_bounds(p_cells)
	var candidates: Array[Dictionary] = []
	var first_row := int(bounds["row_min"])
	var last_row := int(bounds["row_max"]) - p_rows - p_extra_rows + 1
	var first_column := int(bounds["column_min"])
	var last_column := int(bounds["column_max"]) - p_columns + 1
	for row in range(first_row, last_row + 1, p_step_rows):
		for column in range(first_column, last_column + 1, p_step_columns):
			if not _rectangle_is_land(p_cells, row, p_rows, column, p_columns):
				continue
			if p_extra_rows > 0:
				var stair_columns := p_columns - p_extra_column_inset * 2
				if stair_columns <= 0:
					continue
				if not _rectangle_is_land(
					p_cells,
					row + p_rows,
					p_extra_rows,
					column + p_extra_column_inset,
					stair_columns
				):
					continue
			candidates.append({
				"row": row,
				"column": column,
				"rows": p_rows,
				"columns": p_columns,
			})
	return candidates


func _rectangle_is_land(
	p_cells: Dictionary,
	p_row: int,
	p_rows: int,
	p_column: int,
	p_columns: int
) -> bool:
	for row in range(p_row, p_row + p_rows):
		for column in range(p_column, p_column + p_columns):
			if not p_cells.has(Vector2i(row, column)):
				return false
	return true


func _fraction_cell(p_bounds: Dictionary, p_fraction: Vector2) -> Vector2i:
	var row := int(round(lerpf(
		float(p_bounds["row_min"]),
		float(p_bounds["row_max"]),
		clampf(p_fraction.y, 0.0, 1.0)
	)))
	var column := int(round(lerpf(
		float(p_bounds["column_min"]),
		float(p_bounds["column_max"]),
		clampf(p_fraction.x, 0.0, 1.0)
	)))
	return Vector2i(row, column)


func _pick_candidate(
	p_candidates: Array[Dictionary],
	p_target: Vector2i,
	p_occupied: Dictionary
) -> Dictionary:
	var best := {}
	var best_distance := INF
	for candidate in p_candidates:
		if not _candidate_is_free(candidate, p_occupied):
			continue
		var center_row := float(candidate["row"]) + float(candidate["rows"]) * 0.5
		var center_column := float(candidate["column"]) + float(candidate["columns"]) * 0.5
		var delta := Vector2(center_column - p_target.y, center_row - p_target.x)
		var distance := delta.length_squared()
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func _candidate_is_free(p_candidate: Dictionary, p_occupied: Dictionary) -> bool:
	var first_row := int(p_candidate["row"]) - STRUCTURE_CELL_MARGIN
	var last_row := int(p_candidate["row"]) + int(p_candidate["rows"]) + STRUCTURE_CELL_MARGIN
	var first_column := int(p_candidate["column"]) - STRUCTURE_CELL_MARGIN
	var last_column := int(p_candidate["column"]) + int(p_candidate["columns"]) + STRUCTURE_CELL_MARGIN
	for row in range(first_row, last_row):
		for column in range(first_column, last_column):
			if p_occupied.has(Vector2i(row, column)):
				return false
	return true


func _occupy_rect(
	p_rect: Dictionary,
	p_occupied: Dictionary,
	p_margin: int,
	p_extra_rows: int
) -> void:
	var first_row := int(p_rect["row"]) - p_margin
	var last_row := int(p_rect["row"]) + int(p_rect["rows"]) + p_extra_rows + p_margin
	var first_column := int(p_rect["column"]) - p_margin
	var last_column := int(p_rect["column"]) + int(p_rect["columns"]) + p_margin
	for row in range(first_row, last_row):
		for column in range(first_column, last_column):
			p_occupied[Vector2i(row, column)] = true


func _build_offshore_rooms() -> void:
	var room_budget := ROOM_BUDGET_BASE * EXPANSION_FACTOR
	var island_ids: Array = ISLAND_DEFINITIONS.keys()
	if island_ids.is_empty():
		return
	var base_count := room_budget / island_ids.size()
	var remainder := room_budget % island_ids.size()
	var global_index := 0
	for island_offset in range(island_ids.size()):
		var island_id := str(island_ids[island_offset])
		var definition: Dictionary = ISLAND_DEFINITIONS[island_id]
		var target_count := base_count + (1 if island_offset < remainder else 0)
		var boundary_cells: Array = island_boundaries_by_id.get(island_id, [])
		var island_cells: Dictionary = island_cells_by_id.get(island_id, {})
		if boundary_cells.is_empty() or island_cells.is_empty():
			global_index += target_count
			continue
		var entry: Dictionary = island_structure_counts.get(island_id, {"rooms": 0, "platforms": 0})
		for local_index in range(target_count):
			var placement := _find_room_placement(
				boundary_cells,
				island_cells,
				local_index,
				target_count,
				island_offset,
				global_index
			)
			global_index += 1
			if placement.is_empty():
				continue
			var room_index := int(entry.get("rooms", 0)) + 1
			var semantic_id := "room_%s_%d" % [island_id, room_index]
			var cells: Array[Vector2i] = placement["cells"]
			_add_room_plate(
				semantic_id,
				room_index,
				cells,
				str(definition.get("zone_id", REGION_ID))
			)
			room_cells_by_id[semantic_id] = cells
			entry["rooms"] = room_index
		island_structure_counts[island_id] = entry


func _find_room_placement(
	p_boundary_cells: Array,
	p_island_cells: Dictionary,
	p_local_index: int,
	p_target_count: int,
	p_island_offset: int,
	p_global_index: int
) -> Dictionary:
	var centroid := _cell_centroid(p_island_cells)
	var target_angle := TAU * (
		float(p_local_index) / float(maxi(p_target_count, 1))
		+ 0.137 * float(p_island_offset)
	)
	var preferred_radius := float(ROOM_MIN_RADIUS_CELLS + (p_local_index % 3) * 3)
	var pattern: Array = ROOM_SHAPE_PATTERNS[p_global_index % ROOM_SHAPE_PATTERNS.size()]
	var mirrored := (p_global_index % 2) == 1
	var best := {}
	var best_score := INF
	var seen_centers := {}
	for raw_boundary in p_boundary_cells:
		var boundary: Vector2i = raw_boundary
		var outward := Vector2(
			float(boundary.y - centroid.y),
			float(boundary.x - centroid.x)
		)
		if outward.length_squared() < 0.001:
			continue
		outward = outward.normalized()
		var boundary_angle := atan2(outward.y, outward.x)
		var angle_error := absf(wrapf(boundary_angle - target_angle, -PI, PI))
		var quarter_turns := wrapi(
			int(round((boundary_angle + PI * 0.5) / (PI * 0.5))),
			0,
			4
		)
		for radius in range(ROOM_MIN_RADIUS_CELLS, ROOM_MAX_RADIUS_CELLS + 1):
			var center := Vector2i(
				boundary.x + int(round(outward.y * float(radius))),
				boundary.y + int(round(outward.x * float(radius)))
			)
			if seen_centers.has(center):
				continue
			seen_centers[center] = true
			var cells := _room_cells_at(center, pattern, quarter_turns, mirrored)
			if cells.is_empty() or not _room_shape_is_clear(cells, p_island_cells):
				continue
			var score := (
				angle_error * 42.0
				+ absf(float(radius) - preferred_radius)
			)
			if score < best_score:
				best_score = score
				best = {
					"cells": cells,
					"center": center,
					"boundary": boundary,
					"radius": radius,
				}
	return best


func _room_cells_at(
	p_center: Vector2i,
	p_pattern: Array,
	p_quarter_turns: int,
	p_mirrored: bool
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for raw_offset in p_pattern:
		var offset: Vector2i = raw_offset
		var row := offset.x
		var column := offset.y
		if p_mirrored:
			column = -column
		for _turn in range(p_quarter_turns):
			var previous_row := row
			row = column
			column = -previous_row
		cells.append(p_center + Vector2i(row, column))
	return cells


func _room_shape_is_clear(
	p_cells: Array[Vector2i],
	p_island_cells: Dictionary
) -> bool:
	for cell in p_cells:
		if (
			cell.x < ROOM_BORDER_CELLS
			or cell.x >= GRID_ROWS - ROOM_BORDER_CELLS
			or cell.y < ROOM_BORDER_CELLS
			or cell.y >= GRID_COLUMNS - ROOM_BORDER_CELLS
		):
			return false
		for row_offset in range(-ROOM_WATER_GAP_CELLS, ROOM_WATER_GAP_CELLS + 1):
			for column_offset in range(-ROOM_WATER_GAP_CELLS, ROOM_WATER_GAP_CELLS + 1):
				var neighbor := cell + Vector2i(row_offset, column_offset)
				if cell_kinds.has(neighbor):
					return false
	return true


func _add_room_plate(
	p_semantic_id: String,
	p_index: int,
	p_cells: Array[Vector2i],
	p_zone_id: String
) -> void:
	var lookup := {}
	var sorted_cells: Array[Vector2i] = p_cells.duplicate()
	sorted_cells.sort()
	for cell in sorted_cells:
		lookup[cell] = true
		cell_kinds[cell] = p_semantic_id
	var bounds := _cell_bounds(lookup)
	var min_x := WORLD_X_MIN + float(bounds["column_min"]) * GRID_CELL_SIZE.x
	var max_x := WORLD_X_MIN + float(int(bounds["column_max"]) + 1) * GRID_CELL_SIZE.x
	var min_z := WORLD_Z_MIN + float(bounds["row_min"]) * GRID_CELL_SIZE.y
	var max_z := WORLD_Z_MIN + float(int(bounds["row_max"]) + 1) * GRID_CELL_SIZE.y
	var center := Vector3((min_x + max_x) * 0.5, 0.0, (min_z + max_z) * 0.5)
	var host := _add_semantic_host(
		scene_root,
		p_semantic_id,
		"离岸地形房间 %d" % p_index,
		"floor",
		"none",
		p_zone_id,
		["topology", "terrain_plate", "room", "generated_structure", "offshore"],
		[],
		{
			"surface_y": 0.0,
			"thickness": FLOOR_THICKNESS,
			"shape": "irregular_terrain_plate",
			"grid_rect": [
				int(bounds["row_min"]),
				int(bounds["column_min"]),
				int(bounds["row_max"]) - int(bounds["row_min"]) + 1,
				int(bounds["column_max"]) - int(bounds["column_min"]) + 1,
			],
			"grid_cells": sorted_cells,
			"water_gap_cells": ROOM_WATER_GAP_CELLS,
		}
	)
	var body := StaticBody3D.new()
	body.name = "SURFACE_%s" % p_semantic_id.to_upper()
	host.add_child(body)
	_add_cell_runs_static(body, lookup, FLOOR_THICKNESS, Color("#66798b"), "ROOM_FLOOR")
	_add_zone_label(host, "地形房间 %d" % p_index, center)
	room_count += 1


func _validate_room_separation() -> void:
	for raw_room_id in room_cells_by_id:
		var room_id := str(raw_room_id)
		var cells: Array[Vector2i] = room_cells_by_id[room_id]
		for cell in cells:
			for row_offset in range(-ROOM_WATER_GAP_CELLS, ROOM_WATER_GAP_CELLS + 1):
				for column_offset in range(-ROOM_WATER_GAP_CELLS, ROOM_WATER_GAP_CELLS + 1):
					if row_offset == 0 and column_offset == 0:
						continue
					var neighbor := cell + Vector2i(row_offset, column_offset)
					if not cell_kinds.has(neighbor):
						continue
					var neighbor_kind := str(cell_kinds[neighbor])
					if neighbor_kind == room_id:
						continue
					if neighbor_kind.begins_with("br_"):
						continue
					room_validation_error_count += 1


func _build_room_bridges() -> void:
	var room_ids: Array = room_cells_by_id.keys()
	room_ids.sort()
	for raw_room_id in room_ids:
		var room_id := str(raw_room_id)
		var island_id := _room_island_id(room_id)
		var island_cells: Dictionary = island_cells_by_id.get(island_id, {})
		var room_cells: Array[Vector2i] = room_cells_by_id[room_id]
		var bridge := _find_room_bridge(room_id, room_cells, island_cells)
		if bridge.is_empty():
			room_validation_error_count += 1
			continue
		_add_room_bridge(room_id, island_id, bridge["cells"])


func _validate_room_connections() -> void:
	var orthogonal_neighbors := [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
	]
	for raw_room_id in room_cells_by_id:
		var room_id := str(raw_room_id)
		var own_bridge_id := "br_%s" % room_id
		for raw_cell in room_cells_by_id[room_id]:
			var cell: Vector2i = raw_cell
			for direction in orthogonal_neighbors:
				var neighbor: Vector2i = cell + direction
				if not cell_kinds.has(neighbor):
					continue
				var neighbor_kind := str(cell_kinds[neighbor])
				if neighbor_kind == room_id or neighbor_kind == own_bridge_id:
					continue
				if neighbor_kind.begins_with("room_") or neighbor_kind.begins_with("br_"):
					room_validation_error_count += 1


func _find_room_bridge(
	p_room_id: String,
	p_room_cells: Array[Vector2i],
	p_island_cells: Dictionary
) -> Dictionary:
	var room_lookup := {}
	for cell in p_room_cells:
		room_lookup[cell] = true
	var best := {}
	var best_distance := 2147483647
	for raw_room_cell in p_room_cells:
		var room_cell: Vector2i = raw_room_cell
		for raw_island_cell in p_island_cells:
			var island_cell: Vector2i = raw_island_cell
			var distance := absi(room_cell.x - island_cell.x) + absi(room_cell.y - island_cell.y)
			if distance < 2 or distance > best_distance:
				continue
			for row_first in [true, false]:
				var path := _orthogonal_bridge_path(room_cell, island_cell, row_first)
				if (
					path.is_empty()
					or not _bridge_path_is_clear(
						path,
						p_room_id,
						room_lookup,
						p_island_cells
					)
				):
					continue
				if distance < best_distance:
					best_distance = distance
					best = {
						"cells": path,
						"distance": distance,
						"room_cell": room_cell,
						"island_cell": island_cell,
					}
	return best


func _orthogonal_bridge_path(
	p_from: Vector2i,
	p_to: Vector2i,
	p_row_first: bool
) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var cursor := p_from
	if p_row_first:
		while cursor.x != p_to.x:
			cursor.x += signi(p_to.x - cursor.x)
			if cursor != p_to:
				path.append(cursor)
		while cursor.y != p_to.y:
			cursor.y += signi(p_to.y - cursor.y)
			if cursor != p_to:
				path.append(cursor)
		return path
	while cursor.y != p_to.y:
		cursor.y += signi(p_to.y - cursor.y)
		if cursor != p_to:
			path.append(cursor)
	while cursor.x != p_to.x:
		cursor.x += signi(p_to.x - cursor.x)
		if cursor != p_to:
			path.append(cursor)
	return path


func _bridge_path_is_clear(
	p_path: Array[Vector2i],
	p_room_id: String,
	p_room_lookup: Dictionary,
	p_island_cells: Dictionary
) -> bool:
	var orthogonal_neighbors := [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
	]
	for cell in p_path:
		if p_room_lookup.has(cell) or p_island_cells.has(cell):
			return false
		if cell_kinds.has(cell):
			return false
		if (
			cell.x < 1
			or cell.x >= GRID_ROWS - 1
			or cell.y < 1
			or cell.y >= GRID_COLUMNS - 1
		):
			return false
		for direction in orthogonal_neighbors:
			var neighbor_kind := str(cell_kinds.get(cell + direction, ""))
			if neighbor_kind.is_empty():
				continue
			if neighbor_kind == p_room_id:
				continue
			if neighbor_kind.begins_with("room_") or neighbor_kind.begins_with("br_"):
				return false
	return true


func _add_room_bridge(
	p_room_id: String,
	p_island_id: String,
	p_cells: Array[Vector2i]
) -> void:
	var bridge_id := "br_%s" % p_room_id
	var lookup := {}
	var sorted_cells: Array[Vector2i] = p_cells.duplicate()
	sorted_cells.sort()
	for cell in sorted_cells:
		lookup[cell] = true
		cell_kinds[cell] = bridge_id
	var host := _add_semantic_host(
		scene_root,
		bridge_id,
		"房间连接桥 %s" % p_room_id.trim_prefix("room_"),
		"floor",
		"none",
		REGION_ID,
		["topology", "bridge", "generated_structure", "room_connection"],
		[p_room_id, p_island_id],
		{
			"surface_y": 0.0,
			"width": GRID_CELL_SIZE.x,
			"length_cells": sorted_cells.size(),
			"axis": "mixed",
			"connection_cells": sorted_cells,
		}
	)
	var body := StaticBody3D.new()
	body.name = "SURFACE_%s" % bridge_id.to_upper()
	host.add_child(body)
	_add_cell_runs_static(body, lookup, BRIDGE_THICKNESS, Color("#6b6a63"), "BRIDGE_DECK")
	bridge_count += 1
	room_bridge_count += 1


func _room_island_id(p_room_id: String) -> String:
	for island_id in ISLAND_DEFINITIONS:
		if p_room_id.begins_with("room_%s_" % str(island_id)):
			return str(island_id)
	return ""


func _boundary_cells(p_cells: Dictionary) -> Array:
	var result: Array = []
	var directions := [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
	]
	for raw_cell in p_cells:
		var cell: Vector2i = raw_cell
		for direction in directions:
			if not p_cells.has(cell + direction):
				result.append(cell)
				break
	result.sort()
	return result


func _cell_centroid(p_cells: Dictionary) -> Vector2:
	var total := Vector2.ZERO
	for raw_cell in p_cells:
		var cell: Vector2i = raw_cell
		total += Vector2(float(cell.y), float(cell.x))
	return total / float(maxi(p_cells.size(), 1))


func _add_cell_runs_static(
	p_body: StaticBody3D,
	p_cells: Dictionary,
	p_thickness: float,
	p_color: Color,
	p_prefix: String
) -> void:
	var rows := {}
	for raw_cell in p_cells:
		var cell: Vector2i = raw_cell
		if not rows.has(cell.x):
			rows[cell.x] = []
		rows[cell.x].append(cell.y)
	var row_keys: Array = rows.keys()
	row_keys.sort()
	var part_index := 0
	for raw_row in row_keys:
		var row := int(raw_row)
		var runs := _merge_cell_runs(rows[row])
		for run in runs:
			var cell_count := run.y - run.x + 1
			var center_x := WORLD_X_MIN + (float(run.x) + float(cell_count) * 0.5) * GRID_CELL_SIZE.x
			var center_z := WORLD_Z_MIN + (float(row) + 0.5) * GRID_CELL_SIZE.y
			_add_static_box(
				p_body,
				"%s_%02d" % [p_prefix, part_index],
				Vector3(center_x, -p_thickness * 0.5, center_z),
				Vector3(float(cell_count) * GRID_CELL_SIZE.x, p_thickness, GRID_CELL_SIZE.y),
				p_color
			)
			part_index += 1


func _add_platform(
	p_island_id: String,
	p_index: int,
	p_rect: Dictionary,
	p_zone_id: String
) -> void:
	var semantic_id := "platform_%s_%d" % [p_island_id, p_index]
	var host := _add_semantic_host(
		scene_root,
		semantic_id,
		"低平台 %d" % p_index,
		"floor",
		"none",
		p_zone_id,
		["interior", "platform", "raised", "generated_structure"],
		[],
		{
			"surface_y": PLATFORM_HEIGHT,
			"stair_rise": STAIR_RISE,
			"grid_rect": [
				int(p_rect["row"]),
				int(p_rect["column"]),
				int(p_rect["rows"]),
				int(p_rect["columns"]),
			],
		}
	)
	var body := StaticBody3D.new()
	body.name = "SUPPORT_%s" % semantic_id.to_upper()
	host.add_child(body)
	var min_x := WORLD_X_MIN + float(p_rect["column"]) * GRID_CELL_SIZE.x
	var max_x := WORLD_X_MIN + float(int(p_rect["column"]) + int(p_rect["columns"])) * GRID_CELL_SIZE.x
	var min_z := WORLD_Z_MIN + float(p_rect["row"]) * GRID_CELL_SIZE.y
	var max_z := WORLD_Z_MIN + float(int(p_rect["row"]) + int(p_rect["rows"])) * GRID_CELL_SIZE.y
	var width := max_x - min_x
	var depth := max_z - min_z
	var box_height := FLOOR_THICKNESS + PLATFORM_HEIGHT
	_add_static_box(
		body,
		"PLATFORM_DECK",
		Vector3(
			(min_x + max_x) * 0.5,
			(PLATFORM_HEIGHT - FLOOR_THICKNESS) * 0.5,
			(min_z + max_z) * 0.5
		),
		Vector3(width, box_height, depth),
		Color("#697782")
	)
	var step_count := int(round(PLATFORM_HEIGHT / STAIR_RISE))
	var step_width := maxf(width - 0.42, 0.8)
	for step_index in range(step_count):
		var step_height := STAIR_RISE * float(step_index + 1)
		var steps_from_platform := float(step_count - step_index)
		var step_center_z := max_z + STAIR_RUN * (steps_from_platform - 0.5)
		_add_static_box(
			body,
			"STAIR_STEP_%02d" % step_index,
			Vector3(
				(min_x + max_x) * 0.5,
				(step_height - FLOOR_THICKNESS) * 0.5,
				step_center_z
			),
			Vector3(step_width, FLOOR_THICKNESS + step_height, STAIR_RUN + 0.02),
			Color("#7b8791")
		)
		stair_step_count += 1
	platform_count += 1


func _build_shore_walls() -> void:
	var color := Color("#2b343d")
	var horizontal_edges := {}
	var vertical_edges := {}
	for raw_cell in cell_kinds:
		var cell: Vector2i = raw_cell
		var kind := str(cell_kinds[cell])
		if kind.begins_with("br_"):
			continue
		if not _is_land(cell + Vector2i(-1, 0)):
			_append_edge(vertical_edges, cell.x, cell.y)
		if not _is_land(cell + Vector2i(1, 0)):
			_append_edge(vertical_edges, cell.x + 1, cell.y)
		if not _is_land(cell + Vector2i(0, -1)):
			_append_edge(horizontal_edges, cell.y, cell.x)
		if not _is_land(cell + Vector2i(0, 1)):
			_append_edge(horizontal_edges, cell.y + 1, cell.x)

	var horizontal_boundaries: Array = horizontal_edges.keys()
	horizontal_boundaries.sort()
	for raw_boundary in horizontal_boundaries:
		var boundary_row := int(raw_boundary)
		var fixed_z := WORLD_Z_MIN + float(boundary_row) * GRID_CELL_SIZE.y
		var runs := _merge_cell_runs(horizontal_edges[boundary_row])
		for run in runs:
			var start_x := WORLD_X_MIN + float(run.x) * GRID_CELL_SIZE.x
			var end_x := WORLD_X_MIN + float(run.y + 1) * GRID_CELL_SIZE.x
			var wall_name := "SHORE_H_R%02d_C%02d_C%02d" % [boundary_row, run.x, run.y]
			_add_axis_wall(
				scene_root,
				wall_name,
				false,
				fixed_z,
				start_x,
				end_x,
				SHORE_HEIGHT,
				SHORE_THICKNESS,
				color
			)
			shore_segment_count += 1

	var vertical_boundaries: Array = vertical_edges.keys()
	vertical_boundaries.sort()
	for raw_boundary in vertical_boundaries:
		var boundary_col := int(raw_boundary)
		var fixed_x := WORLD_X_MIN + float(boundary_col) * GRID_CELL_SIZE.x
		var runs := _merge_cell_runs(vertical_edges[boundary_col])
		for run in runs:
			var start_z := WORLD_Z_MIN + float(run.x) * GRID_CELL_SIZE.y
			var end_z := WORLD_Z_MIN + float(run.y + 1) * GRID_CELL_SIZE.y
			var wall_name := "SHORE_V_C%02d_R%02d_R%02d" % [boundary_col, run.x, run.y]
			_add_axis_wall(
				scene_root,
				wall_name,
				true,
				fixed_x,
				start_z,
				end_z,
				SHORE_HEIGHT,
				SHORE_THICKNESS,
				color
			)
			shore_segment_count += 1


func _mark_cells(p_row: int, p_start_col: int, p_end_col: int, p_kind: String) -> void:
	for row in range(p_row, p_row + EXPANSION_FACTOR):
		for column in range(p_start_col, p_end_col + 1):
			cell_kinds[Vector2i(row, column)] = p_kind


func _append_edge(p_edges: Dictionary, p_fixed: int, p_run_cell: int) -> void:
	if not p_edges.has(p_fixed):
		p_edges[p_fixed] = []
	p_edges[p_fixed].append(p_run_cell)


func _merge_cell_runs(p_cells: Array) -> Array[Vector2i]:
	var sorted_cells: Array = p_cells.duplicate()
	sorted_cells.sort()
	var runs: Array[Vector2i] = []
	if sorted_cells.is_empty():
		return runs
	var run_start := int(sorted_cells[0])
	var previous := run_start
	for index in range(1, sorted_cells.size()):
		var current := int(sorted_cells[index])
		if current == previous + 1:
			previous = current
			continue
		runs.append(Vector2i(run_start, previous))
		run_start = current
		previous = current
	runs.append(Vector2i(run_start, previous))
	return runs


func _is_land(p_cell: Vector2i) -> bool:
	if p_cell.x < 0 or p_cell.x >= GRID_ROWS:
		return true
	if p_cell.y < 0 or p_cell.y >= GRID_COLUMNS:
		return true
	return cell_kinds.has(p_cell)


func _build_world_walls() -> void:
	var color := Color("#232b35")
	_add_world_wall("wall_world_w", "世界边界西", true, WORLD_X_MIN - 0.3, WORLD_Z_MIN, WORLD_Z_MAX, color)
	_add_world_wall("wall_world_e", "世界边界东", true, WORLD_X_MAX + 0.3, WORLD_Z_MIN, WORLD_Z_MAX, color)
	_add_world_wall("wall_world_n", "世界边界北", false, WORLD_Z_MIN - 0.3, WORLD_X_MIN, WORLD_X_MAX, color)
	_add_world_wall("wall_world_s", "世界边界南", false, WORLD_Z_MAX + 0.3, WORLD_X_MIN, WORLD_X_MAX, color)


func _build_spawn_marker() -> void:
	var spawn_position := Vector3(
		WORLD_X_MIN + (float(SPAWN_CELL.y) + 0.5) * GRID_CELL_SIZE.x,
		0.0,
		WORLD_Z_MIN + (float(SPAWN_CELL.x) + 0.5) * GRID_CELL_SIZE.y
	)
	var host := _add_semantic_host(
		scene_root,
		"spawn",
		"玩家出生点",
		"spawn",
		"spawn",
		REGION_ID,
		["topology", "spawn", "generated_structure"],
		[],
		{
			"surface_y": 0.0,
			"grid_cell": [SPAWN_CELL.x, SPAWN_CELL.y],
		}
	)
	host.position = spawn_position
	_add_box_visual(
		host,
		"SPAWN_MARKER",
		Vector3(0.0, 0.035, 0.0),
		Vector3(0.72, 0.07, 0.72),
		Color("#f1d77a"),
		true,
		0.1
	)


func _refresh_region_metadata() -> void:
	var data := Schema.make(
		REGION_ID,
		"region",
		"none",
		REGION_ID,
		["base_geometry", "topology", "confirmed_top_view", "water_city", "expanded_6x"],
		[],
		{
			"source_image": "G:/好简历/项目原画/Snipaste_2026-09-12_12-52-19.png",
			"source_size_px": Vector2(521.0, 344.0),
			"world_bounds": [WORLD_X_MIN, WORLD_X_MAX, WORLD_Z_MIN, WORLD_Z_MAX],
			"authoring_scene": "res://authoring/scenes/spirit_sprawl_geometry.tscn",
			"scope": "islands_water_bridges_shore_walls_rooms_platforms_spawn_world_walls",
			"structure_counts": {
				"islands": island_count,
				"bridges": bridge_count,
				"room_bridges": room_bridge_count,
				"rooms": room_count,
				"room_validation_errors": room_validation_error_count,
				"platforms": platform_count,
				"stair_steps": stair_step_count,
				"shore_wall_segments": shore_segment_count,
				"world_walls": 4,
			},
			"structure_distribution": island_structure_counts,
			"generation": {
				"expansion_factor": EXPANSION_FACTOR,
				"grid_columns": GRID_COLUMNS,
				"grid_rows": GRID_ROWS,
				"grid_cell_size": GRID_CELL_SIZE,
			},
		},
		DISPLAY_NAME
	)
	Schema.apply_to_node(scene_root, data)


func _add_world_wall(
	p_id: String,
	p_display_name: String,
	p_vertical: bool,
	p_fixed: float,
	p_from: float,
	p_to: float,
	p_color: Color
) -> void:
	var host := _add_semantic_host(
		scene_root,
		p_id,
		p_display_name,
		"wall",
		"none",
		REGION_ID,
		["topology", "world_boundary", "blocked"],
		[],
		{"vertical": p_vertical, "fixed": p_fixed, "from": p_from, "to": p_to}
	)
	_add_axis_wall(
		host,
		p_id.to_upper(),
		p_vertical,
		p_fixed,
		p_from,
		p_to,
		WORLD_WALL_HEIGHT,
		0.6,
		p_color
	)


func _add_island(
	p_id: String,
	p_display_name: String,
	p_zone_id: String,
	p_color: Color,
	p_boxes: Array
) -> void:
	var host := _add_semantic_host(
		scene_root,
		p_id,
		p_display_name,
		"zone",
		"none",
		p_zone_id,
		["topology", "island", "base_geometry"],
		[],
		{"surface_y": 0.0, "thickness": FLOOR_THICKNESS, "shape": "flat_multi_box"}
	)
	var body := StaticBody3D.new()
	body.name = "SURFACE_%s" % p_id.to_upper()
	host.add_child(body)
	for index in range(p_boxes.size()):
		var box: Dictionary = p_boxes[index]
		_add_static_box(
			body,
			"FLOOR_%02d" % index,
			box.get("center", Vector3.ZERO),
			box.get("size", Vector3.ONE),
			p_color
		)
	_add_zone_label(host, p_display_name, _boxes_center(p_boxes))
	island_count += 1


func _add_bridge(
	p_id: String,
	p_display_name: String,
	p_zone_id: String,
	p_center: Vector3,
	p_deck_size: Vector2,
	p_axis: String,
	p_links: Array
) -> void:
	var axis := p_axis.to_lower()
	var length := p_deck_size.y if axis == "z" else p_deck_size.x
	var width := p_deck_size.x if axis == "z" else p_deck_size.y
	var host := _add_semantic_host(
		scene_root,
		p_id,
		p_display_name,
		"floor",
		"none",
		p_zone_id,
		["topology", "bridge", "base_geometry"],
		p_links,
		{
			"surface_y": 0.0,
			"width": width,
			"length": length,
			"axis": axis,
			"deck_size": p_deck_size,
		}
	)
	var body := StaticBody3D.new()
	body.name = "SURFACE_%s" % p_id.to_upper()
	host.add_child(body)
	var deck_size := Vector3(p_deck_size.x, BRIDGE_THICKNESS, p_deck_size.y)
	_add_static_box(
		body,
		"DECK",
		Vector3(p_center.x, -BRIDGE_THICKNESS * 0.5, p_center.z),
		deck_size,
		Color("#6b6a63")
	)
	_add_bridge_rails(host, p_center, p_deck_size, axis)
	bridge_count += 1


func _add_bridge_rails(
	p_parent: Node3D,
	p_center: Vector3,
	p_deck_size: Vector2,
	p_axis: String
) -> void:
	var rail_color := Color("#31363b")
	if p_axis == "z":
		_add_box_visual(
			p_parent,
			"RAIL_WEST",
			Vector3(p_center.x - p_deck_size.x * 0.5 + 0.08, 0.12, p_center.z),
			Vector3(0.12, 0.24, p_deck_size.y),
			rail_color
		)
		_add_box_visual(
			p_parent,
			"RAIL_EAST",
			Vector3(p_center.x + p_deck_size.x * 0.5 - 0.08, 0.12, p_center.z),
			Vector3(0.12, 0.24, p_deck_size.y),
			rail_color
		)
		return
	_add_box_visual(
		p_parent,
		"RAIL_NORTH",
		Vector3(p_center.x, 0.12, p_center.z - p_deck_size.y * 0.5 + 0.08),
		Vector3(p_deck_size.x, 0.24, 0.12),
		rail_color
	)
	_add_box_visual(
		p_parent,
		"RAIL_SOUTH",
		Vector3(p_center.x, 0.12, p_center.z + p_deck_size.y * 0.5 - 0.08),
		Vector3(p_deck_size.x, 0.24, 0.12),
		rail_color
	)


func _add_axis_wall(
	p_parent: Node3D,
	p_name: String,
	p_vertical: bool,
	p_fixed: float,
	p_from: float,
	p_to: float,
	p_height: float,
	p_thickness: float,
	p_color: Color
) -> void:
	var length := absf(p_to - p_from)
	if length <= 0.001:
		return
	var body := StaticBody3D.new()
	body.name = p_name
	p_parent.add_child(body)
	var midpoint := (p_from + p_to) * 0.5
	var center := Vector3.ZERO
	var size := Vector3.ZERO
	if p_vertical:
		center = Vector3(p_fixed, p_height * 0.5, midpoint)
		size = Vector3(p_thickness, p_height, length)
	else:
		center = Vector3(midpoint, p_height * 0.5, p_fixed)
		size = Vector3(length, p_height, p_thickness)
	_add_static_box(body, "BLOCK", center, size, p_color, 0.96)


func _add_semantic_host(
	p_parent: Node3D,
	p_id: String,
	p_display_name: String,
	p_kind: String,
	p_behavior: String,
	p_zone_id: String,
	p_tags: Array,
	p_links: Array,
	p_params: Dictionary
) -> Node3D:
	var host := Node3D.new()
	p_parent.add_child(host)
	var data := Schema.make(
		p_id,
		p_kind,
		p_behavior,
		p_zone_id,
		p_tags,
		p_links,
		p_params,
		p_display_name
	)
	data = Schema.apply_to_node(host, data)
	host.name = Schema.node_name(data)
	return host


func _flat_box_from_span(p_span: Vector3i) -> Dictionary:
	var width := float(p_span.z - p_span.y + 1) * GRID_CELL_SIZE.x
	var min_x := WORLD_X_MIN + float(p_span.y) * GRID_CELL_SIZE.x
	var max_x := WORLD_X_MIN + float(p_span.z + 1) * GRID_CELL_SIZE.x
	var min_z := WORLD_Z_MIN + float(p_span.x) * GRID_CELL_SIZE.y
	var max_z := WORLD_Z_MIN + float(p_span.x + EXPANSION_FACTOR) * GRID_CELL_SIZE.y
	return _flat_box(
		(min_x + max_x) * 0.5,
		(min_z + max_z) * 0.5,
		width,
		max_z - min_z
	)


func _flat_box(p_x: float, p_z: float, p_size_x: float, p_size_z: float) -> Dictionary:
	return {
		"center": Vector3(p_x, -FLOOR_THICKNESS * 0.5, p_z),
		"size": Vector3(p_size_x, FLOOR_THICKNESS, p_size_z),
	}


func _add_static_box(
	p_parent: StaticBody3D,
	p_name: String,
	p_center: Vector3,
	p_size: Vector3,
	p_color: Color,
	p_roughness: float = 0.9
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = p_name
	mesh_instance.position = p_center
	var normalized_size := p_size.max(Vector3(0.001, 0.001, 0.001))
	mesh_instance.scale = normalized_size
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var material := StandardMaterial3D.new()
	material.albedo_color = p_color
	material.roughness = p_roughness
	mesh.material = material
	mesh_instance.mesh = mesh
	p_parent.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	collision.name = "%s_COLLISION" % p_name
	collision.position = p_center
	collision.scale = normalized_size
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE
	collision.shape = shape
	p_parent.add_child(collision)


func _add_box_visual(
	p_parent: Node3D,
	p_name: String,
	p_center: Vector3,
	p_size: Vector3,
	p_color: Color,
	p_transparent: bool = false,
	p_metallic: float = 0.0
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = p_name
	mesh_instance.position = p_center
	mesh_instance.scale = p_size.max(Vector3(0.001, 0.001, 0.001))
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var material := StandardMaterial3D.new()
	material.albedo_color = p_color
	material.roughness = 0.22 if p_transparent else 0.9
	material.metallic = p_metallic
	if p_transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	mesh_instance.mesh = mesh
	p_parent.add_child(mesh_instance)


func _add_zone_label(p_parent: Node3D, p_text: String, p_center: Vector3) -> void:
	var label := Label3D.new()
	label.name = "REVIEW_LABEL"
	label.text = p_text
	label.position = p_center + Vector3(0.0, 0.12, 0.0)
	label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	label.modulate = Color("#f4e7c1")
	label.outline_modulate = Color("#18202a")
	label.outline_size = 12
	label.font_size = 48
	label.pixel_size = 0.01
	label.no_depth_test = true
	p_parent.add_child(label)


func _boxes_center(p_boxes: Array) -> Vector3:
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for value in p_boxes:
		var box: Dictionary = value
		var center: Vector3 = box.get("center", Vector3.ZERO)
		var size: Vector3 = box.get("size", Vector3.ONE)
		min_x = minf(min_x, center.x - size.x * 0.5)
		max_x = maxf(max_x, center.x + size.x * 0.5)
		min_z = minf(min_z, center.z - size.z * 0.5)
		max_z = maxf(max_z, center.z + size.z * 0.5)
	return Vector3((min_x + max_x) * 0.5, 0.0, (min_z + max_z) * 0.5)


func _assign_owner(p_node: Node, p_owner: Node) -> void:
	for child in p_node.get_children():
		child.owner = p_owner
		_assign_owner(child, p_owner)
