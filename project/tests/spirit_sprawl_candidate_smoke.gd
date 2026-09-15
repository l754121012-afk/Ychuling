extends SceneTree

const Schema := preload("res://scripts/authoring/FSAuthoringSchema.gd")
const EnvironmentCatalog := preload("res://scripts/authoring/FSEnvironmentCatalog.gd")

const SCENE_PATH := "res://authoring/scenes/spirit_sprawl_candidate.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var packed := ResourceLoader.load(SCENE_PATH) as PackedScene
	ok = _expect(packed != null, "候选场景必须可加载：%s" % SCENE_PATH) and ok
	if packed == null:
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	ok = _expect(
		scene.name == "FS_REGION_SPIRIT_SPRAWL_CANDIDATE",
		"候选场景根节点名必须稳定：%s" % scene.name
	) and ok

	var stats := {
		"semantic": 0,
		"model_hosts": 0,
		"visuals": 0,
		"supports": 0,
		"environments": 0,
		"cameras": {},
	}
	var semantic_ids := {}
	var missing_names: Array[String] = []
	var duplicate_ids: Array[String] = []
	_collect(scene, stats, semantic_ids, missing_names, duplicate_ids)

	ok = _expect(int(stats["semantic"]) == 123, "候选场景应有 123 个语义节点，实际 %d" % int(stats["semantic"])) and ok
	ok = _expect(int(stats["model_hosts"]) == 112, "候选场景应有 112 个模型宿主，实际 %d" % int(stats["model_hosts"])) and ok
	ok = _expect(int(stats["visuals"]) == 112, "候选场景应有 112 个可见模型层，实际 %d" % int(stats["visuals"])) and ok
	ok = _expect(int(stats["supports"]) > 0, "候选场景必须生成可站立/阻挡的支撑碰撞") and ok
	ok = _expect(int(stats["environments"]) == 21, "候选场景应有 21 个环境特效层，实际 %d" % int(stats["environments"])) and ok
	ok = _expect(missing_names.is_empty(), "候选场景存在空中文显示名：%s" % ", ".join(missing_names)) and ok
	ok = _expect(duplicate_ids.is_empty(), "候选场景存在重复 semantic_id：%s" % ", ".join(duplicate_ids)) and ok

	var cameras: Dictionary = stats["cameras"]
	ok = _expect(
		cameras.has("preview_camera_game") and cameras.has("preview_camera_top_down"),
		"候选场景必须包含游戏透视和顶视正交两套预览相机"
	) and ok
	if cameras.has("preview_camera_game"):
		var game_camera := cameras["preview_camera_game"] as Camera3D
		ok = _expect(
			game_camera != null
			and game_camera.projection == Camera3D.PROJECTION_PERSPECTIVE,
			"preview_camera_game 必须是透视相机"
		) and ok
	if cameras.has("preview_camera_top_down"):
		var top_down_camera := cameras["preview_camera_top_down"] as Camera3D
		ok = _expect(
			top_down_camera != null
			and top_down_camera.projection == Camera3D.PROJECTION_ORTHOGONAL,
			"preview_camera_top_down 必须是正交相机"
		) and ok

	print("SPIRIT_SPRAWL_CANDIDATE semantic=%d model_hosts=%d visuals=%d supports=%d environments=%d errors=%d" % [
		int(stats["semantic"]),
		int(stats["model_hosts"]),
		int(stats["visuals"]),
		int(stats["supports"]),
		int(stats["environments"]),
		0 if ok else 1,
	])
	scene.queue_free()
	packed = null
	await process_frame
	await process_frame
	quit(0 if ok else 1)


func _collect(
	p_node: Node,
	p_stats: Dictionary,
	p_semantic_ids: Dictionary,
	p_missing_names: Array[String],
	p_duplicate_ids: Array[String]
) -> void:
	if p_node.has_meta(Schema.META_KEY):
		p_stats["semantic"] = int(p_stats["semantic"]) + 1
		var data := Schema.data_from_node(p_node)
		var semantic_id := str(data.get("semantic_id", ""))
		var display_name := str(data.get("display_name", ""))
		if semantic_id.is_empty() or p_semantic_ids.has(semantic_id):
			p_duplicate_ids.append(semantic_id)
		else:
			p_semantic_ids[semantic_id] = true
		if display_name.strip_edges().is_empty():
			p_missing_names.append(str(p_node.get_path()))
		if str(data.get("kind", "")) not in ["region", "zone", "camera"]:
			p_stats["model_hosts"] = int(p_stats["model_hosts"]) + 1
		if semantic_id.begins_with("preview_camera_"):
			p_stats["cameras"][semantic_id] = _find_camera(p_node)

	var node_name := str(p_node.name)
	if node_name.begins_with("VISUAL_"):
		p_stats["visuals"] = int(p_stats["visuals"]) + 1
	elif node_name.begins_with("SUPPORT_") and _has_collision_shape(p_node):
		p_stats["supports"] = int(p_stats["supports"]) + 1
	if EnvironmentCatalog.is_environment_node(p_node):
		p_stats["environments"] = int(p_stats["environments"]) + 1

	for child in p_node.get_children():
		_collect(child, p_stats, p_semantic_ids, p_missing_names, p_duplicate_ids)


func _find_camera(p_node: Node) -> Camera3D:
	if p_node is Camera3D:
		return p_node as Camera3D
	for child in p_node.get_children():
		var camera := _find_camera(child)
		if camera != null:
			return camera
	return null


func _has_collision_shape(p_node: Node) -> bool:
	if p_node is CollisionShape3D or p_node is CollisionPolygon3D:
		return true
	for child in p_node.get_children():
		if _has_collision_shape(child):
			return true
	return false


func _expect(p_condition: bool, p_message: String) -> bool:
	if not p_condition:
		push_error(p_message)
	return p_condition
