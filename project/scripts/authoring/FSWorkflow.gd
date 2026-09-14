class_name FSWorkflow
extends RefCounted


static func steps() -> Array[Dictionary]:
	return [
		{
			"id": "spec_confirm",
			"title": "1 / 7 规格确认",
			"owner": "AI 提供规格，用户确认",
			"instruction": "AI 说明本轮搭建范围、入口、验收方式、不会修改的内容，并列出可用的中文显示命名与模型目录。",
			"prompt": "请确认本轮场景规格和模型方案。确认后才进入场景手调。",
		},
		{
			"id": "scene_edit",
			"title": "2 / 7 场景手调",
			"owner": "用户",
			"instruction": "在作者场景中移动、替换、增删物件；行为宿主填写中文显示名和稳定 semantic_id，并从模型目录应用可视模型。",
			"prompt": "请完成场景手调。确认时表示本轮布局、显示名和可视模型已冻结，可以进入语义校验。",
		},
		{
			"id": "semantic_audit",
			"title": "3 / 7 语义校验",
			"owner": "插件 + 用户",
			"instruction": "点击校验，处理重复 ID、缺失行为、无效链接或未规范命名。",
			"prompt": "请确认语义与分组无错误。仍有错误时不能进入导出。",
		},
		{
			"id": "manifest_export",
			"title": "4 / 7 导出并发布",
			"owner": "插件",
			"instruction": "保存作者场景，导出 JSON/Markdown 清单，并把该场景发布为运行时真源。AI 不整读场景。",
			"prompt": "请确认作者场景已保存、清单无错误，并允许发布到运行时。",
		},
		{
			"id": "implementation",
			"title": "5 / 7 功能实现",
			"owner": "AI",
			"instruction": "AI 按清单中的 semantic_id、kind、behavior、links 和 params 实现，不猜测视觉位置。",
			"prompt": "请确认本节点功能实现完成并提供了 smoke 或复现路径。",
		},
		{
			"id": "playtest",
			"title": "6 / 7 试玩验收",
			"owner": "用户",
			"instruction": "用户进入运行时场景检查视觉、碰撞、互动、门锁和状态变化。",
			"prompt": "请确认本轮试玩通过，或记录问题并退回实现节点。",
		},
		{
			"id": "handoff",
			"title": "7 / 7 交接回填",
			"owner": "AI + 用户",
			"instruction": "更新交接簿、运行说明和下一步；一个会话只保留一个明确任务。",
			"prompt": "请确认交接完成，可以结束本会话。",
		},
	]


static func create_document(p_region_id: String, p_scene_path: String) -> Dictionary:
	var step_states: Array[Dictionary] = []
	for step in steps():
		step_states.append({
			"id": step["id"],
			"status": "PENDING",
			"confirmed_at": "",
			"note": "",
		})
	return {
		"schema_version": 1,
		"region_id": p_region_id,
		"scene_path": p_scene_path,
		"current_step": 0,
		"status": "ACTIVE",
		"steps": step_states,
		"updated_at": Time.get_datetime_string_from_system(),
	}


static func load_or_create(p_path: String, p_region_id: String, p_scene_path: String) -> Dictionary:
	if FileAccess.file_exists(p_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(p_path))
		if parsed is Dictionary:
			var normalized := normalize_document(parsed, p_region_id, p_scene_path)
			if normalized != parsed:
				save(p_path, normalized)
			return normalized
	var document := create_document(p_region_id, p_scene_path)
	save(p_path, document)
	return document


