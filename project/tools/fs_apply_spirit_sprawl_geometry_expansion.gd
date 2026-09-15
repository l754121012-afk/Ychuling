extends SceneTree

const Schema := preload("res://scripts/authoring/FSAuthoringSchema.gd")

const SOURCE_PATH := "user://spirit_sprawl_geometry_6x_generated.tscn"
const TARGET_PATH := "res://authoring/scenes/spirit_sprawl_geometry.tscn"
const TERRAIN_GROUP_NAME := "FS_GROUP_地形"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source_packed := ResourceLoader.load(SOURCE_PATH) as PackedScene
	if source_packed == null:
		push_error("无法加载扩区生成场景：%s" % SOURCE_PATH)
		quit(1)
		return
	var target_packed := ResourceLoader.load(TARGET_PATH) as PackedScene
	if target_packed == null:
		push_error("无法加载正式审核场景：%s" % TARGET_PATH)
		quit(1)
		return

	var source := source_packed.instantiate() as Node3D
	var target := target_packed.instantiate() as Node3D
	if source == null or target == null:
		push_error("扩区合并需要两个 Node3D 场景根")
		quit(1)
		return
	root.add_child(source)
	root.add_child(target)

	var terrain_group := target.get_node_or_null(TERRAIN_GROUP_NAME) as Node3D
	if terrain_group == null:
		push_error("正式审核场景缺少分组：%s" % TERRAIN_GROUP_NAME)
		quit(1)
		return

	var replaced_children := terrain_group.get_child_count()
	for child in terrain_group.get_children():
		terrain_group.remove_child(child)
		child.free()

	var moved_children := 0
	for child in source.get_children():
		source.remove_child(child)
		terrain_group.add_child(child)
		_assign_owner(child, target)
		moved_children += 1

	var region_data := Schema.data_from_node(source)
	if not region_data.is_empty():
		Schema.apply_to_node(target, region_data)

	var packed := PackedScene.new()
	var pack_error := packed.pack(target)
	if pack_error != OK:
		push_error("扩区合并场景打包失败：%s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(packed, TARGET_PATH)
	if save_error != OK:
		push_error("扩区合并场景保存失败：%s" % error_string(save_error))
		quit(1)
		return

	print(
		"FS_APPLY_SPIRIT_SPRAWL_GEOMETRY_EXPANSION target=%s replaced_terrain=%d moved=%d errors=0" % [
			TARGET_PATH,
			replaced_children,
			moved_children,
		]
	)
	quit(0)


func _assign_owner(p_node: Node, p_owner: Node) -> void:
	p_node.owner = p_owner
	for child in p_node.get_children():
		_assign_owner(child, p_owner)
