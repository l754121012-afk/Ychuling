class_name FSVisualCatalog
extends RefCounted

const Schema := preload("res://scripts/authoring/FSAuthoringSchema.gd")
const CATALOG_PATH := "res://authoring/assets/model_catalog.json"
const VISUAL_PREFIX := "VISUAL_"
const EFFECT_PREFIX := "EFFECT_"
const SUPPORT_PREFIX := "SUPPORT_"
const HIDDEN_VISUAL_PREFIX := "art_key_"
const HIDDEN_VISUAL_ALT_PREFIX := "Authoring"
const AUTHORING_MARKER_PREFIX := "AuthoringMarker"
const AUTO_SUPPORT_COLLISION_META := "__fs_auto_support_collision"
const SUPPORT_PROFILE_META := "__fs_support_profile"
const HOST_MESH_META := "__fs_visual_host_mesh"
const HOST_HAS_MATERIAL_OVERRIDE_META := "__fs_visual_host_has_material_override"
const HOST_MATERIAL_OVERRIDE_META := "__fs_visual_host_material_override"
const HOST_HAS_MATERIAL_OVERLAY_META := "__fs_visual_host_has_material_overlay"
const HOST_MATERIAL_OVERLAY_META := "__fs_visual_host_material_overlay"
const HIDDEN_VISIBLE_META := "__fs_visual_hidden_visible"
const IMPORTED_MODEL_ROOTS := [
	"res://assets/vendor/kenney/fantasy_town/Models",
	"res://assets/vendor/kenney/graveyard/Models",
	"res://assets/vendor/kenney/mini_dungeon/Models",
]
const AUTO_MODEL_WORDS := {
	"arch": "拱门",
	"balcony": "阳台",
	"banner": "旗帜",
	"barrel": "木桶",
	"bench": "长椅",
	"block": "方块",
	"brick": "砖",
	"bridge": "桥",
	"candle": "蜡烛",
	"cart": "推车",
	"character": "角色",
	"chest": "宝箱",
	"chimney": "烟囱",
	"coffin": "棺材",
	"coin": "金币",
	"column": "石柱",
	"curb": "路缘",
	"debris": "碎片",
	"detail": "部件",
	"door": "门",
	"doorway": "门洞",
	"drain": "排水口",
	"fence": "围栏",
	"floor": "地板",
	"fountain": "喷泉",
	"gate": "门",
	"grave": "坟墓",
	"gravestone": "墓碑",
	"hedge": "树篱",
	"key": "钥匙",
	"lantern": "提灯",
	"lightpost": "路灯",
	"pillar": "石柱",
	"planks": "木板",
	"pot": "陶罐",
	"potion": "药水",
	"road": "道路",
	"rock": "岩石",
	"roof": "屋顶",
	"stairs": "楼梯",
	"stall": "摊位",
	"stone": "石制",
	"table": "桌子",
	"tree": "树",
	"trap": "机关",
	"urn": "骨灰瓮",
	"wall": "墙",
	"watermill": "水车",
	"wheel": "轮子",
	"window": "窗",
	"wood": "木制",
}
const WATER_SHORTCUT_MODEL_IDS := [
	"fountain_round",
	"fountain_round_detail",
	"fountain_square",
	"fountain_square_detail",
	"fountain_center",
	"fountain_curved",
	"fountain_edge",
	"fountain_corner",
	"fountain_corner_inner",
	"fountain_corner_inner_square",
	"waterfall",
	"river_straight",
	"river_corner",
	"riverbank",
	"water_surface",
	"plunge_pool_foam",
	"puddle_ripple",
	"drain_outfall",
	"watermill",
	"watermill_wide",
]
const SUPPORT_PROFILE_BY_MODEL_ID := {
	"town_road": "floor",
	"town_road_curb": "floor",
	"town_road_corner": "floor",
	"town_road_slope": "floor",
	"town_road_edge_slope": "floor",
	"dungeon_floor": "floor",
	"dungeon_floor_detail": "floor",
	"dungeon_dirt": "floor",
	"wood_planks": "platform",
	"planks_half": "platform",
	"planks_opening": "platform",
	"pressure_plate": "platform",
	"brick_wall": "wall",
	"brick_wall_corner": "wall",
	"stone_wall": "wall",
	"stone_wall_column": "wall",
	"stone_wall_curve": "wall",
	"town_wall": "wall",
	"town_wood_wall": "wall",
	"town_wall_slope": "wall",
	"town_wood_wall_slope": "wall",
	"dungeon_wall": "wall",
	"dungeon_wall_half": "wall",
	"dungeon_wall_narrow": "wall",
	"dungeon_wall_opening": "wall",
	"stairs_stone": "stairs",
	"stairs_wood": "stairs",
	"stairs_stone_corner": "stairs",
	"stairs_stone_handrail": "stairs",
	"stairs_wide_stone": "stairs",
	"stairs_wide_stone_handrail": "stairs",
	"stairs_full": "stairs",
	"dungeon_stairs": "stairs",
	"stone_pillar_large": "column",
	"dungeon_column": "column",
	"wood_support": "column",
	"rocks": "obstacle",
	"rocks_tall": "obstacle",
	"rock_small": "obstacle",
	"rock_wide": "obstacle",
	"rock_large": "obstacle",
}


static func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not FileAccess.file_exists(CATALOG_PATH):
		return result
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not (parsed is Dictionary):
		return result
	for raw_entry in parsed.get("entries", []):
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry.duplicate(true)
		entry["id"] = str(entry.get("id", "")).strip_edges()
		entry["label"] = str(entry.get("label", entry["id"])).strip_edges()
		entry["category"] = str(entry.get("category", "未分类")).strip_edges()
		entry["path"] = str(entry.get("path", "")).strip_edges()
		entry["tags"] = _string_array(entry.get("tags", []))
		entry["default_scale"] = _vector3(entry.get("default_scale", [1.0, 1.0, 1.0]), Vector3.ONE)
		entry["rotation_degrees"] = _vector3(entry.get("rotation_degrees", [0.0, 0.0, 0.0]), Vector3.ZERO)
		entry["y_offset"] = float(entry.get("y_offset", 0.0))
		entry["fit_mode"] = str(entry.get("fit_mode", "contain")).strip_edges().to_lower()
		entry["placement"] = str(entry.get(
			"placement",
			_default_placement_for_model_id(str(entry["id"]))
		)).strip_edges().to_lower()
		entry["support_profile"] = _normalize_support_profile(
			str(entry.get("support_profile", "")),
			str(entry["id"]),
			entry["tags"],
			str(entry["path"])
		)
		entry["repeat_along_longest"] = bool(entry.get("repeat_along_longest", false))
		entry["max_repeat"] = maxi(1, int(entry.get("max_repeat", 24)))
		if not entry["id"].is_empty() and not entry["path"].is_empty():
			result.append(entry)
	return result


static func all_entries() -> Array[Dictionary]:
	var result := entries()
	var known_paths := {}
	for entry in result:
		known_paths[str(entry.get("path", ""))] = true
	for root_path in IMPORTED_MODEL_ROOTS:
		_collect_imported_models(root_path, result, known_paths)
	return result


static func categories() -> Array[String]:
	var result: Array[String] = []
	for entry in all_entries():
		var category := str(entry.get("category", ""))
		if not category.is_empty() and not result.has(category):
			result.append(category)
	return result


static func water_shortcut_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries():
		if str(entry.get("id", "")) in WATER_SHORTCUT_MODEL_IDS:
			result.append(entry)
	return result


static func support_shortcut_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in all_entries():
		if str(entry.get("support_profile", "none")) != "none":
			result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := "%s %s" % [str(a.get("category", "")), str(a.get("label", ""))]
		var b_key := "%s %s" % [str(b.get("category", "")), str(b.get("label", ""))]
		return a_key < b_key
	)
	return result


static func support_profile_for_host(p_host: Node) -> String:
	if not p_host:
		return "none"
	if p_host.has_meta(SUPPORT_PROFILE_META):
		var meta_profile := _normalize_support_profile(
			str(p_host.get_meta(SUPPORT_PROFILE_META)),
			"",
			[],
			""
		)
		if meta_profile != "none":
			return meta_profile
	var data := Schema.data_from_node(p_host)
	var params: Dictionary = (
		data.get("params", {})
		if data.get("params", {}) is Dictionary
		else {}
	)
	var visual: Dictionary = (
		params.get("visual", {})
		if params.get("visual", {}) is Dictionary
		else {}
	)
	var visual_profile := str(visual.get("support_profile", "")).strip_edges().to_lower()
	var model_id := str(visual.get("model_id", "")).strip_edges()
	if model_id.is_empty():
		model_id = model_id_from_node(p_host)
	return _normalize_support_profile(
		visual_profile,
		model_id,
		_string_array(visual.get("tags", [])),
		str(visual.get("path", ""))
	)


