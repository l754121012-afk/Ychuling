class_name FSAuthoringRuntime
extends RefCounted

const Schema := preload("res://scripts/authoring/FSAuthoringSchema.gd")
const GateScript := preload("res://scripts/v2/V2AbilityGate.gd")
const BreakableScript := preload("res://scripts/v2/V2Breakable.gd")
const PickupScript := preload("res://scripts/v2/V2AbilityPickup.gd")

const DEFAULT_SCENE_DIR := "res://authoring/scenes"
const DEFAULT_RUNTIME_DIR := "res://authoring/runtime"


static func scene_path_for_region(p_region_id: String) -> String:
	var region_id := Schema.sanitize_token(p_region_id)
	return DEFAULT_SCENE_DIR.path_join("%s_authoring.tscn" % region_id)


static func binding_path_for_region(p_region_id: String) -> String:
	var region_id := Schema.sanitize_token(p_region_id)
	return DEFAULT_RUNTIME_DIR.path_join("%s.json" % region_id)


static func resolve_published_scene(p_region_id: String) -> String:
	var binding := load_binding(p_region_id)
	if binding.is_empty():
		return ""
	var scene_path := str(binding.get("scene_path", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return ""
	return scene_path


static func load_binding(p_region_id: String) -> Dictionary:
	var path := binding_path_for_region(p_region_id)
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return {}
	if str(parsed.get("region_id", "")) != Schema.sanitize_token(p_region_id):
		return {}
	return parsed


static func publish(
	p_manifest: Dictionary,
	p_manifest_json_path: String,
	p_runtime_scene_path: String = ""
) -> Dictionary:
	var region_id := Schema.sanitize_token(str(p_manifest.get("region_id", "")))
	if region_id.is_empty():
		return {"ok": false, "error": "发布失败：manifest 缺少 region_id。"}
	var scene_path := p_runtime_scene_path
	if scene_path.is_empty():
		scene_path = str(p_manifest.get("scene_path", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return {"ok": false, "error": "发布失败：作者场景不存在 %s" % scene_path}
	var binding := {
		"schema_version": 1,
		"region_id": region_id,
		"scene_path": scene_path,
		"manifest_path": p_manifest_json_path,
		"object_count": int(p_manifest.get("object_count", 0)),
		"generated_at": Time.get_datetime_string_from_system(),
	}
	var binding_path := binding_path_for_region(region_id)
	_ensure_project_dir(binding_path.get_base_dir())
	var file := FileAccess.open(binding_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "无法写入运行时绑定：%s" % binding_path}
	file.store_string(JSON.stringify(binding, "\t", true, true))
	file.close()
	return {"ok": true, "binding_path": binding_path, "scene_path": scene_path}


static func build(p_parent: Node, p_region: Dictionary, p_scene_path: String = "") -> Dictionary:
	var region_id := Schema.sanitize_token(str(p_region.get("region_id", "")))
	var scene_path := p_scene_path
	if scene_path.is_empty():
		scene_path = resolve_published_scene(region_id)
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return {}
	var packed: PackedScene = ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE
	) as PackedScene
	if packed == null:
		return {}
	var scene_root := packed.instantiate()
	if not (scene_root is Node3D):
		scene_root.free()
		return {}
	p_parent.add_child(scene_root)

	var handle := {
		"authored": true,
		"scene_path": scene_path,
		"scene_root": scene_root,
		"zones": {},
		"gates": {},
		"route_gates": {},
		"pickups": {},
		"markers": {},
		"marker_nodes": {},
		"props": 0,
		"decor": 0,
		"floors": 0,
	}
	_install_semantics(scene_root, handle)
	return handle


static func _install_semantics(p_root: Node, p_handle: Dictionary) -> void:
	for node in _walk(p_root):
		var data := Schema.data_from_node(node)
		if data.is_empty():
			continue
		var kind := str(data.get("kind", ""))
		var behavior := str(data.get("behavior", ""))
		var semantic_id := str(data.get("semantic_id", ""))
		if kind == "zone":
			p_handle["zones"][semantic_id] = node
			p_handle["floors"] = int(p_handle["floors"]) + 1
		elif kind == "floor":
			p_handle["floors"] = int(p_handle["floors"]) + 1
		elif kind == "prop" or kind == "breakable" or kind == "route_gate":
			p_handle["props"] = int(p_handle["props"]) + 1
		elif kind == "decor":
			p_handle["decor"] = int(p_handle["decor"]) + 1

		if behavior == "gate":
			var gate := _attach_gate(node, data)
			if gate:
				p_handle["gates"][semantic_id] = gate
		elif behavior == "breakable":
			_attach_breakable(node, data)
		elif behavior == "pickup":
			var pickup := _attach_pickup(node, data)
			if pickup:
				p_handle["pickups"][semantic_id] = pickup
		elif behavior == "lift":
			_animate_lift(node, data)
		elif behavior == "route_gate":
			p_handle["route_gates"][semantic_id] = node

		if kind in ["spawn", "rest", "case", "boss", "objective", "npc", "patrol", "nav"]:
			var marker := data.duplicate(true)
			marker["node_path"] = _safe_node_path(p_root, node)
			marker["position"] = _node_position(node)
			p_handle["markers"][semantic_id] = marker
			p_handle["marker_nodes"][semantic_id] = node


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


static func _attach_gate(p_node: Node, p_data: Dictionary) -> Node:
	var params: Dictionary = p_data.get("params", {})
	if p_node is StaticBody3D:
		if p_node.get_script() == null:
			p_node.set_script(GateScript)
		if p_node.get_script() == GateScript:
			p_node.set("gate_id", str(p_data.get("semantic_id", "")))
			p_node.set("required_ability", str(params.get("required_ability", "")))
			p_node.set("required_boss", str(params.get("required_boss", "")))
			p_node.set("required_quest", str(params.get("required_quest", "")))
			p_node.set("kind", str(params.get("kind", "")))
			p_node.set("prompt", str(params.get("prompt", "")))
			if p_node.has_method("runtime_initialize"):
				p_node.call("runtime_initialize")
			return p_node
	var gate := GateScript.new()
	gate.name = "RuntimeGate"
	gate.set("gate_id", str(p_data.get("semantic_id", "")))
	gate.set("required_ability", str(params.get("required_ability", "")))
	gate.set("required_boss", str(params.get("required_boss", "")))
	gate.set("required_quest", str(params.get("required_quest", "")))
	gate.set("kind", str(params.get("kind", "")))
	gate.set("prompt", str(params.get("prompt", "")))
	p_node.add_child(gate)
	return gate


static func _attach_breakable(p_node: Node, p_data: Dictionary) -> Node:
	if p_node is StaticBody3D and p_node.get_script() == null:
		p_node.set_script(BreakableScript)
	if p_node is StaticBody3D and p_node.get_script() == BreakableScript:
		p_node.set("breakable_id", str(p_data.get("semantic_id", "")))
		if p_node.has_method("runtime_initialize"):
			p_node.call("runtime_initialize")
		return p_node
	var body := BreakableScript.new()
	body.name = "RuntimeBreakable"
	body.set("breakable_id", str(p_data.get("semantic_id", "")))
	p_node.add_child(body)
	return body


static func _attach_pickup(p_node: Node, p_data: Dictionary) -> Node:
	var params: Dictionary = p_data.get("params", {})
	var pickup: Area3D
	if p_node is Area3D:
		pickup = p_node
		if pickup.get_script() == null:
			pickup.set_script(PickupScript)
	else:
		pickup = PickupScript.new()
		pickup.name = "RuntimePickup"
		p_node.add_child(pickup)
	if pickup.get_script() != PickupScript:
		return null
	pickup.set("ability_id", str(params.get("ability_id", p_data.get("semantic_id", ""))))
	pickup.set("ability_name", str(params.get("ability_name", "")))
	if pickup.has_method("runtime_initialize"):
		pickup.call("runtime_initialize")
	return pickup


static func _animate_lift(p_node: Node, p_data: Dictionary) -> void:
	if not (p_node is AnimatableBody3D):
		return
	var params: Dictionary = p_data.get("params", {})
	var lift_height := float(params.get("lift", 2.0))
	var duration := maxf(0.1, float(params.get("dur", 2.4)))
	var base_position: Vector3 = p_node.position
	var tween := p_node.create_tween()
	tween.set_loops()
	tween.tween_property(p_node, "position", base_position + Vector3(0.0, lift_height, 0.0), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(p_node, "position", base_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


static func _walk(p_root: Node) -> Array[Node]:
	var result: Array[Node] = [p_root]
	for child in p_root.get_children():
		result.append_array(_walk(child))
	return result


static func _node_position(p_node: Node) -> Array:
	if p_node is Node3D:
		var position: Vector3 = p_node.global_position
		return [position.x, position.y, position.z]
	return []


static func _ensure_project_dir(p_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p_path))
