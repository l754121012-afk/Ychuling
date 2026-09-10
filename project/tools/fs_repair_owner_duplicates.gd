extends SceneTree

const SCENE_PATH := "res://authoring/scenes/first_night_authoring.tscn"
const VISUAL_PREFIX := "VISUAL_"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_path := SCENE_PATH
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		scene_path = user_args[0]
	if not FileAccess.file_exists(scene_path):
		push_error("找不到作者场景：%s" % scene_path)
		quit(1)
		return
	var packed := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_IGNORE
	) as PackedScene
	if packed == null:
		push_error("作者场景无法加载：%s" % scene_path)
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	var before_size := FileAccess.get_file_as_bytes(scene_path).size()
	var removed := _remove_duplicate_instance_children(scene, scene)
	var remaining := _count_duplicate_instance_children(scene, scene)
	if removed == 0:
		print("FS_OWNER_REPAIR removed=0 remaining=%d path=%s" % [remaining, scene_path])
		root.remove_child(scene)
		scene.free()
		quit(0 if remaining == 0 else 1)
		return

	var repaired := PackedScene.new()
	var pack_error := repaired.pack(scene)
	if pack_error != OK:
		push_error("修复后的作者场景打包失败：%s" % error_string(pack_error))
		root.remove_child(scene)
		scene.free()
		quit(1)
		return
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var backup_path := "%s.%s.owner-fix.bak" % [scene_path, stamp]
	var copy_error := DirAccess.copy_absolute(
		ProjectSettings.globalize_path(scene_path),
		ProjectSettings.globalize_path(backup_path)
	)
	if copy_error != OK:
		push_error("备份原作者场景失败：%s" % error_string(copy_error))
		root.remove_child(scene)
		scene.free()
		quit(1)
		return
	var save_error := ResourceSaver.save(repaired, scene_path)
	root.remove_child(scene)
	scene.free()
	if save_error != OK:
		push_error("保存修复后的作者场景失败：%s" % error_string(save_error))
		quit(1)
		return

	var verify_packed := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_IGNORE
	) as PackedScene
	if verify_packed == null:
		push_error("修复后的作者场景无法重新加载：%s" % scene_path)
		quit(1)
		return
	var verify_scene := verify_packed.instantiate()
	root.add_child(verify_scene)
	var verify_remaining := _count_duplicate_instance_children(verify_scene, verify_scene)
	root.remove_child(verify_scene)
	verify_scene.free()
	var after_size := FileAccess.get_file_as_bytes(scene_path).size()
	print(
		"FS_OWNER_REPAIR removed=%d remaining=%d before=%d after=%d backup=%s path=%s" % [
			removed,
			verify_remaining,
			before_size,
			after_size,
			backup_path,
			scene_path,
		]
	)
	quit(0 if verify_remaining == 0 else 1)


func _remove_duplicate_instance_children(p_node: Node, p_scene_root: Node) -> int:
	var removed := 0
	if (
		str(p_node.name).begins_with(VISUAL_PREFIX)
		and not str(p_node.scene_file_path).is_empty()
	):
		for child in p_node.get_children():
			if child.owner == p_scene_root:
				p_node.remove_child(child)
				child.free()
				removed += 1
	for child in p_node.get_children():
		removed += _remove_duplicate_instance_children(child, p_scene_root)
	return removed


func _count_duplicate_instance_children(p_node: Node, p_scene_root: Node) -> int:
	var count := 0
	if (
		str(p_node.name).begins_with(VISUAL_PREFIX)
		and not str(p_node.scene_file_path).is_empty()
	):
		for child in p_node.get_children():
			if child.owner == p_scene_root:
				count += 1
	for child in p_node.get_children():
		count += _count_duplicate_instance_children(child, p_scene_root)
	return count
