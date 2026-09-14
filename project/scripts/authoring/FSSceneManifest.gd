class_name FSSceneManifest
extends RefCounted

const Schema := preload("res://scripts/authoring/FSAuthoringSchema.gd")
const DEFAULT_REGION_PATH := "res://content/route/first_night_region.json"
const DEFAULT_OUTPUT_ROOT := "res://authoring"


static func build(
	p_root: Node,
	p_scene_path: String,
	p_region_id: String = "",
	p_region_path: String = DEFAULT_REGION_PATH
) -> Dictionary:
	var objects: Array[Dictionary] = []
	_collect_objects(p_root, p_root, objects)
	objects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("node_path", "")) < str(b.get("node_path", ""))
	)

	var ids := {}
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var counts := {}
	var resolved_region_id := Schema.sanitize_token(p_region_id)
	if resolved_region_id.is_empty():
		resolved_region_id = _scene_region_id(p_root)
	for object in objects:
		var object_id := str(object.get("semantic_id", ""))
		var object_path := str(object.get("node_path", "."))
		var object_kind := str(object.get("kind", ""))
		if object_id.is_empty():
			errors.append("语义对象缺少 semantic_id：%s" % object_path)
		elif ids.has(object_id):
			errors.append("重复 semantic_id：%s（%s 与 %s）" % [object_id, str(ids[object_id]), object_path])
		else:
			ids[object_id] = object_path
		counts[object_kind] = int(counts.get(object_kind, 0)) + 1

	var known_zones := _load_zone_ids(p_region_path)
	if not resolved_region_id.is_empty():
		known_zones[resolved_region_id] = true
	for object in objects:
		var object_path := str(object.get("node_path", "."))
		var object_id := str(object.get("semantic_id", ""))
		var zone_id := str(object.get("zone_id", ""))
		if not zone_id.is_empty() and not known_zones.is_empty() and not known_zones.has(zone_id):
			warnings.append("zone_id 不在区域 JSON 中：%s -> %s" % [object_path, zone_id])
		for link in object.get("links", []):
			var link_id := str(link)
			if not link_id.is_empty() and not ids.has(link_id):
				errors.append("links 指向不存在的 semantic_id：%s -> %s" % [object_path, link_id])
		if str(object.get("kind", "")) not in Schema.kind_ids():
			errors.append("未知 kind：%s -> %s" % [object_path, str(object.get("kind", ""))])
		if str(object.get("behavior", "")) not in Schema.behavior_ids():
			errors.append("未知 behavior：%s -> %s" % [object_path, str(object.get("behavior", ""))])
		var expected_name := Schema.node_name(object)
		if str(object.get("node_name", "")) != expected_name:
			warnings.append("节点名未规范化：%s，建议 %s" % [object_path, expected_name])
		for group in Schema.groups(object):
			if not object.get("groups", []).has(group):
				warnings.append("缺少语义分组：%s -> %s" % [object_path, group])

	var manifest := {
		"schema_version": Schema.SCHEMA_VERSION,
		"generated_at": Time.get_datetime_string_from_system(),
		"scene_path": p_scene_path,
		"region_id": resolved_region_id,
		"object_count": objects.size(),
		"counts": counts,
		"objects": objects,
		"validation": {
			"errors": errors,
			"warnings": warnings,
		},
	}
	return manifest


static func write_manifest(p_manifest: Dictionary, p_output_root: String = DEFAULT_OUTPUT_ROOT) -> Dictionary:
	var scene_name := _scene_stem(str(p_manifest.get("scene_path", "scene")))
	var manifest_dir := p_output_root.path_join("manifests")
	var semantic_dir := p_output_root.path_join("semantic")
	_ensure_project_dir(manifest_dir)
	_ensure_project_dir(semantic_dir)

	var json_path := manifest_dir.path_join("%s.manifest.json" % scene_name)
	var markdown_path := semantic_dir.path_join("%s.md" % scene_name)
	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	if json_file == null:
		return {"ok": false, "error": "无法写入 %s" % json_path}
	json_file.store_string(JSON.stringify(p_manifest, "\t", true, true))
	json_file.close()

	var markdown_file := FileAccess.open(markdown_path, FileAccess.WRITE)
	if markdown_file == null:
		return {"ok": false, "error": "无法写入 %s" % markdown_path}
	markdown_file.store_string(to_markdown(p_manifest))
	markdown_file.close()
	return {"ok": true, "json_path": json_path, "markdown_path": markdown_path}


static func to_markdown(p_manifest: Dictionary) -> String:
	var lines: Array[String] = [
		"# FIVESTAR 作者场景清单",
		"",
		"- 场景：`%s`" % str(p_manifest.get("scene_path", "")),
		"- 区域：`%s`" % str(p_manifest.get("region_id", "")),
		"- 物件：`%d`" % int(p_manifest.get("object_count", 0)),
		"- 生成时间：`%s`" % str(p_manifest.get("generated_at", "")),
		"",
		"## 物件",
		"",
		"| 显示名 | semantic_id | kind | behavior | runtime | zone | 模型 / 事件 | 节点名 | tags/links |",
		"| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
	]
	for object in p_manifest.get("objects", []):
		var extras: Array[String] = []
		for tag in object.get("tags", []):
			extras.append("tag:%s" % str(tag))
		for link in object.get("links", []):
			extras.append("link:%s" % str(link))
		lines.append("| %s | `%s` | `%s` | `%s` | `%s` | `%s` | %s | `%s` | %s |" % [
			_escape_table(str(object.get("display_name", ""))),
			_escape_table(str(object.get("semantic_id", ""))),
			_escape_table(str(object.get("kind", ""))),
			_escape_table(str(object.get("behavior", ""))),
			_escape_table(str(object.get("runtime_support", "none"))),
			_escape_table(str(object.get("zone_id", ""))),
			_escape_table(_visual_summary(object)),
			_escape_table(str(object.get("node_name", ""))),
			_escape_table(", ".join(extras)),
		])
	lines.append("")
	lines.append("## 校验")
	lines.append("")
	var validation: Dictionary = p_manifest.get("validation", {})
	var errors: Array = validation.get("errors", [])
	var warnings: Array = validation.get("warnings", [])
	lines.append("- 错误：`%d`" % errors.size())
	lines.append("- 警告：`%d`" % warnings.size())
	for error in errors:
		lines.append("- ERROR: %s" % str(error))
	for warning in warnings:
		lines.append("- WARN: %s" % str(warning))
	lines.append("")
	return "\n".join(lines)


