class_name FSAuthoringSchema
extends RefCounted

const META_KEY := "fivestar_semantic"
const SCHEMA_VERSION := 1


static func kind_options() -> Array[Dictionary]:
	return [
		{"id": "region", "label": "区域根节点"},
		{"id": "zone", "label": "区域/房间"},
		{"id": "floor", "label": "地板/区域地色"},
		{"id": "spawn", "label": "出生点"},
		{"id": "rest", "label": "休息/复活点"},
		{"id": "case", "label": "案件点"},
		{"id": "gate", "label": "门/能力门"},
		{"id": "route_gate", "label": "路线进度门"},
		{"id": "ability", "label": "能力拾取"},
		{"id": "quest", "label": "任务/线索"},
		{"id": "boss", "label": "Boss 点"},
		{"id": "objective", "label": "目标/终点"},
		{"id": "npc", "label": "NPC"},
		{"id": "breakable", "label": "可击破物"},
		{"id": "interactive", "label": "可互动物"},
		{"id": "prop", "label": "玩法道具"},
		{"id": "decor", "label": "纯装饰"},
		{"id": "hazard", "label": "危险物"},
		{"id": "trigger", "label": "触发区域"},
		{"id": "patrol", "label": "巡逻路径"},
		{"id": "camera", "label": "镜头锚点"},
		{"id": "nav", "label": "导航/路径点"},
	]


static func behavior_options() -> Array[Dictionary]:
	return [
		{"id": "none", "label": "无运行时行为"},
		{"id": "spawn", "label": "出生"},
		{"id": "rest", "label": "休息/复活"},
		{"id": "case", "label": "案件"},
		{"id": "gate", "label": "门锁"},
		{"id": "route_gate", "label": "路线进度门"},
		{"id": "pickup", "label": "拾取能力"},
		{"id": "interact", "label": "E 互动"},
		{"id": "breakable", "label": "可击破"},
		{"id": "boss", "label": "Boss"},
		{"id": "objective", "label": "完成目标"},
		{"id": "trigger", "label": "触发"},
		{"id": "patrol", "label": "巡逻"},
		{"id": "pushable", "label": "可推"},
		{"id": "lift", "label": "升降平台"},
		{"id": "pressure_plate", "label": "压力机关"},
		{"id": "hazard", "label": "危险伤害"},
		{"id": "door", "label": "普通门"},
	]


static func normalize(p_data: Dictionary) -> Dictionary:
	var data := p_data.duplicate(true)
	data["semantic_id"] = sanitize_token(str(data.get("semantic_id", "")))
	data["display_name"] = sanitize_display_name(str(data.get("display_name", "")))
	data["kind"] = _valid_or_default(str(data.get("kind", "prop")), kind_options(), "prop")
	data["behavior"] = _valid_or_default(str(data.get("behavior", "none")), behavior_options(), "none")
	data["zone_id"] = sanitize_token(str(data.get("zone_id", "")))
	data["tags"] = string_array(data.get("tags", []))
	data["links"] = string_array(data.get("links", []))
	data["params"] = data.get("params", {})
	if not (data["params"] is Dictionary):
		data["params"] = {}
	return data


static func make(
	p_id: String,
	p_kind: String,
	p_behavior: String = "none",
	p_zone_id: String = "",
	p_tags: Array = [],
	p_links: Array = [],
	p_params: Dictionary = {},
	p_display_name: String = ""
) -> Dictionary:
	return normalize({
		"semantic_id": p_id,
		"display_name": p_display_name,
		"kind": p_kind,
		"behavior": p_behavior,
		"zone_id": p_zone_id,
		"tags": p_tags,
		"links": p_links,
		"params": p_params,
	})


