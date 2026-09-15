extends SceneTree

const SCENE_PATH := "res://authoring/scenes/spirit_sprawl_geometry.tscn"
const CONNECTIVITY_GROUP_NAME := "FS_GROUP_连通修正"
const TARGET_EDGES := [13, 24, 36, 39, 40, 46, 49, 51, 52, 60, 83, 89, 99, 108, 110, 121, 124, 134, 144, 166, 170, 176]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := (ResourceLoader.load(SCENE_PATH) as PackedScene).instantiate() as Node3D
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var group := scene.get_node(CONNECTIVITY_GROUP_NAME)
	var physics := scene.get_world_3d().direct_space_state
	for target_edge in TARGET_EDGES:
		var marker := _find_marker(group, target_edge)
		if marker == null:
			print("edge=%d missing" % target_edge)
			continue
		var from: Vector3 = marker.get_meta("connection_from")
		var to: Vector3 = marker.get_meta("connection_to")
		var x := (from.x + to.x) * 0.5
		var z := (from.z + to.z) * 0.5
		var query := PhysicsRayQueryParameters3D.create(Vector3(x, 3.0, z), Vector3(x, -3.0, z))
		query.collide_with_areas = false
		var hit := physics.intersect_ray(query)
		var collider_name := ""
		if not hit.is_empty() and hit.get("collider") is Node:
			collider_name = str((hit["collider"] as Node).get_path())
		print(
			"edge=%d name=%s pos=(%.4f,%.4f) hit=%s collider=%s transform=%s"
			% [
				target_edge,
				str(marker.name),
				x,
				z,
				str(hit.get("position", Vector3(0.0, INF, 0.0))),
				collider_name,
				str((marker as Node3D).global_transform),
			]
		)
	scene.queue_free()
	quit(0)


func _find_marker(node: Node, target_edge: int) -> Node:
	if bool(node.get_meta("v12_a_edge_marker", false)) and int(node.get_meta("edge_index", -1)) == target_edge:
		return node
	for child in node.get_children():
		var found := _find_marker(child, target_edge)
		if found != null:
			return found
	return null