static func normalize_document(
	p_document: Dictionary,
	p_region_id: String,
	p_scene_path: String
) -> Dictionary:
	var all_steps := steps()
	var raw_steps_value: Variant = p_document.get("steps", [])
	var raw_steps: Array = raw_steps_value if raw_steps_value is Array else []
	var states_by_id := {}
	for raw_step in raw_steps:
		if raw_step is Dictionary:
			var raw_state: Dictionary = raw_step
			var raw_id := str(raw_state.get("id", ""))
			if not raw_id.is_empty() and not states_by_id.has(raw_id):
				states_by_id[raw_id] = raw_state

	var normalized_steps: Array[Dictionary] = []
	for index in range(all_steps.size()):
		var step_id := str(all_steps[index]["id"])
		var candidate: Dictionary = {}
		if states_by_id.has(step_id):
			candidate = states_by_id[step_id]
		elif index < raw_steps.size() and raw_steps[index] is Dictionary:
			var indexed_state: Dictionary = raw_steps[index]
			var indexed_id := str(indexed_state.get("id", ""))
			if indexed_id.is_empty() or indexed_id == step_id:
				candidate = indexed_state
		normalized_steps.append(_normalize_step_state(candidate, step_id))

	var first_pending := normalized_steps.size()
	for index in range(normalized_steps.size()):
		if str(normalized_steps[index].get("status", "PENDING")) != "DONE":
			first_pending = index
			break

	var normalized_region_id := p_region_id
	if normalized_region_id.is_empty():
		normalized_region_id = str(p_document.get("region_id", ""))
	var normalized_scene_path := p_scene_path
	if normalized_scene_path.is_empty():
		normalized_scene_path = str(p_document.get("scene_path", ""))
	var normalized_updated_at := str(p_document.get("updated_at", ""))
	if normalized_updated_at.is_empty():
		normalized_updated_at = Time.get_datetime_string_from_system()
	return {
		"schema_version": 1,
		"region_id": normalized_region_id,
		"scene_path": normalized_scene_path,
		"current_step": first_pending,
		"status": "COMPLETE" if first_pending >= all_steps.size() else "ACTIVE",
		"steps": normalized_steps,
		"updated_at": normalized_updated_at,
	}


static func save(p_path: String, p_document: Dictionary) -> bool:
	_ensure_project_dir(p_path.get_base_dir())
	p_document["updated_at"] = Time.get_datetime_string_from_system()
	var file := FileAccess.open(p_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(p_document, "\t", true))
	file.close()
	return true


static func current_step(p_document: Dictionary) -> Dictionary:
	var all_steps := steps()
	var index := int(p_document.get("current_step", 0))
	if index < 0 or index >= all_steps.size():
		return {}
	return all_steps[index]


static func confirm_current(p_document: Dictionary, p_note: String = "") -> Dictionary:
	var all_steps := steps()
	var document := normalize_document(
		p_document,
		str(p_document.get("region_id", "")),
		str(p_document.get("scene_path", ""))
	)
	var index := int(document.get("current_step", 0))
	if index < 0 or index >= all_steps.size():
		document["status"] = "COMPLETE"
		p_document.clear()
		p_document.merge(document, true)
		return p_document
	var state: Dictionary = document["steps"][index]
	state["status"] = "DONE"
	state["confirmed_at"] = Time.get_datetime_string_from_system()
	state["note"] = p_note
	document["steps"][index] = state
	index += 1
	document["current_step"] = index
	document["status"] = "COMPLETE" if index >= all_steps.size() else "ACTIVE"
	p_document.clear()
	p_document.merge(document, true)
	return p_document


static func progress_text(p_document: Dictionary) -> String:
	var all_steps := steps()
	var document := normalize_document(
		p_document,
		str(p_document.get("region_id", "")),
		str(p_document.get("scene_path", ""))
	)
	var states: Array = document["steps"]
	var lines: Array[String] = []
	for index in range(all_steps.size()):
		var state: Dictionary = states[index]
		var marker := "[ ]"
		if str(state.get("status", "")) == "DONE":
			marker = "[x]"
		elif index == int(document.get("current_step", 0)):
			marker = "[>]"
		lines.append("%s %s" % [marker, str(all_steps[index]["title"])])
	return "\n".join(lines)


static func path_for_region(p_region_id: String) -> String:
	return "res://authoring/workflows/%s.json" % FSAuthoringSchema.sanitize_token(p_region_id)


static func _ensure_project_dir(p_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p_path))


static func _normalize_step_state(p_state: Dictionary, p_step_id: String) -> Dictionary:
	var step_status := str(p_state.get("status", "PENDING")).to_upper()
	if step_status != "DONE":
		step_status = "PENDING"
	return {
		"id": p_step_id,
		"status": step_status,
		"confirmed_at": str(p_state.get("confirmed_at", "")),
		"note": str(p_state.get("note", "")),
	}