static func _collect_objects(p_root: Node, p_node: Node, p_objects: Array[Dictionary]) -> void:
	if p_node.has_meta(Schema.META_KEY):
		var data := Schema.data_from_node(p_node)
		var object := data.duplicate(true)
		var params: Dictionary = data.get("params", {})
		object["visual"] = params.get("visual", {}).duplicate(true) if params.get("visual", {}) is Dictionary else {}
		object["effect"] = params.get("effect", {}).duplicate(true) if params.get("effect", {}) is Dictionary else {}
		object["runtime_support"] = Schema.runtime_support_for(
			str(data.get("kind", "")),
			str(data.get("behavior", ""))
		)
		object["node_name"] = str(p_node.name)
		object["node_path"] = _safe_node_path(p_root, p_node)
		object["node_class"] = p_node.get_class()
		object["script_class"] = _script_class(p_node)
		object["scene_file_path"] = p_node.scene_file_path
		object["groups"] = _string_array(p_node.get_groups())
		object["transform"] = _transform_data(p_node)
		p_objects.append(object)
	for child in p_node.get_children():
		_collect_objects(p_root, child, p_objects)


static func _safe_node_path(p_root: Node, p_node: Node) -> String:
	if p_root == null or p_node == null:
		return ""
	if p_node == p_root:
		return "."
	var parts: Array[String] = []
	var current: Node = p_node
	while current != null and current != p_root:
		parts.append(str(current.name))
		current = current.get_parent()
	if current != p_root:
		return ""
	parts.reverse()
	return "/".join(parts)


static func _transform_data(p_node: Node) -> Dictionary:
	if not (p_node is Node3D):
		return {}
	var global_position: Vector3 = p_node.position
	if p_node.is_inside_tree():
		global_position = p_node.global_position
	else:
		var chain: Array[Node3D] = []
		var current := p_node as Node3D
		while current != null:
			chain.append(current)
			current = current.get_parent() as Node3D
		var accumulated := Transform3D.IDENTITY
		for index in range(chain.size() - 1, -1, -1):
			accumulated *= chain[index].transform
		global_position = accumulated.origin
	return {
		"local_position": _vector3_to_array(p_node.position),
		"global_position": _vector3_to_array(global_position),
		"rotation_degrees": _vector3_to_array(p_node.rotation_degrees),
		"scale": _vector3_to_array(p_node.scale),
	}


static func _vector3_to_array(p_value: Vector3) -> Array:
	return [p_value.x, p_value.y, p_value.z]


static func _script_class(p_node: Node) -> String:
	var script: Variant = p_node.get_script()
	if script == null:
		return ""
	if script is Script:
		return str(script.get_global_name())
	return ""


static func _scene_region_id(p_root: Node) -> String:
	var data := Schema.data_from_node(p_root)
	if str(data.get("kind", "")) == "region":
		return str(data.get("semantic_id", ""))
	return ""


static func _load_zone_ids(p_region_path: String) -> Dictionary:
	var result := {}
	if not FileAccess.file_exists(p_region_path):
		return result
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(p_region_path))
	if not (parsed is Dictionary):
		return result
	var region_id := str(parsed.get("region_id", ""))
	if not region_id.is_empty():
		result[region_id] = true
	for zone in parsed.get("zones", []):
		var zone_id := str(zone.get("id", ""))
		if not zone_id.is_empty():
			result[zone_id] = true
	return result


static func _scene_stem(p_scene_path: String) -> String:
	var file_name := p_scene_path.get_file()
	if file_name.is_empty():
		file_name = "scene"
	var stem := file_name.get_basename()
	return Schema.sanitize_token(stem)


static func _ensure_project_dir(p_path: String) -> void:
	var absolute := ProjectSettings.globalize_path(p_path)
	DirAccess.make_dir_recursive_absolute(absolute)


static func _string_array(p_values) -> Array[String]:
	var result: Array[String] = []
	for value in p_values:
		result.append(str(value))
	return result


static func _escape_table(p_text: String) -> String:
	return p_text.replace("|", "\\|").replace("\n", " ")


static func _visual_summary(p_object: Dictionary) -> String:
	var visual: Dictionary = p_object.get("visual", {})
	var effect: Dictionary = p_object.get("effect", {})
	var parts: Array[String] = []
	if not visual.is_empty():
		var label := str(visual.get("label", ""))
		var model_id := str(visual.get("model_id", ""))
		parts.append("%s (`%s`)" % [label, model_id] if not label.is_empty() and not model_id.is_empty() else label if not label.is_empty() else model_id)
	if not effect.is_empty():
		var effect_label := str(effect.get("label", ""))
		var effect_id := str(effect.get("effect_id", ""))
		parts.append("事件：%s" % ("%s (`%s`)" % [effect_label, effect_id] if not effect_label.is_empty() and not effect_id.is_empty() else effect_label if not effect_label.is_empty() else effect_id))
	return "；".join(parts)
