extends SceneTree

const DEFAULT_SCENE_PATH := "res://authoring/scenes/spirit_sprawl_geometry_cubes_v3_test.tscn"
const DEFAULT_OUTPUT_PATH := "C:/Users/李泽文/Documents/Codex/2026-09-13/godot/work/v3-footprints.json"
const TERRAIN_GROUP_NAME := "FS_GROUP_地形"

const KIND_PREFIXES := [
	"PLATFORM_DECK",
	"STAIR_STEP",
	"ROOM_FLOOR",
	"BRIDGE_DECK",
	"FLOOR",
	"DECK",
	"BLOCK",
	"WATER",
	"RAIL",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_path := DEFAULT_SCENE_PATH
	var output_path := DEFAULT_OUTPUT_PATH
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scene="):
			scene_path = argument.trim_prefix("--scene=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")

	var packed := ResourceLoader.load(scene_path) as PackedScene
	if packed == null:
		push_error("Unable to load scene: %s" % scene_path)
		quit(1)
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		push_error("Scene root is not Node3D: %s" % scene_path)
		quit(1)
		return
	root.add_child(scene)
	for _frame in range(2):
		await process_frame

	var terrain := scene.get_node_or_null(TERRAIN_GROUP_NAME)
	if terrain == null:
		push_error("Terrain group not found: %s" % TERRAIN_GROUP_NAME)
		quit(1)
		return

	var records: Array[Dictionary] = []
	_collect_meshes(terrain, records)
	var payload := {
		"scene": scene_path,
		"terrain_group": TERRAIN_GROUP_NAME,
		"records": records,
	}
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write JSON: %s" % output_path)
		quit(1)
		return
	file.store_string(JSON.stringify(payload, "  "))
	file.close()
	print("FS_EXPORT_FOOTPRINTS records=%d scene=%s output=%s errors=0" % [
		records.size(),
		scene_path,
		output_path,
	])
	quit(0)


func _collect_meshes(p_node: Node, p_records: Array[Dictionary]) -> void:
	if p_node is MeshInstance3D:
		var mesh_instance := p_node as MeshInstance3D
		if mesh_instance.mesh is BoxMesh:
			var aabb := mesh_instance.global_transform * mesh_instance.get_aabb()
			var record := {
				"name": str(mesh_instance.name),
				"kind": _kind(str(mesh_instance.name)),
				"center": _vector3_to_array(aabb.get_center()),
				"size": _vector3_to_array(aabb.size.abs()),
				"cube_role": str(mesh_instance.get_meta("fivestar_cube_role", "")),
				"source_kind": str(
					mesh_instance.get_meta("fivestar_cube_source_kind", "")
				),
				"source_name": str(
					mesh_instance.get_meta("fivestar_cube_source_name", "")
				),
			}
			p_records.append(record)
	for child in p_node.get_children():
		_collect_meshes(child, p_records)


func _kind(p_name: String) -> String:
	var upper := p_name.to_upper()
	for prefix in KIND_PREFIXES:
		if upper.begins_with(prefix) or upper.contains("_" + prefix + "_"):
			return prefix
	return "OTHER"


func _vector3_to_array(p_vector: Vector3) -> Array[float]:
	return [p_vector.x, p_vector.y, p_vector.z]