static func ensure_support_collision(p_host: Node, p_owner: Node = null) -> Dictionary:
	if not (p_host is Node3D):
		return {"ok": false, "error": "承托碰撞只能生成在 Node3D 语义宿主上。"}
	var profile := support_profile_for_host(p_host)
	if profile == "none":
		return {"ok": true, "skipped": true, "reason": "该模型不承担地形或阻挡。"}
	var removed := remove_auto_support_collision(p_host)
	if _has_user_support_collision(p_host):
		return {
			"ok": true,
			"skipped": true,
			"profile": profile,
			"removed": removed,
			"reason": "宿主已有用户自建碰撞，保留原碰撞。",
		}
	var source_aabb := _support_source_aabb(p_host as Node3D)
	if (
		source_aabb.size.x <= 0.0001
		or source_aabb.size.z <= 0.0001
		or (profile != "floor" and source_aabb.size.y <= 0.0001)
	):
		return {
			"ok": false,
			"profile": profile,
			"error": "模型包围盒为空，无法生成承托碰撞。",
		}
	var collision_size := _support_collision_size(profile, source_aabb.size)
	if (
		collision_size.x <= 0.0001
		or collision_size.y <= 0.0001
		or collision_size.z <= 0.0001
	):
		return {
			"ok": false,
			"profile": profile,
			"error": "计算出的承托碰撞尺寸无效。",
		}
	var collision_position := _support_collision_position(profile, source_aabb, collision_size)
	var shape := BoxShape3D.new()
	shape.size = collision_size
	var collision_shape := CollisionShape3D.new()
	collision_shape.name = SUPPORT_PREFIX + profile
	collision_shape.shape = shape
	collision_shape.position = collision_position
	collision_shape.set_meta(AUTO_SUPPORT_COLLISION_META, true)
	collision_shape.set_meta(SUPPORT_PROFILE_META, profile)

	if p_host is CollisionObject3D:
		p_host.add_child(collision_shape)
		_assign_support_owner(collision_shape, p_owner)
		return {
			"ok": true,
			"profile": profile,
			"node": collision_shape,
			"size": collision_size,
			"position": collision_position,
			"removed": removed,
		}

	var body := StaticBody3D.new()
	body.name = SUPPORT_PREFIX + profile
	body.set_meta(AUTO_SUPPORT_COLLISION_META, true)
	body.set_meta(SUPPORT_PROFILE_META, profile)
	body.add_child(collision_shape)
	p_host.add_child(body)
	_assign_support_owner(body, p_owner)
	_assign_support_owner(collision_shape, p_owner)
	return {
		"ok": true,
		"profile": profile,
		"node": body,
		"shape": collision_shape,
		"size": collision_size,
		"position": collision_position,
		"removed": removed,
	}


static func refresh_all_support_collisions(p_root: Node) -> Dictionary:
	if not p_root:
		return {"ok": false, "error": "没有可修正的场景根节点。"}
	var nodes: Array[Node] = []
	_collect_semantic_nodes(p_root, nodes)
	var corrected := 0
	var skipped := 0
	var failed := 0
	var errors: Array[String] = []
	for node in nodes:
		if not (node is Node3D):
			continue
		var result := ensure_support_collision(node, p_root)
		if bool(result.get("ok", false)):
			if bool(result.get("skipped", false)):
				skipped += 1
			else:
				corrected += 1
		else:
			failed += 1
			errors.append("%s: %s" % [
				str(node.name),
				str(result.get("error", "未知错误")),
			])
	return {
		"ok": failed == 0,
		"corrected": corrected,
		"skipped": skipped,
		"failed": failed,
		"errors": errors,
	}


static func remove_auto_support_collision(p_host: Node) -> int:
	if not p_host:
		return 0
	var generated: Array[Node] = []
	_collect_auto_support_collisions(p_host, generated)
	var removed := 0
	for node in generated:
		if not is_instance_valid(node) or node == p_host:
			continue
		var parent := node.get_parent()
		if not parent:
			continue
		parent.remove_child(node)
		node.free()
		removed += 1
	return removed


static func _normalize_support_profile(
	p_profile: String,
	p_model_id: String,
	p_tags: Array[String],
	p_path: String
) -> String:
	var profile := p_profile.strip_edges().to_lower()
	if profile in [
		"floor",
		"platform",
		"wall",
		"stairs",
		"column",
		"obstacle",
		"none",
	]:
		return profile
	return _default_support_profile_for_model_id(p_model_id, p_tags, p_path)


static func _default_support_profile_for_model_id(
	p_model_id: String,
	p_tags: Array[String],
	p_path: String
) -> String:
	var model_id := p_model_id.strip_edges().to_lower()
	if SUPPORT_PROFILE_BY_MODEL_ID.has(model_id):
		return str(SUPPORT_PROFILE_BY_MODEL_ID[model_id])

	var stem := p_path.get_file().get_basename().to_lower()
	var haystack := "%s %s %s" % [
		model_id,
		stem,
		" ".join(p_tags).to_lower(),
	]
	var token_text := haystack.replace("-", "_").replace(" ", "_")

	# Doorways, windows and arches are architectural details rather than
	# invisible blockers. Their eventual behavior belongs to the semantic event.
	if (
		token_text.contains("door")
		or token_text.contains("window")
		or token_text.contains("arch")
		or token_text.contains("opening")
	):
		return "none"
	if token_text.contains("stair"):
		return "stairs"
	if (
		token_text.contains("pillar")
		or token_text.contains("column")
		or token_text.contains("support")
		or token_text.contains("pole")
	):
		return "column"
	if token_text.contains("wall"):
		return "wall"
	if (
		token_text.contains("plank")
		or token_text.contains("platform")
		or token_text.contains("bridge")
		or token_text.contains("balcony")
	):
		return "platform"
	if (
		token_text.contains("road")
		or token_text.contains("floor")
		or token_text.contains("dirt")
		or token_text.contains("ground")
		or token_text.contains("pavement")
		or token_text.contains("tile")
	):
		return "floor"
	if (
		token_text.contains("rock_")
		or token_text.ends_with("_rock")
		or token_text.contains("_rocks")
		or token_text.ends_with("_stones")
	):
		return "obstacle"
	return "none"


static func _has_user_support_collision(p_host: Node) -> bool:
	for child in p_host.get_children():
		if _has_user_support_collision_recursive(child):
			return true
	return false


static func _has_user_support_collision_recursive(p_node: Node) -> bool:
	if _is_auto_support_node(p_node):
		return false
	if p_node is CollisionShape3D or p_node is CollisionPolygon3D:
		return true
	for child in p_node.get_children():
		if _has_user_support_collision_recursive(child):
			return true
	return false


static func _support_source_aabb(p_host: Node3D) -> AABB:
	var visual := visual_node(p_host)
	if visual:
		var visual_aabb := _node_aabb_in_parent(visual)
		if (
			visual_aabb.size.x > 0.0001
			or visual_aabb.size.y > 0.0001
			or visual_aabb.size.z > 0.0001
		):
			return visual_aabb
	return _host_target_aabb(p_host)


static func _support_collision_size(profile: String, p_source_size: Vector3) -> Vector3:
	match profile:
		"floor":
			return Vector3(
				p_source_size.x * 0.98,
				clampf(p_source_size.y, 0.08, 0.25),
				p_source_size.z * 0.98
			)
		"platform":
			return Vector3(
				p_source_size.x * 0.98,
				clampf(p_source_size.y, 0.12, 0.35),
				p_source_size.z * 0.98
			)
		"wall":
			return Vector3(
				maxf(0.02, p_source_size.x * 0.92),
				maxf(0.02, p_source_size.y * 0.98),
				maxf(0.02, p_source_size.z * 0.92)
			)
		"column":
			return Vector3(
				maxf(0.02, p_source_size.x * 0.9),
				maxf(0.02, p_source_size.y * 0.98),
				maxf(0.02, p_source_size.z * 0.9)
			)
		"obstacle":
			return Vector3(
				maxf(0.02, p_source_size.x * 0.92),
				maxf(0.02, p_source_size.y * 0.98),
				maxf(0.02, p_source_size.z * 0.92)
			)
		"stairs":
			return p_source_size.max(Vector3(0.02, 0.02, 0.02))
	return Vector3.ZERO


