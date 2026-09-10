extends SceneTree

const Scaffold := preload("res://scripts/authoring/FSRegionScaffold.gd")
const RouteData := preload("res://scripts/v2/V2RouteData.gd")
const Manifest := preload("res://scripts/authoring/FSSceneManifest.gd")
const Runtime := preload("res://scripts/authoring/FSAuthoringRuntime.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var region := RouteData.load_region()
	if region.is_empty():
		push_error("无法读取默认 region JSON。")
		quit(1)
		return
	var region_id := str(region.get("region_id", "region"))
	var output_path := "res://authoring/scenes/%s_authoring.tscn" % region_id
	_ensure_project_dir(output_path.get_base_dir())

	var scene_root := Node3D.new()
	scene_root.name = "FS_REGION_%s" % region_id.to_upper()
	var result := Scaffold.build(scene_root, region, region_id)
	if result.has("error"):
		push_error(str(result["error"]))
		scene_root.free()
		quit(1)
		return
	_assign_owner(scene_root, scene_root)
	var manifest := Manifest.build(scene_root, output_path, region_id)
	var validation: Dictionary = manifest.get("validation", {})
	var errors: Array = validation.get("errors", [])
	if not errors.is_empty():
		push_error("作者场景清单校验失败：%s" % "; ".join(errors))
		scene_root.free()
		quit(1)
		return

	var packed := PackedScene.new()
	var pack_error := packed.pack(scene_root)
	if pack_error != OK:
		push_error("作者场景打包失败：%s" % error_string(pack_error))
		scene_root.free()
		quit(1)
		return
	var save_error := ResourceSaver.save(packed, output_path)
	scene_root.free()
	if save_error != OK:
		push_error("作者场景保存失败：%s" % error_string(save_error))
		quit(1)
		return
	var write_result := Manifest.write_manifest(manifest)
	if not bool(write_result.get("ok", false)):
		push_error(str(write_result.get("error", "作者清单写入失败。")))
		quit(1)
		return
	var publish_result := Runtime.publish(manifest, str(write_result.get("json_path", "")), output_path)
	if not bool(publish_result.get("ok", false)):
		push_error(str(publish_result.get("error", "作者场景发布失败。")))
		quit(1)
		return
	print("FS_AUTHORING_SCENE path=%s objects=%s props=%s decor=%s rest=%s binding=%s" % [
		output_path,
		int(manifest.get("object_count", 0)),
		int(result.get("props", 0)),
		int(result.get("decor", 0)),
		int(result.get("rest", 0)),
		str(publish_result.get("binding_path", "")),
	])
	quit(0)


func _assign_owner(p_node: Node, p_owner: Node) -> void:
	for child in p_node.get_children():
		child.owner = p_owner
		_assign_owner(child, p_owner)


func _ensure_project_dir(p_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p_path))
