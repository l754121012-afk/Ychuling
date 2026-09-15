extends SceneTree

const Schema := preload("res://scripts/authoring/FSAuthoringSchema.gd")
const EnvironmentCatalog := preload("res://scripts/authoring/FSEnvironmentCatalog.gd")

const SCENE_PATH := "res://authoring/scenes/spirit_sprawl_geometry.tscn"
const GROUP_TERRAIN := "FS_GROUP_地形"
const GROUP_BUILDINGS := "FS_GROUP_建筑"
const GROUP_OBJECTS := "FS_GROUP_物件"
const GROUP_CHARACTERS := "FS_GROUP_角色"
const GROUP_EFFECTS := "FS_GROUP_特效"
const GROUP_NAMES := [
	GROUP_TERRAIN,
	GROUP_BUILDINGS,
	GROUP_OBJECTS,
	GROUP_CHARACTERS,
	GROUP_EFFECTS,
]
const EDITOR_LOCK_META := "_edit_lock_"
const TERRAIN_CATEGORIES := [
	"地形与平台",
	"城镇道路",
	"雨城水文",
	"围栏与墙",
	"地牢结构",
]
const BUILDING_CATEGORIES := [
	"门与出入口",
	"墓园建筑",
	"城镇建筑",
]
const CHARACTER_CATEGORIES := [
	"角色占位",
]
const TERRAIN_SEMANTIC_IDS := [
	"canal_water",
	"north_knot",
	"east_mainland",
	"northeast_lobe",
	"br_north_east",
	"br_northeast_east",
	"wall_world_w",
	"wall_world_e",
	"wall_world_n",
	"wall_world_s",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := ResourceLoader.load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("无法加载场景：%s" % SCENE_PATH)
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("场景根节点不是 Node3D。")
		return
	root.add_child(scene)

	var groups := {}
	for group_name in GROUP_NAMES:
		groups[group_name] = _ensure_group(scene, group_name)

	var moved := {}
	var candidates: Array[Node] = []
	for child in scene.get_children():
		if str(child.name) in GROUP_NAMES:
			continue
		candidates.append(child)
	for child in candidates:
		var group_name := _group_for_node(child)
		var group: Node3D = groups[group_name]
		var world_transform: Transform3D = child.global_transform if child is Node3D else Transform3D.IDENTITY
		child.reparent(group, true)
		if child is Node3D:
			(child as Node3D).global_transform = world_transform
		child.owner = scene
		moved[group_name] = int(moved.get(group_name, 0)) + 1

	var locked_terrain_nodes := _lock_generated_terrain(groups[GROUP_TERRAIN])

	var repacked := PackedScene.new()
	var pack_error := repacked.pack(scene)
	if pack_error != OK:
		_fail("打包场景失败：%s" % error_string(pack_error))
		return
	var save_error := ResourceSaver.save(repacked, SCENE_PATH)
	if save_error != OK:
		_fail("保存场景失败：%s" % error_string(save_error))
		return

	var parts: Array[String] = []
	for group_name in GROUP_NAMES:
		parts.append("%s=%d" % [group_name, int(moved.get(group_name, 0))])
	print(
		"SPIRIT_SPRAWL_GROUPS %s locked_terrain=%d errors=0" % [
			" ".join(parts),
			locked_terrain_nodes,
		]
	)
	scene.queue_free()
	quit(0)


func _ensure_group(p_root: Node3D, p_name: String) -> Node3D:
	var existing := p_root.get_node_or_null(NodePath(p_name)) as Node3D
	if existing:
		existing.owner = p_root
		return existing
	var group := Node3D.new()
	group.name = p_name
	p_root.add_child(group)
	group.owner = p_root
	return group


func _group_for_node(p_node: Node) -> String:
	if EnvironmentCatalog.is_environment_node(p_node):
		return GROUP_EFFECTS
	var data := Schema.data_from_node(p_node)
	var semantic_id := str(data.get("semantic_id", ""))
	var name := str(p_node.name)
	if TERRAIN_SEMANTIC_IDS.has(semantic_id):
		return GROUP_TERRAIN
	if (
		name.begins_with("SHORE_")
		or name.begins_with("FS_ZONE_")
		or name.begins_with("FS_FLOOR_")
		or name.begins_with("FS_PROP_世界边界")
		or name.begins_with("FS_DECOR_雨城水道")
	):
		return GROUP_TERRAIN
	var params: Dictionary = data.get("params", {}) if data.get("params", {}) is Dictionary else {}
	var visual: Dictionary = params.get("visual", {}) if params.get("visual", {}) is Dictionary else {}
	var category := str(visual.get("category", "")).strip_edges()
	var tags := Schema.string_array(data.get("tags", []))
	if _matches_category(category, tags, TERRAIN_CATEGORIES):
		return GROUP_TERRAIN
	if _matches_category(category, tags, BUILDING_CATEGORIES):
		return GROUP_BUILDINGS
	if _matches_category(category, tags, CHARACTER_CATEGORIES):
		return GROUP_CHARACTERS
	if str(data.get("kind", "")) in ["character", "npc"]:
		return GROUP_CHARACTERS
	if str(data.get("kind", "")) == "building":
		return GROUP_BUILDINGS
	return GROUP_OBJECTS


func _matches_category(p_category: String, p_tags: Array[String], p_categories: Array) -> bool:
	if p_categories.has(p_category):
		return true
	for tag in p_tags:
		if p_categories.has(tag):
			return true
	return false


func _lock_generated_terrain(p_group: Node) -> int:
	var locked_count := 0
	var pending: Array[Node] = [p_group]
	while not pending.is_empty():
		var node: Node = pending.pop_front()
		if node is GridMap:
			continue
		if node.owner != null:
			node.set_meta(EDITOR_LOCK_META, true)
			locked_count += 1
		for child in node.get_children():
			pending.append(child)
	return locked_count


func _fail(p_message: String) -> void:
	push_error(p_message)
	print("SPIRIT_SPRAWL_GROUPS errors=1")
	quit(1)