static func _support_collision_position(
	profile: String,
	p_source_aabb: AABB,
	p_collision_size: Vector3
) -> Vector3:
	var center := p_source_aabb.get_center()
	if profile in ["floor", "platform"]:
		return Vector3(
			center.x,
			p_source_aabb.end.y - p_collision_size.y * 0.5,
			center.z
		)
	return center


static func _assign_support_owner(p_node: Node, p_owner: Node) -> void:
	if not p_owner or not p_owner.is_ancestor_of(p_node):
		return
	p_node.owner = p_owner


static func _collect_auto_support_collisions(
	p_node: Node,
	p_result: Array[Node]
) -> void:
	for child in p_node.get_children():
		if _is_auto_support_node(child):
			p_result.append(child)
			continue
		_collect_auto_support_collisions(child, p_result)


static func _is_auto_support_node(p_node: Node) -> bool:
	return (
		p_node.has_meta(AUTO_SUPPORT_COLLISION_META)
		or str(p_node.name).begins_with(SUPPORT_PREFIX)
	)


static func find(p_model_id: String) -> Dictionary:
	for entry in all_entries():
		if str(entry.get("id", "")) == p_model_id:
			return entry
	return {}


static func _collect_imported_models(
	p_directory: String,
	p_result: Array[Dictionary],
	p_known_paths: Dictionary
) -> void:
	var directory := DirAccess.open(p_directory)
	if directory == null:
		return
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		var path := p_directory.path_join(file_name)
		if directory.current_is_dir():
			_collect_imported_models(path, p_result, p_known_paths)
		elif file_name.to_lower().ends_with(".glb") and not p_known_paths.has(path):
			var kit := _model_kit_from_path(path)
			var stem := file_name.get_basename()
			var model_id := Schema.sanitize_token("auto_%s_%s" % [kit, stem])
			var tags: Array[String] = ["自动扫描", kit, stem]
			p_result.append({
				"id": model_id,
				"label": _auto_model_label(kit, stem),
				"category": "自动扫描 / %s" % _kit_label(kit),
				"path": path,
				"default_scale": [1.0, 1.0, 1.0],
				"y_offset": 0.0,
				"rotation_degrees": [0.0, 0.0, 0.0],
				"fit_mode": "contain",
				"placement": "ground",
				"support_profile": _default_support_profile_for_model_id(
					model_id,
					tags,
					path
				),
				"tags": tags,
			})
			p_known_paths[path] = true
		file_name = directory.get_next()
	directory.list_dir_end()


static func _model_kit_from_path(p_path: String) -> String:
	var marker := "res://assets/vendor/kenney/"
	if not p_path.begins_with(marker):
		return "其他"
	return p_path.trim_prefix(marker).split("/", false)[0]


static func _kit_label(p_kit: String) -> String:
	match p_kit:
		"fantasy_town":
			return "幻想城镇"
		"graveyard":
			return "墓园"
		"mini_dungeon":
			return "迷你地牢"
	return p_kit


static func _auto_model_label(p_kit: String, p_stem: String) -> String:
	var words := p_stem.replace("_", " ").replace("-", " ").split(" ", false)
	var translated: Array[String] = []
	for word in words:
		translated.append(str(AUTO_MODEL_WORDS.get(str(word).to_lower(), str(word))))
	return "%s：%s（%s）" % [_kit_label(p_kit), " ".join(translated), p_stem]


static func recommended_model_id(
	p_kind: String,
	p_behavior: String,
	p_semantic_id: String,
	p_art_keys: Array[String] = [],
	p_extra_context: String = ""
) -> String:
	var kind := p_kind.strip_edges().to_lower()
	var behavior := p_behavior.strip_edges().to_lower()
	var semantic_id := p_semantic_id.strip_edges().to_lower()
	var context := "%s %s %s" % [
		semantic_id,
		" ".join(p_art_keys).to_lower(),
		p_extra_context.strip_edges().to_lower(),
	]

	# 大面积地板保留现有色板；它承担区域底色，不适合被单个道路模块覆盖。
	if kind == "floor":
		return ""
	if semantic_id.contains("route_wall") or context.contains("route_wall") or context.contains("boundary"):
		return "town_wall"
	if kind == "route_gate" or behavior == "route_gate":
		return "town_wall"
	if behavior == "lift" or context.contains("lift_platform") or context.contains("lift"):
		return "wood_planks"
	if behavior == "pressure_plate" or context.contains("pressure_plate"):
		return "pressure_plate"
	if (
		context.contains("building")
		or context.contains("house")
		or context.contains("hut")
		or context.contains("建筑")
		or context.contains("房屋")
		or context.contains("小屋")
		or context.contains("楼房")
		or context.contains("塔楼")
		or context.contains("城楼")
		or context.contains("亭子")
	):
		return "crypt_small"
	if (
		context.contains("waterfall")
		or context.contains("water_fall")
		or context.contains("瀑布")
		or context.contains("水幕")
		or context.contains("水帘")
		or context.contains("跌水")
	):
		return "waterfall"
	if (
		context.contains("river_corner")
		or context.contains("river_turn")
		or context.contains("河湾")
		or context.contains("河道转角")
	):
		return "river_corner"
	if (
		context.contains("riverbank")
		or context.contains("river_bank")
		or context.contains("stone_bank")
		or context.contains("河岸")
		or context.contains("石岸")
		or context.contains("岸边")
	):
		return "riverbank"
	if (
		context.contains("river")
		or context.contains("stream")
		or context.contains("河流")
		or context.contains("河道")
		or context.contains("溪")
		or context.contains("溪流")
		or context.contains("水渠")
		or context.contains("水沟")
		or context.contains("水道")
		or context.contains("运河")
		or context.contains("护城河")
	):
		return "river_straight"
	if (
		context.contains("puddle")
		or context.contains("ripple")
		or context.contains("水坑")
		or context.contains("积水坑")
		or context.contains("涟漪")
	):
		return "puddle_ripple"
	if (
		context.contains("drain")
		or context.contains("outfall")
		or context.contains("排水口")
		or context.contains("下水口")
	):
		return "drain_outfall"
	if context.contains("fountain_square_detail"):
		return "fountain_square_detail"
	if context.contains("fountain_square"):
		return "fountain_square"
	if context.contains("fountain_center"):
		return "fountain_center"
	if context.contains("fountain_curved"):
		return "fountain_curved"
	if context.contains("fountain_edge"):
		return "fountain_edge"
	if context.contains("fountain_corner_inner_square"):
		return "fountain_corner_inner_square"
	if context.contains("fountain_corner_inner"):
		return "fountain_corner_inner"
	if context.contains("fountain_corner"):
		return "fountain_corner"
	if context.contains("fountain") or context.contains("喷泉"):
		return "fountain_round_detail"
	if (
		context.contains("water_surface")
		or context.contains("water")
		or context.contains("水面")
		or context.contains("积水")
		or context.contains("水景")
		or context.contains("水洼")
		or context.contains("雨水")
		or context.contains("水池")
		or context.contains("水塘")
		or context.contains("雨池")
	):
		return "water_surface"
	if context.contains("counter") or context.contains("desk") or context.contains("柜台") or context.contains("桌子"):
		return "dungeon_table"
	if (
		context.contains("pillar")
		or context.contains("column")
		or context.contains("石柱")
		or context.contains("柱子")
		or context.contains("立柱")
		or context.contains("圆柱")
		or context.contains("方柱")
		or context.contains("支撑柱")
		or context.contains("柱体")
	):
		return "stone_pillar_large"
	if kind == "gate":
		return "crypt_door" if semantic_id.contains("shortcut") else "crypt_large_door"
	if context.contains("doorway") or context.contains("door") or context.contains("门") or context.contains("门户"):
		return "simple_door"
	if context.contains("wall") or context.contains("墙") or context.contains("围挡"):
		return "town_wall"
	if (
		context.contains("floating")
		or context.contains("hover")
		or context.contains("platform")
		or context.contains("block")
		or context.contains("cube")
		or context.contains("悬浮")
		or context.contains("悬空")
		or context.contains("浮空")
		or context.contains("平台")
		or context.contains("方块")
		or context.contains("台阶")
		or context.contains("踏板")
		or context.contains("桥")
	):
		return "wood_planks"
	if behavior == "breakable" or semantic_id.contains("jar") or context.contains("jar"):
		return "urn_round"
	if behavior == "pushable" or context.contains("pushable_box"):
		return "cart"
	if context.contains("window"):
		return "town_window"
	if context.contains("sofa"):
		return "wood_altar"
	if context.contains("tv"):
		return "stone_altar"
	if context.contains("wardrobe"):
		return "crypt_small"
	if context.contains("lamp"):
		return "lightpost_single"
	if context.contains("plant"):
		return "pine"
	if context.contains("spirit_fire"):
		return "fire_basket"
	if context.contains("mist"):
		return "rocks"
	if kind == "objective" or kind == "boss":
		return "stone_altar"
	if kind == "case":
		return "dungeon_chest"
	if kind == "prop":
		return "dungeon_chest"
	if kind == "decor":
		return "grave_stone"
	return ""