static func sanitize_token(p_text: String) -> String:
	var text := p_text.strip_edges().to_lower().replace(" ", "_")
	if text.is_empty():
		return ""
	var output := ""
	for index in range(text.length()):
		var character := text.substr(index, 1)
		var allowed := character == "_"
		allowed = allowed or (character >= "a" and character <= "z")
		allowed = allowed or (character >= "0" and character <= "9")
		if allowed:
			output += character
		elif not output.ends_with("_"):
			output += "_"
	output = output.trim_prefix("_").trim_suffix("_")
	if output.is_empty():
		output = "semantic_object"
	return output.left(64)


static func sanitize_display_name(p_text: String) -> String:
	var text := p_text.strip_edges()
	for token in [".", ":", "@", "/", "\"", "%", "\n", "\r", "\t"]:
		text = text.replace(token, "_")
	while text.contains("__"):
		text = text.replace("__", "_")
	text = text.trim_prefix("_").trim_suffix("_")
	return text.left(48)


static func node_name(p_data: Dictionary) -> String:
	var data := normalize(p_data)
	var base := "FS_%s" % str(data["kind"]).to_upper()
	var display_name := sanitize_display_name(str(data.get("display_name", "")))
	if not display_name.is_empty():
		base += "_%s" % display_name
	return "%s_%s" % [base, str(data["semantic_id"]).to_upper()]


static func groups(p_data: Dictionary) -> PackedStringArray:
	var data := normalize(p_data)
	var result := PackedStringArray(["fs.semantic", "fs.kind.%s" % str(data["kind"])])
	if not str(data["zone_id"]).is_empty():
		result.append("fs.zone.%s" % str(data["zone_id"]))
	result.append("fs.behavior.%s" % str(data["behavior"]))
	for tag in data["tags"]:
		var safe_tag := sanitize_token(str(tag))
		if not safe_tag.is_empty():
			result.append("fs.tag.%s" % safe_tag)
	return result


static func apply_to_node(p_node: Node, p_data: Dictionary) -> Dictionary:
	var data := normalize(p_data)
	p_node.set_meta(META_KEY, data)
	for group in p_node.get_groups():
		var group_name := str(group)
		if group_name.begins_with("fs."):
			p_node.remove_from_group(group)
	for group in groups(data):
		p_node.add_to_group(group)
	return data


static func data_from_node(p_node: Node) -> Dictionary:
	if not p_node.has_meta(META_KEY):
		return {}
	var value = p_node.get_meta(META_KEY)
	if not (value is Dictionary):
		return {}
	return normalize(value)


static func string_array(p_value) -> Array[String]:
	var result: Array[String] = []
	if p_value == null:
		return result
	if p_value is String:
		for part in p_value.split(",", false):
			var value := str(part).strip_edges()
			if not value.is_empty():
				result.append(value)
		return result
	if p_value is Array or p_value is PackedStringArray:
		for part in p_value:
			var value := str(part).strip_edges()
			if not value.is_empty() and not result.has(value):
				result.append(value)
	return result


static func kind_ids() -> Array[String]:
	var result: Array[String] = []
	for option in kind_options():
		result.append(str(option["id"]))
	return result


static func behavior_ids() -> Array[String]:
	var result: Array[String] = []
	for option in behavior_options():
		result.append(str(option["id"]))
	return result


static func runtime_support_for(p_kind: String, p_behavior: String) -> String:
	var behavior := str(p_behavior)
	if behavior in ["gate", "breakable", "pickup", "lift", "route_gate"]:
		return "runtime"
	if behavior == "pushable":
		return "native"
	if str(p_kind) in ["spawn", "rest", "case", "boss", "objective", "npc", "patrol", "nav"]:
		return "marker"
	if behavior in ["interact", "trigger", "pressure_plate", "hazard", "door"]:
		return "pending"
	return "none"


static func label_for(p_options: Array[Dictionary], p_id: String) -> String:
	for option in p_options:
		if str(option["id"]) == p_id:
			return str(option["label"])
	return p_id


static func _valid_or_default(p_value: String, p_options: Array[Dictionary], p_default: String) -> String:
	for option in p_options:
		if str(option["id"]) == p_value:
			return p_value
	return p_default