static func recommended_model_for_node(p_host: Node) -> Dictionary:
	if not p_host.has_meta(Schema.META_KEY):
		return {}
	var value = p_host.get_meta(Schema.META_KEY)
	if not (value is Dictionary):
		return {}
	var data: Dictionary = value
	var art_keys: Array[String] = []
	for child in p_host.get_children():
		var child_name := str(child.name)
		if child_name.begins_with("art_key_"):
			art_keys.append(child_name.trim_prefix("art_key_"))
	var context_parts: Array[String] = []
	for tag in Schema.string_array(data.get("tags", [])):
		context_parts.append(tag)
	context_parts.append(str(p_host.name))
	context_parts.append(str(data.get("display_name", "")))
	var params = data.get("params", {})
	if params is Dictionary:
		for key in ["type", "style", "water_type", "visual_type"]:
			var value_part := str(params.get(key, "")).strip_edges()
			if not value_part.is_empty():
				context_parts.append(value_part)
	var model_id := recommended_model_id(
		str(data.get("kind", "")),
		str(data.get("behavior", "")),
		str(data.get("semantic_id", "")),
		art_keys,
		" ".join(context_parts)
	)
	var entry := find(model_id)
	if entry.is_empty():
		return entry

	var semantic_id := str(data.get("semantic_id", "")).to_lower()
	var context := " ".join(context_parts).to_lower()
	var node_context := "%s %s" % [semantic_id, context]
	if (
		semantic_id.contains("route_wall")
		or semantic_id.contains("route_gate")
		or context.contains("boundary")
		or context.contains("wall")
		or context.contains("墙")
		or str(data.get("behavior", "")) == "route_gate"
	):
		entry["fit_mode"] = "repeat_longest"
		entry["repeat_along_longest"] = true
		entry["max_repeat"] = 32
	elif str(data.get("behavior", "")) == "lift":
		entry["fit_mode"] = "stretch"
	elif context.contains("platform") or context.contains("floating") or context.contains("悬浮") or context.contains("平台"):
		entry["fit_mode"] = "stretch"
	elif str(data.get("behavior", "")) == "pressure_plate":
		entry["fit_mode"] = "stretch"
	elif node_context.contains("waterfall"):
		entry["fit_mode"] = "height"
	elif str(data.get("kind", "")) == "gate":
		entry["fit_mode"] = "height"
		entry["rotation_degrees"] = [0.0, 90.0, 0.0]
	elif str(data.get("kind", "")) == "decor" and context.contains("pillar"):
		entry["fit_mode"] = "contain"
	return entry


static func apply_recommended_model(p_host: Node, p_owner: Node = null) -> Dictionary:
	var entry := recommended_model_for_node(p_host)
	if entry.is_empty():
		return {"ok": false, "skipped": true, "error": "没有匹配的推荐模型。"}
	var result := apply_model(p_host, entry, p_owner)
	if not bool(result.get("ok", false)):
		return result
	var data := Schema.data_from_node(p_host)
	if data.is_empty():
		remove_model(p_host)
		return {"ok": false, "error": "语义宿主缺少 FIVESTAR 元数据。"}
	var params: Dictionary = data.get("params", {}).duplicate(true)
	params["visual"] = result.get("visual", {})
	data["params"] = params
	if str(data.get("display_name", "")).strip_edges().is_empty():
		data["display_name"] = str(entry.get("label", ""))
	data = Schema.apply_to_node(p_host, data)
	p_host.name = Schema.node_name(data)
	result["data"] = data
	result["entry"] = entry
	return result


static func apply_recommended_models(p_root: Node, p_owner: Node = null) -> Dictionary:
	var registered := _register_unmarked_recommended_hosts(p_root)
	var nodes: Array[Node] = []
	_collect_semantic_nodes(p_root, nodes)
	var applied := 0
	var repaired := 0
	var skipped := 0
	var failed := 0
	var errors: Array[String] = []
	for node in nodes:
		if not (node is Node3D):
			skipped += 1
			continue
		var existing_model_id := model_id_from_node(node)
		if not existing_model_id.is_empty():
			if is_model_visual_usable(node):
				# Scenes authored by older plugin versions can contain a valid
				# VISUAL_* child while the original MeshInstance3D placeholder is
				# still visible. Repair that overlap without replacing the model.
				if _placeholder_visibility_is_visible(node):
					_set_placeholder_visibility(node, false)
					repaired += 1
				else:
					skipped += 1
				continue
			var repaired_result := apply_recommended_model(node, p_owner)
			if bool(repaired_result.get("skipped", false)):
				skipped += 1
			elif bool(repaired_result.get("ok", false)):
				repaired += 1
			else:
				failed += 1
				errors.append("%s: %s" % [str(node.name), str(repaired_result.get("error", "未知错误"))])
			continue
		var result := apply_recommended_model(node, p_owner)
		if bool(result.get("skipped", false)):
			skipped += 1
		elif bool(result.get("ok", false)):
			applied += 1
		else:
			failed += 1
			errors.append("%s: %s" % [str(node.name), str(result.get("error", "未知错误"))])
	return {
		"ok": failed == 0,
		"registered": registered,
		"applied": applied,
		"repaired": repaired,
		"skipped": skipped,
		"failed": failed,
		"errors": errors,
		"remaining_unregistered": _collect_unregistered_host_names(p_root),
	}


static func _register_unmarked_recommended_hosts(p_root: Node) -> int:
	var registered := 0
	for child in p_root.get_children():
		registered += _register_unmarked_recommended_host(child, p_root)
	return registered


static func _register_unmarked_recommended_host(p_node: Node, p_root: Node) -> int:
	var node_name := str(p_node.name)
	if (
		node_name.begins_with(VISUAL_PREFIX)
		or node_name.begins_with(HIDDEN_VISUAL_PREFIX)
		or node_name.begins_with(AUTHORING_MARKER_PREFIX)
		or node_name.begins_with("@")
		or p_node is CollisionShape3D
		or p_node is Label3D
		or p_node is Camera3D
		or p_node is Light3D
	):
		return 0
	var registered := 0
	if (
		p_node is Node3D
		and not p_node.has_meta(Schema.META_KEY)
		and p_node.owner == p_root
		and not _has_semantic_ancestor(p_node, p_root)
	):
		var display_name := Schema.sanitize_display_name(node_name)
		var semantic_id := _unique_auto_visual_id(p_root, node_name)
		var context := "%s %s" % [node_name, _parent_name_context(p_node, p_root)]
		var recommended := recommended_model_id("", "", semantic_id, [], context)
		if not recommended.is_empty() and not display_name.is_empty():
			var data := Schema.make(
				semantic_id,
				"decor",
				"none",
				_zone_id_from_ancestor(p_node, p_root),
				["自动识别", "模型关键词"],
				[],
				{},
				display_name
			)
			data = Schema.apply_to_node(p_node, data)
			p_node.name = Schema.node_name(data)
			registered += 1
	for child in p_node.get_children():
		registered += _register_unmarked_recommended_host(child, p_root)
	return registered


static func _collect_unregistered_host_names(p_root: Node) -> Array[String]:
	var result: Array[String] = []
	_collect_unregistered_host_names_recursive(p_root, p_root, result)
	return result


static func _collect_unregistered_host_names_recursive(
	p_node: Node,
	p_root: Node,
	p_result: Array[String]
) -> void:
	for child in p_node.get_children():
		if child.has_meta(Schema.META_KEY):
			var data := Schema.data_from_node(child)
			if str(data.get("kind", "")) in ["zone", "region"]:
				_collect_unregistered_host_names_recursive(child, p_root, p_result)
			continue
		var child_name := str(child.name)
		var ignored := (
			child_name.begins_with(VISUAL_PREFIX)
			or child_name.begins_with(HIDDEN_VISUAL_PREFIX)
			or child_name.begins_with(AUTHORING_MARKER_PREFIX)
			or child_name.begins_with("@")
			or child is CollisionShape3D
			or child is Label3D
			or child is Camera3D
			or child is Light3D
		)
		if (
			not ignored
			and child is Node3D
			and child.owner == p_root
			and not _has_semantic_ancestor(child, p_root)
		):
			p_result.append(child_name)
		_collect_unregistered_host_names_recursive(child, p_root, p_result)


static func _has_semantic_ancestor(p_node: Node, p_root: Node) -> bool:
	var current := p_node.get_parent()
	while current and current != p_root:
		if current.has_meta(Schema.META_KEY):
			var data := Schema.data_from_node(current)
			# Zones and the region root are authoring containers. User-created objects
			# grouped under them still need semantic discovery. Behavior hosts remain
			# opaque so their generated visual children are not registered separately.
			if str(data.get("kind", "")) not in ["zone", "region"]:
				return true
		current = current.get_parent()
	return false


static func _parent_name_context(p_node: Node, p_root: Node) -> String:
	var parts: Array[String] = []
	var current := p_node.get_parent()
	while current and current != p_root:
		parts.append(str(current.name))
		current = current.get_parent()
	return " ".join(parts)


static func _unique_auto_visual_id(p_root: Node, p_name: String) -> String:
	var used: Dictionary = {}
	_collect_semantic_id_set(p_root, used)
	var base := Schema.sanitize_token("auto_%s" % p_name)
	var candidate := base
	var index := 2
	while used.has(candidate):
		candidate = Schema.sanitize_token("%s_%d" % [base, index])
		index += 1
	return candidate


static func _collect_semantic_id_set(p_node: Node, p_result: Dictionary) -> void:
	var data := Schema.data_from_node(p_node)
	var semantic_id := str(data.get("semantic_id", ""))
	if not semantic_id.is_empty():
		p_result[semantic_id] = true
	for child in p_node.get_children():
		_collect_semantic_id_set(child, p_result)


static func _zone_id_from_ancestor(p_node: Node, p_root: Node) -> String:
	var current: Node = p_node
	while current != null and current != p_root.get_parent():
		var data := Schema.data_from_node(current)
		if str(data.get("kind", "")) == "zone":
			return str(data.get("semantic_id", ""))
		var ancestor_zone := str(data.get("zone_id", ""))
		if not ancestor_zone.is_empty():
			return ancestor_zone
		current = current.get_parent()
	return ""


static func search(p_query: String, p_category: String = "") -> Array[Dictionary]:
	var query := p_query.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	for entry in all_entries():
		if not p_category.is_empty() and str(entry.get("category", "")) != p_category:
			continue
		if query.is_empty():
			result.append(entry)
			continue
		var haystack := "%s %s %s %s" % [
			str(entry.get("id", "")),
			str(entry.get("label", "")),
			str(entry.get("category", "")),
			" ".join(entry.get("tags", [])),
		]
		if haystack.to_lower().contains(query):
			result.append(entry)
	return result


static func visual_params(p_entry: Dictionary) -> Dictionary:
	return {
		"model_id": str(p_entry.get("id", "")),
		"label": str(p_entry.get("label", "")),
		"path": str(p_entry.get("path", "")),
		"scale": _vector3_to_array(p_entry.get("default_scale", Vector3.ONE)),
		"y_offset": float(p_entry.get("y_offset", 0.0)),
		"rotation_degrees": _vector3_to_array(p_entry.get("rotation_degrees", Vector3.ZERO)),
		"fit_mode": str(p_entry.get("fit_mode", "contain")),
		"placement": str(p_entry.get("placement", "ground")),
		"support_profile": _normalize_support_profile(
			str(p_entry.get("support_profile", "")),
			str(p_entry.get("id", "")),
			_string_array(p_entry.get("tags", [])),
			str(p_entry.get("path", ""))
		),
		"repeat_along_longest": bool(p_entry.get("repeat_along_longest", false)),
	}


static func placement_for_model_id(p_model_id: String) -> String:
	var entry := find(p_model_id)
	if not entry.is_empty():
		return str(entry.get("placement", "ground")).strip_edges().to_lower()
	return _default_placement_for_model_id(p_model_id)


static func _default_placement_for_model_id(p_model_id: String) -> String:
	var model_id := p_model_id.strip_edges().to_lower()
	if model_id in [
		"water_surface",
		"plunge_pool_foam",
		"puddle_ripple",
		"auto_fantasy_town_cloud",
	]:
		return "float"
	return "ground"


static func visual_node(p_host: Node) -> Node3D:
	if not p_host:
		return null
	for child in p_host.get_children():
		if str(child.name).begins_with(VISUAL_PREFIX) and child is Node3D:
			return child as Node3D
	return null


static func ground_model(p_host: Node) -> Dictionary:
	if not (p_host is Node3D):
		return {"ok": false, "error": "落地修正只能用于 Node3D 语义宿主。"}
	var visual := visual_node(p_host)
	if not visual:
		return {"ok": false, "skipped": true, "error": "选中宿主没有 VISUAL_ 模型。"}
	var data := Schema.data_from_node(p_host)
	var params: Dictionary = data.get("params", {}) if data.get("params", {}) is Dictionary else {}
	var visual_params_data: Dictionary = (
		params.get("visual", {})
		if params.get("visual", {}) is Dictionary
		else {}
	)
	var model_id := str(visual_params_data.get("model_id", "")).strip_edges()
	if model_id.is_empty():
		model_id = str(visual.name).trim_prefix(VISUAL_PREFIX).trim_prefix("auto_")
	var placement := str(visual_params_data.get("placement", "")).strip_edges().to_lower()
	if placement.is_empty():
		placement = placement_for_model_id(model_id)
	if placement == "float":
		return {"ok": true, "skipped": true, "placement": placement, "error": "显式浮动模型不落地。"}
	var target_aabb := _host_target_aabb(p_host as Node3D)
	var result := _align_visual_to_target(visual, target_aabb, {
		"placement": placement,
	})
	if not bool(result.get("ok", false)):
		return result
	return {
		"ok": true,
		"visual": visual,
		"placement": placement,
		"bottom_before": result.get("bottom_before", 0.0),
		"bottom_after": result.get("bottom_after", 0.0),
	}


static func ground_all_models(p_root: Node) -> Dictionary:
	if not p_root:
		return {"ok": false, "error": "没有可修正的场景根节点。"}
	var nodes: Array[Node] = []
	_collect_semantic_nodes(p_root, nodes)
	var corrected := 0
	var skipped := 0
	var failed := 0
	var errors: Array[String] = []
	for node in nodes:
		if not (node is Node3D):
			continue
		var result := ground_model(node)
		if bool(result.get("ok", false)):
			if bool(result.get("skipped", false)):
				skipped += 1
			else:
				corrected += 1
		else:
			failed += 1
			if str(result.get("error", "")) != "选中宿主没有 VISUAL_ 模型。":
				errors.append("%s: %s" % [str(node.name), str(result.get("error", "未知错误"))])
	return {
		"ok": failed == 0,
		"corrected": corrected,
		"skipped": skipped,
		"failed": failed,
		"errors": errors,
	}


static func apply_model(p_host: Node, p_entry: Dictionary, p_owner: Node = null) -> Dictionary:
	if not (p_host is Node3D):
		return {"ok": false, "error": "模型只能挂到 Node3D 语义宿主下。"}
	var path := str(p_entry.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return {"ok": false, "error": "模型资源不存在或尚未导入：%s" % path}
	var packed = ResourceLoader.load(path)
	if not (packed is PackedScene):
		return {"ok": false, "error": "模型不是 PackedScene：%s" % path}

	var target_aabb := _host_target_aabb(p_host as Node3D)
	var packed_scene := packed as PackedScene
	var visual_result := _build_visual(p_host as Node3D, packed_scene, p_entry, target_aabb)
	if not bool(visual_result.get("ok", false)):
		return visual_result
	var visual := visual_result.get("node") as Node3D
	# Build before removing the old visual so a failed replacement never leaves
	# an otherwise valid authoring host empty.
	remove_model(p_host, visual)
	visual.name = VISUAL_PREFIX + str(p_entry.get("id", "model"))
	_assign_visual_owner(visual, p_owner)
	_set_placeholder_visibility(p_host, false)
	ensure_support_collision(p_host, p_owner)

	var params := visual_params(p_entry)
	params["fitted_size"] = _vector3_to_array(visual_result.get("fitted_size", Vector3.ZERO))
	params["fit_scale"] = _vector3_to_array(visual_result.get("fit_scale", Vector3.ONE))
	params["repeat_count"] = int(visual_result.get("repeat_count", 1))
	return {
		"ok": true,
		"node": visual,
		"visual": params,
		"fit": visual_result,
	}


static func remove_model(p_host: Node, p_keep: Node = null) -> int:
	if not p_host:
		return 0
	remove_auto_support_collision(p_host)
	var removed := 0
	var visual_nodes: Array[Node] = []
	_collect_visual_descendants(p_host, visual_nodes, p_keep)
	var legacy_hosts: Array[Node] = []
	_collect_legacy_visual_hosts(p_host, legacy_hosts, p_keep)
	for child in visual_nodes:
		var parent := child.get_parent()
		if not parent:
			continue
		parent.remove_child(child)
		child.free()
		removed += 1
	for host in legacy_hosts:
		var parent := host.get_parent()
		if not parent:
			continue
		if not _subtree_has_authoring_payload(host):
			parent.remove_child(host)
			host.free()
	_restore_placeholder_visibility(p_host)
	return removed


static func model_id_from_node(p_host: Node) -> String:
	for child in p_host.get_children():
		var child_name := str(child.name)
		if child_name.begins_with(VISUAL_PREFIX):
			return child_name.trim_prefix(VISUAL_PREFIX)
	return ""


static func _collect_visual_descendants(
	p_node: Node,
	p_result: Array[Node],
	p_keep: Node
) -> void:
	for child in p_node.get_children():
		if child == p_keep:
			continue
		if str(child.name).begins_with(VISUAL_PREFIX):
			p_result.append(child)
			continue
		_collect_visual_descendants(child, p_result, p_keep)


static func _collect_legacy_visual_hosts(
	p_node: Node,
	p_result: Array[Node],
	p_keep: Node
) -> void:
	for child in p_node.get_children():
		if child == p_keep:
			continue
		if child.has_meta(Schema.META_KEY) and _contains_visual_descendant(child, p_keep):
			p_result.append(child)
		_collect_legacy_visual_hosts(child, p_result, p_keep)


static func _contains_visual_descendant(p_node: Node, p_keep: Node) -> bool:
	for child in p_node.get_children():
		if child == p_keep:
			continue
		if str(child.name).begins_with(VISUAL_PREFIX):
			return true
		if _contains_visual_descendant(child, p_keep):
			return true
	return false


static func _subtree_has_authoring_payload(p_node: Node) -> bool:
	for child in p_node.get_children():
		if child is VisualInstance3D or child is CollisionShape3D:
			return true
		if child.get_child_count() > 0 and _subtree_has_authoring_payload(child):
			return true
	return false


static func is_model_visual_usable(p_host: Node) -> bool:
	for child in p_host.get_children():
		if not str(child.name).begins_with(VISUAL_PREFIX):
			continue
		if not (child is Node3D):
			return false
		var visual := child as Node3D
		if visual.get_child_count() == 0:
			return false
		var bounds := _subtree_aabb(visual)
		return (
			bounds.size.x > 0.0001
			or bounds.size.y > 0.0001
			or bounds.size.z > 0.0001
		)
	return false


static func _build_visual(
	p_host: Node3D,
	p_packed_scene: PackedScene,
	p_entry: Dictionary,
	p_target_aabb: AABB
) -> Dictionary:
	var visual := Node3D.new()
	visual.name = VISUAL_PREFIX + str(p_entry.get("id", "model"))
	p_host.add_child(visual)

	var repeat_along_longest := bool(p_entry.get("repeat_along_longest", false))
	if repeat_along_longest:
		var repeated := _populate_repeated_tiles(visual, p_packed_scene, p_entry, p_target_aabb)
		if not bool(repeated.get("ok", false)):
			p_host.remove_child(visual)
			visual.free()
			return repeated
		return repeated

	var instance := p_packed_scene.instantiate()
	if not (instance is Node3D):
		instance.free()
		p_host.remove_child(visual)
		visual.free()
		return {"ok": false, "error": "模型根节点不是 Node3D：%s" % str(p_entry.get("path", ""))}
	var model := instance as Node3D
	model.name = "Model"
	visual.add_child(model)
	_apply_entry_transform(model, p_entry)
	var fitted := _fit_visual_to_target(visual, p_target_aabb, p_entry)
	return {
		"ok": true,
		"node": visual,
		"fitted_size": fitted.get("fitted_size", Vector3.ZERO),
		"fit_scale": fitted.get("fit_scale", Vector3.ONE),
		"repeat_count": 1,
	}


static func _populate_repeated_tiles(
	p_visual: Node3D,
	p_packed_scene: PackedScene,
	p_entry: Dictionary,
	p_target_aabb: AABB
) -> Dictionary:
	if p_target_aabb.size.x <= 0.0001 and p_target_aabb.size.z <= 0.0001:
		var fallback_instance := p_packed_scene.instantiate()
		if not (fallback_instance is Node3D):
			fallback_instance.free()
			return {"ok": false, "error": "点状宿主模型根节点不是 Node3D。"}
		var fallback_model := fallback_instance as Node3D
		fallback_model.name = "Model"
		p_visual.add_child(fallback_model)
		_apply_entry_transform(fallback_model, p_entry)
		var fitted := _fit_visual_to_target(p_visual, p_target_aabb, p_entry)
		return {
			"ok": true,
			"node": p_visual,
			"fitted_size": fitted.get("fitted_size", Vector3.ZERO),
			"fit_scale": fitted.get("fit_scale", Vector3.ONE),
			"repeat_count": 1,
		}
	var long_axis_is_x := p_target_aabb.size.x >= p_target_aabb.size.z
	var target_long := p_target_aabb.size.x if long_axis_is_x else p_target_aabb.size.z
	var target_short := p_target_aabb.size.z if long_axis_is_x else p_target_aabb.size.x
	var base_rotation := _vector3(p_entry.get("rotation_degrees", [0.0, 0.0, 0.0]), Vector3.ZERO)

	var probe := p_packed_scene.instantiate()
	if not (probe is Node3D):
		probe.free()
		return {"ok": false, "error": "长墙模型根节点不是 Node3D。"}
	var probe_node := probe as Node3D
	probe_node.rotation_degrees = base_rotation
	var base_aabb := _node_aabb_in_parent(probe_node)
	var base_size := base_aabb.size
	probe_node.free()
	if base_size.x <= 0.0001 or base_size.y <= 0.0001 or base_size.z <= 0.0001:
		return {"ok": false, "error": "长墙模型没有可用的包围盒。"}

	var extra_y := 0.0
	if long_axis_is_x and base_size.x < base_size.z:
		extra_y = 90.0
	elif not long_axis_is_x and base_size.z < base_size.x:
		extra_y = -90.0
	var rotation_degrees := base_rotation + Vector3(0.0, extra_y, 0.0)
	probe = p_packed_scene.instantiate()
	probe_node = probe as Node3D
	probe_node.rotation_degrees = rotation_degrees
	var rotated_aabb := _node_aabb_in_parent(probe_node)
	var rotated_size := rotated_aabb.size
	probe_node.free()

	var source_long := rotated_size.x if long_axis_is_x else rotated_size.z
	var source_short := rotated_size.z if long_axis_is_x else rotated_size.x
	if source_long <= 0.0001:
		return {"ok": false, "error": "长墙模型的长边尺寸无效。"}
	var scale_short := target_short / source_short
	var scale_height := p_target_aabb.size.y / rotated_size.y
	if scale_short <= 0.0001 or scale_height <= 0.0001:
		return {"ok": false, "error": "长墙模块的横截面尺寸无效。"}
	var repeat_count := clampi(
		int(round(target_long / maxf(0.001, source_long * scale_height))),
		1,
		int(p_entry.get("max_repeat", 24))
	)
	var scale_long := target_long / (source_long * float(repeat_count))
	var local_long_axis_is_z := base_size.z >= base_size.x
	var tile_scale := (
		Vector3(scale_short, scale_height, scale_long)
		if local_long_axis_is_z
		else Vector3(scale_long, scale_height, scale_short)
	)

	var first := p_packed_scene.instantiate() as Node3D
	if not first:
		return {"ok": false, "error": "长墙模型无法实例化。"}
	first.name = "Tile_00"
	first.rotation_degrees = rotation_degrees
	first.scale = tile_scale
	p_visual.add_child(first)
	var first_aabb := _node_aabb_in_parent(first)
	var target_center := p_target_aabb.get_center()
	var first_center := first_aabb.get_center()
	var base_position := Vector3(
		target_center.x - first_center.x,
		p_target_aabb.position.y - first_aabb.position.y,
		target_center.z - first_center.z
	)
	var stride := target_long / float(repeat_count)
	first.position = base_position + (
		Vector3(-(repeat_count - 1) * stride * 0.5, 0.0, 0.0)
		if long_axis_is_x
		else Vector3(0.0, 0.0, -(repeat_count - 1) * stride * 0.5)
	)

	for index in range(1, repeat_count):
		var tile := p_packed_scene.instantiate() as Node3D
		if not tile:
			continue
		tile.name = "Tile_%02d" % index
		tile.rotation_degrees = rotation_degrees
		tile.scale = tile_scale
		tile.position = base_position + (
			Vector3((float(index) - (repeat_count - 1) * 0.5) * stride, 0.0, 0.0)
			if long_axis_is_x
			else Vector3(0.0, 0.0, (float(index) - (repeat_count - 1) * 0.5) * stride)
		)
		p_visual.add_child(tile)

	var fitted_aabb := _node_aabb_in_parent(p_visual)
	return {
		"ok": true,
		"node": p_visual,
		"fitted_size": fitted_aabb.size,
		"fit_scale": tile_scale,
		"repeat_count": repeat_count,
	}


static func _fit_visual_to_target(
	p_visual: Node3D,
	p_target_aabb: AABB,
	p_entry: Dictionary
) -> Dictionary:
	var mode := str(p_entry.get("fit_mode", "contain")).to_lower()
	var source_aabb := _node_aabb_in_parent(p_visual)
	var fit_scale := Vector3.ONE
	var source_valid := (
		source_aabb.size.x > 0.0001
		and source_aabb.size.y > 0.0001
		and source_aabb.size.z > 0.0001
	)
	var target_valid := (
		p_target_aabb.size.x > 0.0001
		and p_target_aabb.size.y > 0.0001
		and p_target_aabb.size.z > 0.0001
	)
	if source_valid and target_valid:
		match mode:
			"stretch":
				fit_scale = p_target_aabb.size / source_aabb.size
			"height":
				var height_scale := p_target_aabb.size.y / source_aabb.size.y
				fit_scale = Vector3.ONE * height_scale
			"none":
				fit_scale = Vector3.ONE
			_:
				var uniform_scale := minf(
					p_target_aabb.size.x / source_aabb.size.x,
					minf(
						p_target_aabb.size.y / source_aabb.size.y,
						p_target_aabb.size.z / source_aabb.size.z
					)
				)
				fit_scale = Vector3.ONE * uniform_scale * 0.98
		fit_scale.x = maxf(0.0001, fit_scale.x)
		fit_scale.y = maxf(0.0001, fit_scale.y)
		fit_scale.z = maxf(0.0001, fit_scale.z)
		p_visual.scale *= fit_scale
	var alignment := _align_visual_to_target(p_visual, p_target_aabb, p_entry)
	return {
		"fitted_size": _node_aabb_in_parent(p_visual).size,
		"fit_scale": fit_scale,
		"alignment": alignment,
	}


static func _align_visual_to_target(
	p_visual: Node3D,
	p_target_aabb: AABB,
	p_entry: Dictionary
) -> Dictionary:
	var visual_aabb := _node_aabb_in_parent(p_visual)
	var visual_valid := (
		visual_aabb.size.x > 0.0001
		or visual_aabb.size.y > 0.0001
		or visual_aabb.size.z > 0.0001
	)
	if not visual_valid:
		return {"ok": false, "error": "模型包围盒为空，无法修正落地。"}
	var target_valid := (
		p_target_aabb.size.x > 0.0001
		and p_target_aabb.size.y > 0.0001
		and p_target_aabb.size.z > 0.0001
	)
	var bottom_before := visual_aabb.position.y
	var center := visual_aabb.get_center()
	var horizontal_target := p_target_aabb.get_center() if target_valid else Vector3.ZERO
	p_visual.position.x += horizontal_target.x - center.x
	p_visual.position.z += horizontal_target.z - center.z
	var placement := str(p_entry.get("placement", "ground")).strip_edges().to_lower()
	if placement.is_empty():
		var model_id := str(p_entry.get("id", "")).strip_edges()
		placement = placement_for_model_id(model_id) if not model_id.is_empty() else "ground"
	if placement != "float":
		var ground_y := p_target_aabb.position.y if target_valid else 0.0
		p_visual.position.y += ground_y - visual_aabb.position.y
	var bottom_after := _node_aabb_in_parent(p_visual).position.y
	return {
		"ok": true,
		"placement": placement,
		"bottom_before": bottom_before,
		"bottom_after": bottom_after,
	}


static func _apply_entry_transform(p_node: Node3D, p_entry: Dictionary) -> void:
	p_node.position = Vector3(0.0, float(p_entry.get("y_offset", 0.0)), 0.0)
	p_node.rotation_degrees = _vector3(p_entry.get("rotation_degrees", [0.0, 0.0, 0.0]), Vector3.ZERO)
	p_node.scale = _vector3(p_entry.get("default_scale", [1.0, 1.0, 1.0]), Vector3.ONE)


static func _set_placeholder_visibility(p_host: Node, p_visible: bool) -> void:
	if p_visible:
		_restore_placeholder_visibility(p_host)
		return
	if p_host is MeshInstance3D:
		var host_mesh := p_host as MeshInstance3D
		if not host_mesh.has_meta(HOST_MESH_META):
			host_mesh.set_meta(HOST_MESH_META, host_mesh.mesh)
			host_mesh.set_meta(HOST_HAS_MATERIAL_OVERRIDE_META, host_mesh.material_override != null)
			if host_mesh.material_override:
				host_mesh.set_meta(HOST_MATERIAL_OVERRIDE_META, host_mesh.material_override)
			host_mesh.set_meta(HOST_HAS_MATERIAL_OVERLAY_META, host_mesh.material_overlay != null)
			if host_mesh.material_overlay:
				host_mesh.set_meta(HOST_MATERIAL_OVERLAY_META, host_mesh.material_overlay)
		host_mesh.mesh = null
		host_mesh.material_override = null
		host_mesh.material_overlay = null

	var visuals: Array[VisualInstance3D] = []
	_collect_placeholder_visuals(p_host, visuals)
	for visual in visuals:
		if not visual.has_meta(HIDDEN_VISIBLE_META):
			visual.set_meta(HIDDEN_VISIBLE_META, visual.visible)
		visual.visible = false


static func _placeholder_visibility_is_visible(p_host: Node) -> bool:
	if p_host is MeshInstance3D and (p_host as MeshInstance3D).mesh != null:
		return true
	var visuals: Array[VisualInstance3D] = []
	_collect_placeholder_visuals(p_host, visuals)
	for visual in visuals:
		if visual.visible:
			return true
	return false


static func _restore_placeholder_visibility(p_host: Node) -> void:
	if p_host is MeshInstance3D and p_host.has_meta(HOST_MESH_META):
		var host_mesh := p_host as MeshInstance3D
		host_mesh.mesh = host_mesh.get_meta(HOST_MESH_META)
		if bool(host_mesh.get_meta(HOST_HAS_MATERIAL_OVERRIDE_META, false)):
			host_mesh.material_override = host_mesh.get_meta(HOST_MATERIAL_OVERRIDE_META)
		else:
			host_mesh.material_override = null
		if bool(host_mesh.get_meta(HOST_HAS_MATERIAL_OVERLAY_META, false)):
			host_mesh.material_overlay = host_mesh.get_meta(HOST_MATERIAL_OVERLAY_META)
		else:
			host_mesh.material_overlay = null
		for key in [
			HOST_MESH_META,
			HOST_HAS_MATERIAL_OVERRIDE_META,
			HOST_MATERIAL_OVERRIDE_META,
			HOST_HAS_MATERIAL_OVERLAY_META,
			HOST_MATERIAL_OVERLAY_META,
		]:
			host_mesh.remove_meta(key)

	var visuals: Array[VisualInstance3D] = []
	_collect_placeholder_visuals(p_host, visuals)
	for visual in visuals:
		if visual.has_meta(HIDDEN_VISIBLE_META):
			visual.visible = bool(visual.get_meta(HIDDEN_VISIBLE_META))
			visual.remove_meta(HIDDEN_VISIBLE_META)


static func _collect_placeholder_visuals(p_node: Node, p_result: Array[VisualInstance3D]) -> void:
	for child in p_node.get_children():
		if child is VisualInstance3D:
			var child_name := str(child.name)
			if (
				child_name.begins_with(HIDDEN_VISUAL_PREFIX)
				or child_name.begins_with(HIDDEN_VISUAL_ALT_PREFIX)
				or child.has_meta(HIDDEN_VISIBLE_META)
			):
				p_result.append(child as VisualInstance3D)
		_collect_placeholder_visuals(child, p_result)


static func _host_target_aabb(p_host: Node3D) -> AABB:
	var accumulator := {"aabb": AABB(), "has_bounds": false}
	if p_host is MeshInstance3D:
		var host_mesh := p_host as MeshInstance3D
		var source_mesh: Mesh = host_mesh.mesh
		if source_mesh == null and host_mesh.has_meta(HOST_MESH_META):
			source_mesh = host_mesh.get_meta(HOST_MESH_META) as Mesh
		if source_mesh:
			_accumulate_host_bounds(accumulator, source_mesh.get_aabb(), Transform3D.IDENTITY)
	for child in p_host.get_children():
		if str(child.name).begins_with(VISUAL_PREFIX):
			continue
		if str(child.name).begins_with(EFFECT_PREFIX):
			continue
		if str(child.name).begins_with(AUTHORING_MARKER_PREFIX):
			continue
		if _is_auto_support_node(child):
			continue
		_collect_host_bounds(p_host, child, accumulator)
	return accumulator["aabb"] if bool(accumulator["has_bounds"]) else AABB()


static func _collect_host_bounds(
	p_root: Node3D,
	p_node: Node,
	p_accumulator: Dictionary
) -> void:
	if (
		str(p_node.name).begins_with(VISUAL_PREFIX)
		or str(p_node.name).begins_with(EFFECT_PREFIX)
	):
		return
	if str(p_node.name).begins_with(AUTHORING_MARKER_PREFIX):
		return
	if _is_auto_support_node(p_node):
		return
	if p_node is CollisionShape3D:
		var collision := p_node as CollisionShape3D
		if collision.shape:
			var shape_bounds := _shape_aabb(collision.shape)
			var transformed := _transform_aabb(shape_bounds, _relative_transform(p_root, collision))
			_accumulate_host_bounds(p_accumulator, transformed, Transform3D.IDENTITY)
	elif p_node is VisualInstance3D and not (p_node is Label3D):
		var visual := p_node as VisualInstance3D
		if visual.has_method("get_aabb"):
			var visual_bounds = visual.call("get_aabb")
			if visual_bounds is AABB:
				var transformed := _transform_aabb(visual_bounds, _relative_transform(p_root, visual))
				_accumulate_host_bounds(p_accumulator, transformed, Transform3D.IDENTITY)
	for child in p_node.get_children():
		_collect_host_bounds(p_root, child, p_accumulator)


static func _accumulate_host_bounds(
	p_accumulator: Dictionary,
	p_bounds: AABB,
	p_transform: Transform3D
) -> void:
	var transformed := _transform_aabb(p_bounds, p_transform) if p_transform != Transform3D.IDENTITY else p_bounds
	if bool(p_accumulator.get("has_bounds", false)):
		p_accumulator["aabb"] = (p_accumulator["aabb"] as AABB).merge(transformed)
	else:
		p_accumulator["aabb"] = transformed
		p_accumulator["has_bounds"] = true


static func _node_aabb_in_parent(p_node: Node3D) -> AABB:
	return _transform_aabb(_subtree_aabb(p_node), p_node.transform)


static func _subtree_aabb(p_node: Node3D) -> AABB:
	var result := AABB()
	var has_bounds := false
	if p_node is MeshInstance3D and (p_node as MeshInstance3D).mesh:
		result = (p_node as MeshInstance3D).get_aabb()
		has_bounds = true
	for child in p_node.get_children():
		if not (child is Node3D):
			continue
		var child_node := child as Node3D
		var child_bounds := _node_aabb_in_parent(child_node)
		result = result.merge(child_bounds) if has_bounds else child_bounds
		has_bounds = true
	return result


static func _relative_transform(p_root: Node3D, p_node: Node3D) -> Transform3D:
	var result := p_node.transform
	var current := p_node.get_parent()
	while current and current != p_root:
		if current is Node3D:
			result = (current as Node3D).transform * result
		current = current.get_parent()
	return result


static func _shape_aabb(p_shape: Shape3D) -> AABB:
	if p_shape is BoxShape3D:
		var size := (p_shape as BoxShape3D).size
		return AABB(-size * 0.5, size)
	if p_shape is SphereShape3D:
		var radius := (p_shape as SphereShape3D).radius
		return AABB(Vector3.ONE * -radius, Vector3.ONE * radius * 2.0)
	if p_shape is CylinderShape3D:
		var cylinder := p_shape as CylinderShape3D
		return AABB(
			Vector3(-cylinder.radius, -cylinder.height * 0.5, -cylinder.radius),
			Vector3(cylinder.radius * 2.0, cylinder.height, cylinder.radius * 2.0)
		)
	if p_shape is CapsuleShape3D:
		var capsule := p_shape as CapsuleShape3D
		return AABB(
			Vector3(-capsule.radius, -capsule.height * 0.5, -capsule.radius),
			Vector3(capsule.radius * 2.0, capsule.height, capsule.radius * 2.0)
		)
	return AABB()


static func _transform_aabb(p_aabb: AABB, p_transform: Transform3D) -> AABB:
	var result := AABB(p_transform * p_aabb.position, Vector3.ZERO)
	for x in [p_aabb.position.x, p_aabb.end.x]:
		for y in [p_aabb.position.y, p_aabb.end.y]:
			for z in [p_aabb.position.z, p_aabb.end.z]:
				result = result.expand(p_transform * Vector3(x, y, z))
	return result


static func _assign_visual_owner(p_visual: Node3D, p_owner: Node) -> void:
	if not p_owner or not p_owner.is_ancestor_of(p_visual):
		return
	p_visual.owner = p_owner
	# PackedScene instances must keep ownership of their internal nodes. Only
	# their roots belong to the authoring scene, otherwise Godot serializes the
	# instance contents a second time and reports duplicate node-name conflicts.
	for child in p_visual.get_children():
		if not child.scene_file_path.is_empty():
			child.owner = p_owner


static func _collect_semantic_nodes(p_node: Node, p_result: Array[Node]) -> void:
	if p_node.has_meta(Schema.META_KEY):
		p_result.append(p_node)
	for child in p_node.get_children():
		_collect_semantic_nodes(child, p_result)


static func _vector3(p_value, p_default: Vector3) -> Vector3:
	if not (p_value is Array or p_value is PackedFloat32Array or p_value is PackedFloat64Array):
		return p_default
	if p_value.size() < 3:
		return p_default
	return Vector3(float(p_value[0]), float(p_value[1]), float(p_value[2]))


static func _vector3_to_array(p_value) -> Array:
	if p_value is Vector3:
		return [p_value.x, p_value.y, p_value.z]
	if p_value is Array and p_value.size() >= 3:
		return [float(p_value[0]), float(p_value[1]), float(p_value[2])]
	return [1.0, 1.0, 1.0]


static func _string_array(p_value) -> Array[String]:
	var result: Array[String] = []
	if p_value == null:
		return result
	if p_value is String:
		for part in p_value.split(",", false):
			var value := str(part).strip_edges()
			if not value.is_empty() and not result.has(value):
				result.append(value)
		return result
	if p_value is Array or p_value is PackedStringArray:
		for part in p_value:
			var value := str(part).strip_edges()
			if not value.is_empty() and not result.has(value):
				result.append(value)
	return result
