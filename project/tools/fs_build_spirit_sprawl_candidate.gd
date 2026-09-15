extends SceneTree

const Schema := preload("res://scripts/authoring/FSAuthoringSchema.gd")
const VisualCatalog := preload("res://scripts/authoring/FSVisualCatalog.gd")
const EnvironmentCatalog := preload("res://scripts/authoring/FSEnvironmentCatalog.gd")
const SceneManifest := preload("res://scripts/authoring/FSSceneManifest.gd")

const OUTPUT_PATH := "res://authoring/scenes/spirit_sprawl_candidate.tscn"
const REGION_ID := "spirit_sprawl_candidate"
const DISPLAY_NAME := "雨夜灵潮废墟候选场景"

var scene_root: Node3D
var build_errors: Array[String] = []
var model_hosts := 0
var model_ok := 0
var environment_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	scene_root = Node3D.new()
	scene_root.name = "FS_REGION_%s" % REGION_ID.to_upper()
	root.add_child(scene_root)
	_mark_region_root()
	_build_water_and_atmosphere()
	_build_upper_ruin()
	_build_left_mass()
	_build_central_bridge_and_river()
	_build_lower_gate_tower()
	_build_right_platform()
	_build_southeast_block()
	_add_preview_cameras()
	_add_world_environment()
	_assign_owner(scene_root, scene_root)

	var packed := PackedScene.new()
	var pack_error := packed.pack(scene_root)
	if pack_error != OK:
		push_error("候选场景打包失败：%s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(packed, OUTPUT_PATH)
	if save_error != OK:
		push_error("候选场景保存失败：%s" % error_string(save_error))
		quit(1)
		return
	var manifest := SceneManifest.build(scene_root, OUTPUT_PATH, REGION_ID)
	var manifest_write := SceneManifest.write_manifest(manifest, "res://authoring")
	if not bool(manifest_write.get("ok", false)):
		build_errors.append("候选场景清单写入失败：%s" % str(manifest_write.get("error", "未知错误")))
	var manifest_validation: Dictionary = manifest.get("validation", {})
	for validation_error in manifest_validation.get("errors", []):
		build_errors.append("候选场景清单校验失败：%s" % str(validation_error))

	var semantic_count := _count_semantic_nodes(scene_root)
	print(
		"FS_SPIRIT_SPRAWL_CANDIDATE path=%s semantic=%d model_hosts=%d model_ok=%d environments=%d errors=%d manifest=%s" % [
			OUTPUT_PATH,
			semantic_count,
			model_hosts,
			model_ok,
			environment_count,
			build_errors.size(),
			str(manifest_write.get("json_path", "")),
		]
	)
	for error in build_errors:
		push_error(error)
	quit(0 if build_errors.is_empty() else 1)


func _mark_region_root() -> void:
	var data := Schema.make(
		REGION_ID,
		"region",
		"none",
		REGION_ID,
		["候选", "雨城", "顶视参考", "完整场景"],
		[],
		{"layout": "top_view_reference", "locked_authoring_scene": "first_night_authoring"},
		DISPLAY_NAME
	)
	Schema.apply_to_node(scene_root, data)


func _build_water_and_atmosphere() -> void:
	var water := _add_zone(
		scene_root,
		"water_and_atmosphere",
		"外围水面与氛围",
		["水体", "雨", "远景", "氛围"]
	)
	_add_model(
		water,
		"water_surface_main",
		"主水面",
		"decor",
		"water_and_atmosphere",
		"water_surface",
		Vector3(0.0, -0.22, 0.0),
		Vector3(48.0, 0.08, 58.0),
		Vector3.ZERO,
		["水面", "雨夜", "外围"],
		false,
		"float"
	)
	_add_model(
		water,
		"river_vertical_main",
		"中央主河道",
		"decor",
		"water_and_atmosphere",
		"river_straight",
		Vector3(2.2, -0.12, 0.0),
		Vector3(5.8, 0.12, 31.0),
		Vector3.ZERO,
		["河流", "中央", "重复拼片"],
		true
	)
	_add_model(
		water,
		"river_upper_channel",
		"上层横向水道",
		"decor",
		"water_and_atmosphere",
		"river_calm_straight",
		Vector3(-3.0, -0.1, -1.4),
		Vector3(35.0, 0.1, 5.2),
		Vector3.ZERO,
		["河流", "上层", "平静"],
		true
	)
	_add_model(
		water,
		"river_lower_basin",
		"下层门塔水湾",
		"decor",
		"water_and_atmosphere",
		"river_rapids_straight",
		Vector3(1.5, -0.08, 13.2),
		Vector3(19.0, 0.1, 9.5),
		Vector3.ZERO,
		["河流", "下层", "急流"],
		true
	)
	_add_model(
		water,
		"river_east_branch",
		"东侧支流",
		"decor",
		"water_and_atmosphere",
		"river_corner",
		Vector3(10.0, -0.08, 5.4),
		Vector3(16.0, 0.1, 5.2),
		Vector3.ZERO,
		["河流", "东侧", "转角"],
		false
	)
	_add_model(
		water,
		"riverbank_south",
		"南侧河岸",
		"decor",
		"water_and_atmosphere",
		"riverbank",
		Vector3(0.0, -0.06, 19.5),
		Vector3(37.0, 0.18, 1.1),
		Vector3.ZERO,
		["河岸", "南侧", "边界"],
		true
	)
	for index in range(6):
		var x := -16.0 + float(index) * 6.4
		_add_environment(
			water,
			"rain_sheet",
			"雨幕_%02d" % (index + 1),
			Vector3(x, 5.8, -2.0 if index % 2 == 0 else 6.0)
		)
	for index in range(4):
		_add_environment(
			water,
			"ground_fog",
			"地面雾_%02d" % (index + 1),
			Vector3(-13.0 if index % 2 == 0 else 11.0, -0.05, -12.0 + float(index) * 9.0)
		)
	_add_environment(water, "cloud_layer", "低云层_西", Vector3(-13.0, 7.5, -12.0))
	_add_environment(water, "cloud_layer", "低云层_东", Vector3(12.0, 7.2, -5.0))
	_add_environment(water, "wind_lines", "环境风线_上层", Vector3(-4.0, 3.2, -10.5))
	_add_environment(water, "wind_lines", "环境风线_下层", Vector3(3.0, 2.4, 10.5))
	_add_environment(water, "dust_motes", "湿冷尘埃_中央", Vector3(1.0, 2.0, 0.0))
	_add_environment(water, "moonlight", "月光", Vector3(0.0, 12.0, 0.0))


func _build_upper_ruin() -> void:
	var upper := _add_zone(
		scene_root,
		"upper_ruin_complex",
		"上层废墟主廊",
		["上层", "主廊", "分支", "窄平台"]
	)
	_add_platform(
		upper,
		"upper_main_deck",
		"上层主平台",
		"upper_ruin_complex",
		Vector3(-8.2, 0.0, -12.2),
		Vector3(13.2, 0.38, 4.8),
		["上层", "横向主路", "重复地板"],
		true
	)
	_add_platform(
		upper,
		"upper_east_arm",
		"上层东支路",
		"upper_ruin_complex",
		Vector3(2.1, 0.0, -12.8),
		Vector3(8.8, 0.34, 2.7),
		["上层", "东支路", "窄平台"],
		true
	)
	_add_platform(
		upper,
		"upper_east_round",
		"上层东端平台",
		"upper_ruin_complex",
		Vector3(8.3, 0.0, -12.5),
		Vector3(3.8, 0.34, 4.2),
		["上层", "东端", "观景台"],
		true
	)
	_add_platform(
		upper,
		"upper_south_branch",
		"上层南支路",
		"upper_ruin_complex",
		Vector3(-9.9, 0.0, -8.2),
		Vector3(3.2, 0.34, 5.1),
		["上层", "南支路", "窄平台"],
		true
	)
	_add_platform(
		upper,
		"upper_bridge_junction",
		"上层桥口",
		"upper_ruin_complex",
		Vector3(-3.8, 0.0, -8.5),
		Vector3(6.8, 0.34, 2.6),
		["上层", "桥口", "连接"],
		true
	)
	_add_model(
		upper,
		"upper_dirt_patch_a",
		"上层湿泥补面",
		"decor",
		"upper_ruin_complex",
		"dungeon_dirt",
		Vector3(-11.2, 0.41, -12.1),
		Vector3(2.8, 0.05, 2.0),
		Vector3.ZERO,
		["湿泥", "地面装饰"],
		false
	)
	_add_model(
		upper,
		"upper_detail_patch_a",
		"上层石板花纹",
		"decor",
		"upper_ruin_complex",
		"dungeon_floor_detail",
		Vector3(-5.0, 0.41, -11.6),
		Vector3(2.6, 0.05, 1.9),
		Vector3.ZERO,
		["石板", "花纹", "地面装饰"],
		false
	)
	_add_model(
		upper,
		"upper_dirt_patch_b",
		"东端湿泥补面",
		"decor",
		"upper_ruin_complex",
		"dungeon_dirt",
		Vector3(8.2, 0.37, -12.4),
		Vector3(2.2, 0.05, 2.2),
		Vector3.ZERO,
		["湿泥", "东端"],
		false
	)
	_add_puddle(upper, "upper_puddle_a", "上层积水一", "upper_ruin_complex", Vector3(-8.3, 0.39, -12.0), Vector3(2.6, 0.04, 1.2))
	_add_puddle(upper, "upper_puddle_b", "上层积水二", "upper_ruin_complex", Vector3(2.2, 0.35, -12.8), Vector3(2.1, 0.04, 1.0))
	_add_edge_run(upper, "upper_north_border", "上层北侧路缘", "upper_ruin_complex", Vector3(-14.5, 0.38, -14.6), Vector3(-1.6, 0.38, -14.6))
	_add_edge_run(upper, "upper_south_border", "上层南侧路缘", "upper_ruin_complex", Vector3(-14.5, 0.38, -9.8), Vector3(-12.5, 0.38, -9.8))
	_add_edge_run(upper, "upper_east_border", "东支路南侧路缘", "upper_ruin_complex", Vector3(-2.2, 0.35, -11.5), Vector3(6.5, 0.35, -11.5))
	_add_edge_run(upper, "upper_round_edge", "东端外缘", "upper_ruin_complex", Vector3(10.1, 0.35, -14.4), Vector3(10.1, 0.35, -10.6))
	for x in [-13.8, -11.8, -6.0, -3.4, 0.6, 3.7, 8.6]:
		_add_prop(upper, "upper_column_%s" % str(x).replace("-", "m").replace(".", "_"), "上层残柱", "upper_ruin_complex", "dungeon_column", Vector3(x, 0.38, -14.1), Vector3(0.62, 1.8, 0.62))
	for x in [-12.8, -7.6, -4.7, 2.7, 7.1]:
		_add_prop(upper, "upper_wall_stub_%s" % str(x).replace("-", "m").replace(".", "_"), "上层断墙", "upper_ruin_complex", "dungeon_wall_half", Vector3(x, 0.38, -9.9), Vector3(1.8, 1.1, 0.42))
	_add_prop(upper, "upper_pine_west", "上层西松", "upper_ruin_complex", "pine_crooked", Vector3(-13.8, 0.38, -11.7), Vector3(1.8, 2.6, 1.8))
	_add_prop(upper, "upper_pine_east", "上层东松", "upper_ruin_complex", "pine", Vector3(8.8, 0.35, -13.4), Vector3(1.8, 2.8, 1.8))
	_add_prop(upper, "upper_rocks", "上层碎石", "upper_ruin_complex", "rocks", Vector3(-10.9, 0.38, -10.5), Vector3(2.2, 0.8, 2.0))


func _build_left_mass() -> void:
	var left := _add_zone(
		scene_root,
		"left_wet_platform",
		"左侧厚重湿台",
		["左侧", "厚平台", "水车", "瀑布"]
	)
	_add_platform(
		left,
		"left_main_deck",
		"左侧主平台",
		"left_wet_platform",
		Vector3(-13.0, 0.0, 0.4),
		Vector3(6.8, 0.46, 9.6),
		["左侧", "厚重平台", "重复地板"],
		true
	)
	_add_platform(
		left,
		"left_north_apron",
		"左侧北侧缓台",
		"left_wet_platform",
		Vector3(-11.7, 0.0, -4.7),
		Vector3(4.6, 0.36, 3.0),
		["左侧", "缓台", "连接"],
		true
	)
	_add_model(
		left,
		"left_road_slope",
		"左侧连接坡道",
		"floor",
		"left_wet_platform",
		"road_slope",
		Vector3(-10.5, 0.78, -6.6),
		Vector3(3.1, 1.2, 4.0),
		Vector3(0.0, 90.0, 0.0),
		["坡道", "连接", "左侧"],
		false
	)
	_add_edge_run(left, "left_west_edge", "左侧西缘", "left_wet_platform", Vector3(-16.5, 0.46, -4.0), Vector3(-16.5, 0.46, 5.1))
	_add_edge_run(left, "left_east_edge", "左侧东缘", "left_wet_platform", Vector3(-9.5, 0.46, -3.8), Vector3(-9.5, 0.46, 3.6))
	_add_edge_run(left, "left_south_edge", "左侧南缘", "left_wet_platform", Vector3(-16.3, 0.46, 5.2), Vector3(-9.6, 0.46, 5.2))
	_add_wall_run(left, "left_north_wall", "左侧北墙", "left_wet_platform", Vector3(-15.8, 0.46, -4.3), Vector3(-12.8, 0.46, -4.3), 1.35, "dungeon_wall_half")
	_add_wall_run(left, "left_south_wall", "左侧南墙", "left_wet_platform", Vector3(-14.8, 0.46, 5.0), Vector3(-11.6, 0.46, 5.0), 1.05, "dungeon_wall_half")
	for z in [-2.7, 0.5, 3.4]:
		_add_prop(left, "left_column_%s" % str(z).replace("-", "m").replace(".", "_"), "左侧支撑柱", "left_wet_platform", "stone_pillar_large", Vector3(-15.6, 0.46, z), Vector3(0.7, 2.2, 0.7))
	for x in [-15.4, -12.5]:
		_add_prop(left, "left_wood_support_%s" % str(x).replace("-", "m").replace(".", "_"), "左侧木支撑", "left_wet_platform", "wood_support", Vector3(x, 0.46, 1.8), Vector3(1.0, 1.8, 1.0))
	_add_prop(left, "left_watermill", "左侧水车", "left_wet_platform", "watermill_wide", Vector3(-11.7, 0.46, 3.3), Vector3(3.8, 2.7, 2.0), Vector3(0.0, 90.0, 0.0))
	_add_waterfall(left, "left_waterfall", "左侧瀑布", "left_wet_platform", Vector3(-16.4, -0.25, 1.6), Vector3(2.4, 3.08, 0.18), 2.1)
	_add_waterfall(left, "left_waterfall_wide", "左侧宽瀑布", "left_wet_platform", Vector3(-16.2, -0.25, -2.7), Vector3(4.6, 3.08, 0.18), 2.1)
	_add_puddle(left, "left_puddle_a", "左侧积水一", "left_wet_platform", Vector3(-13.6, 0.47, -1.8), Vector3(2.8, 0.04, 1.4))
	_add_puddle(left, "left_puddle_b", "左侧积水二", "left_wet_platform", Vector3(-11.2, 0.47, 0.5), Vector3(2.0, 0.04, 1.3))
	_add_prop(left, "left_rocks", "左侧湿石", "left_wet_platform", "rock_wide", Vector3(-14.8, 0.46, 4.2), Vector3(2.2, 1.0, 1.5))
	_add_prop(left, "left_pine", "左侧松树", "left_wet_platform", "pine", Vector3(-12.1, 0.46, -3.6), Vector3(1.7, 2.6, 1.7))


func _build_central_bridge_and_river() -> void:
	var bridge := _add_zone(
		scene_root,
		"central_bridge_channel",
		"中央竖桥与水道",
		["中央", "桥", "水道", "纵向连接"]
	)
	_add_platform(
		bridge,
		"central_bridge_deck",
		"中央木桥",
		"central_bridge_channel",
		Vector3(1.5, 0.0, 0.0),
		Vector3(2.7, 0.34, 11.4),
		["中央", "木桥", "纵向"],
		true
	)
	_add_model(
		bridge,
		"central_bridge_planks",
		"中央桥面木板",
		"decor",
		"central_bridge_channel",
		"wood_planks",
		Vector3(1.5, 0.2, 0.0),
		Vector3(2.5, 0.08, 10.8),
		Vector3.ZERO,
		["木板", "桥面"],
		false
	)
	_add_model(
		bridge,
		"central_channel_flow",
		"桥下水道",
		"decor",
		"central_bridge_channel",
		"water_flow_sheet",
		Vector3(1.5, -0.05, 0.0),
		Vector3(1.8, 0.06, 11.2),
		Vector3.ZERO,
		["水流面片", "桥下", "纵向"],
		false,
		"float"
	)
	_add_wall_run(bridge, "bridge_west_rail", "桥西护栏", "central_bridge_channel", Vector3(0.35, 0.2, -5.0), Vector3(0.35, 0.2, 5.0), 0.72, "wood_wall_slope")
	_add_wall_run(bridge, "bridge_east_rail", "桥东护栏", "central_bridge_channel", Vector3(2.65, 0.2, -5.0), Vector3(2.65, 0.2, 5.0), 0.72, "wood_wall_slope")
	_add_prop(bridge, "bridge_north_landing", "中央桥北端", "central_bridge_channel", "planks_opening", Vector3(1.5, 0.2, -5.6), Vector3(2.7, 0.34, 1.3))
	_add_prop(bridge, "bridge_south_landing", "中央桥南端", "central_bridge_channel", "planks_half", Vector3(1.5, 0.2, 5.6), Vector3(3.0, 0.34, 1.2))
	_add_model(
		bridge,
		"bridge_waterfall_top",
		"中央落水口",
		"decor",
		"central_bridge_channel",
		"waterfall_narrow",
		Vector3(2.2, 0.65, 4.7),
		Vector3(0.8, 2.3, 0.18),
		Vector3.ZERO,
		["落水", "中央", "细瀑布"],
		false
	)
	_add_model(
		bridge,
		"bridge_foam",
		"中央落水泡沫",
		"decor",
		"central_bridge_channel",
		"plunge_pool_foam",
		Vector3(2.2, -0.02, 5.1),
		Vector3(2.1, 0.12, 1.8),
		Vector3.ZERO,
		["泡沫", "落水"],
		false,
		"float"
	)
	_add_prop(bridge, "bridge_column_west", "桥西桩柱", "central_bridge_channel", "wood_support", Vector3(0.2, 0.2, -2.2), Vector3(0.8, 2.4, 0.8))
	_add_prop(bridge, "bridge_column_east", "桥东桩柱", "central_bridge_channel", "wood_support", Vector3(2.8, 0.2, 1.8), Vector3(0.8, 2.4, 0.8))
	_add_prop(bridge, "bridge_lantern", "桥头提灯", "central_bridge_channel", "lantern_candle", Vector3(0.5, 0.55, -4.3), Vector3(0.55, 0.9, 0.55))
	_add_environment(bridge, "cold_spotlight", "桥口冷光", Vector3(1.5, 3.2, -4.5))


func _build_lower_gate_tower() -> void:
	var tower := _add_zone(
		scene_root,
		"lower_gate_tower",
		"下层水口门塔",
		["下层", "门塔", "水口", "城垛"]
	)
	_add_platform(
		tower,
		"tower_main_deck",
		"门塔主平台",
		"lower_gate_tower",
		Vector3(1.5, 0.0, 11.2),
		Vector3(10.6, 0.48, 7.6),
		["下层", "门塔", "主平台"],
		true
	)
	_add_platform(
		tower,
		"tower_front_apron",
		"门塔前庭",
		"lower_gate_tower",
		Vector3(1.5, 0.0, 15.6),
		Vector3(7.0, 0.4, 2.8),
		["下层", "前庭", "入口"],
		true
	)
	_add_model(
		tower,
		"tower_stairs",
		"门塔石阶",
		"floor",
		"lower_gate_tower",
		"stairs_wide_stone",
		Vector3(1.5, 1.15, 8.2),
		Vector3(3.2, 1.4, 2.6),
		Vector3.ZERO,
		["楼梯", "上层连接", "门塔"],
		false
	)
	_add_wall_run(tower, "tower_west_wall", "门塔西墙", "lower_gate_tower", Vector3(-3.8, 0.48, 7.6), Vector3(-3.8, 0.48, 14.8), 1.8, "dungeon_wall_half")
	_add_wall_run(tower, "tower_east_wall", "门塔东墙", "lower_gate_tower", Vector3(6.8, 0.48, 7.6), Vector3(6.8, 0.48, 14.8), 1.8, "dungeon_wall_half")
	_add_wall_run(tower, "tower_north_wall_left", "门塔北墙左段", "lower_gate_tower", Vector3(-3.8, 0.48, 7.6), Vector3(0.0, 0.48, 7.6), 1.8, "dungeon_wall_half")
	_add_wall_run(tower, "tower_north_wall_right", "门塔北墙右段", "lower_gate_tower", Vector3(3.2, 0.48, 7.6), Vector3(6.8, 0.48, 7.6), 1.8, "dungeon_wall_half")
	_add_wall_run(tower, "tower_front_wall_left", "门塔南墙左段", "lower_gate_tower", Vector3(-3.8, 0.48, 14.8), Vector3(-1.2, 0.48, 14.8), 1.8, "dungeon_wall_half")
	_add_wall_run(tower, "tower_front_wall_right", "门塔南墙右段", "lower_gate_tower", Vector3(4.2, 0.48, 14.8), Vector3(6.8, 0.48, 14.8), 1.8, "dungeon_wall_half")
	_add_prop(tower, "tower_gate", "门塔铁门", "lower_gate_tower", "dungeon_gate", Vector3(1.5, 0.48, 15.0), Vector3(3.2, 3.0, 0.55), Vector3.ZERO, "gate", "none", ["门", "门塔", "后续功能"])
	for x in [-3.1, -0.9, 1.5, 3.9, 6.0]:
		_add_prop(tower, "tower_crenellation_%s" % str(x).replace("-", "m").replace(".", "_"), "门塔城垛", "lower_gate_tower", "dungeon_wall_narrow", Vector3(x, 2.48, 14.8), Vector3(0.74, 0.72, 0.58), Vector3.ZERO, "decor", "none", ["城垛", "门塔"])
	for x in [-3.1, 1.5, 5.8]:
		_add_prop(tower, "tower_crenellation_back_%s" % str(x).replace("-", "m").replace(".", "_"), "门塔后城垛", "lower_gate_tower", "dungeon_wall_narrow", Vector3(x, 2.48, 7.6), Vector3(0.74, 0.72, 0.58), Vector3.ZERO, "decor", "none", ["城垛", "门塔"])
	_add_prop(tower, "tower_front_column_west", "门塔前柱西", "lower_gate_tower", "stone_pillar_large", Vector3(-1.5, 0.48, 15.0), Vector3(0.82, 2.5, 0.82))
	_add_prop(tower, "tower_front_column_east", "门塔前柱东", "lower_gate_tower", "stone_pillar_large", Vector3(4.5, 0.48, 15.0), Vector3(0.82, 2.5, 0.82))
	_add_model(
		tower,
		"tower_water_outfall",
		"门塔排水口",
		"decor",
		"lower_gate_tower",
		"drain_outfall",
		Vector3(4.6, 0.75, 15.1),
		Vector3(1.55, 0.95, 0.35),
		Vector3.ZERO,
		["排水口", "门塔", "建筑出水"],
		false,
		"float"
	)
	_add_waterfall(tower, "tower_outfall_flow", "门塔外流水柱", "lower_gate_tower", Vector3(4.6, -0.28, 15.15), Vector3(0.8, 2.55, 0.2), 1.65)
	_add_model(
		tower,
		"tower_outfall_foam",
		"门塔外流泡沫",
		"decor",
		"lower_gate_tower",
		"plunge_pool_foam",
		Vector3(4.6, -0.02, 15.35),
		Vector3(2.2, 0.12, 1.4),
		Vector3.ZERO,
		["泡沫", "门塔", "落水"],
		false,
		"float"
	)
	_add_puddle(tower, "tower_puddle", "门塔积水", "lower_gate_tower", Vector3(0.5, 0.49, 12.1), Vector3(2.5, 0.04, 1.4))
	_add_prop(tower, "tower_fire_basket", "门塔火盆", "lower_gate_tower", "fire_basket", Vector3(-2.7, 0.48, 13.9), Vector3(0.8, 0.9, 0.8))
	_add_environment(tower, "warm_lantern_light", "门塔暖光", Vector3(1.5, 1.5, 14.0))
	_add_environment(tower, "fire", "门塔火盆火焰", Vector3(-2.7, 1.45, 13.9))
	_add_environment(tower, "cold_spotlight", "门塔冷色顶光", Vector3(1.5, 4.3, 11.8))


func _build_right_platform() -> void:
	var right := _add_zone(
		scene_root,
		"right_isolated_platform",
		"右侧独立平台",
		["右侧", "独立平台", "断桥"]
	)
	_add_platform(
		right,
		"right_main_deck",
		"右侧主平台",
		"right_isolated_platform",
		Vector3(14.2, 0.0, -0.3),
		Vector3(6.7, 0.4, 7.7),
		["右侧", "独立平台", "重复地板"],
		true
	)
	_add_model(
		right,
		"right_broken_bridge",
		"右侧断桥",
		"decor",
		"right_isolated_platform",
		"planks_opening",
		Vector3(9.8, 0.18, -0.2),
		Vector3(3.7, 0.3, 2.0),
		Vector3.ZERO,
		["断桥", "右侧连接"],
		false
	)
	_add_edge_run(right, "right_west_edge", "右侧西缘", "right_isolated_platform", Vector3(10.8, 0.4, -3.7), Vector3(10.8, 0.4, 3.3))
	_add_edge_run(right, "right_east_edge", "右侧东缘", "right_isolated_platform", Vector3(17.5, 0.4, -3.7), Vector3(17.5, 0.4, 3.3))
	_add_wall_run(right, "right_south_wall", "右侧南墙", "right_isolated_platform", Vector3(11.8, 0.4, 3.4), Vector3(14.4, 0.4, 3.4), 1.25, "town_wall")
	_add_wall_run(right, "right_north_stub", "右侧北侧断墙", "right_isolated_platform", Vector3(15.0, 0.4, -4.1), Vector3(17.2, 0.4, -4.1), 1.45, "dungeon_wall_half")
	for z in [-2.5, 0.3, 2.7]:
		_add_prop(right, "right_column_%s" % str(z).replace("-", "m").replace(".", "_"), "右侧残柱", "right_isolated_platform", "dungeon_column", Vector3(17.0, 0.4, z), Vector3(0.6, 1.9, 0.6))
	_add_prop(right, "right_tree", "右侧枯树", "right_isolated_platform", "town_tree", Vector3(12.2, 0.4, -2.1), Vector3(1.8, 2.8, 1.8))
	_add_prop(right, "right_rocks", "右侧碎岩", "right_isolated_platform", "rocks_tall", Vector3(16.0, 0.4, 2.2), Vector3(1.4, 1.8, 1.4))
	_add_waterfall(right, "right_waterfall", "右侧瀑布", "right_isolated_platform", Vector3(17.6, -0.25, -1.2), Vector3(2.6, 3.1, 0.2), 2.1)
	_add_puddle(right, "right_puddle", "右侧积水", "right_isolated_platform", Vector3(13.4, 0.41, 1.4), Vector3(2.3, 0.04, 1.3))
	_add_environment(right, "cold_spotlight", "右侧冷光", Vector3(14.0, 3.6, -0.4))


func _build_southeast_block() -> void:
	var southeast := _add_zone(
		scene_root,
		"southeast_small_block",
		"东南小平台",
		["东南", "小平台", "附属结构"]
	)
	_add_platform(
		southeast,
		"southeast_deck",
		"东南小平台",
		"southeast_small_block",
		Vector3(9.8, 0.0, 12.1),
		Vector3(4.6, 0.38, 4.3),
		["东南", "小平台", "附属"],
		true
	)
	_add_platform(
		southeast,
		"southeast_link",
		"东南连接台",
		"southeast_small_block",
		Vector3(6.8, 0.0, 10.6),
		Vector3(3.1, 0.32, 2.0),
		["东南", "连接", "窄台"],
		true
	)
	_add_wall_run(southeast, "southeast_wall", "东南断墙", "southeast_small_block", Vector3(8.2, 0.38, 13.0), Vector3(11.4, 0.38, 13.0), 1.15, "dungeon_wall_half")
	_add_prop(southeast, "southeast_column", "东南残柱", "southeast_small_block", "dungeon_column", Vector3(8.2, 0.38, 10.5), Vector3(0.62, 1.8, 0.62))
	_add_prop(southeast, "southeast_rocks", "东南石堆", "southeast_small_block", "rocks", Vector3(11.1, 0.38, 11.0), Vector3(1.8, 0.8, 1.8))
	_add_puddle(southeast, "southeast_puddle", "东南积水", "southeast_small_block", Vector3(9.4, 0.39, 12.7), Vector3(1.9, 0.04, 1.1))
	_add_waterfall(southeast, "southeast_waterfall", "东南落水", "southeast_small_block", Vector3(11.8, -0.25, 14.1), Vector3(1.7, 2.5, 0.18), 1.6)


func _add_preview_cameras() -> void:
	var cameras := _add_zone(scene_root, "preview_cameras", "预览相机", ["相机", "预览", "不参与玩法"])
	var perspective := _add_semantic_host(
		cameras,
		"preview_camera_game",
		"默认斜视预览相机",
		"camera",
		"none",
		"preview_cameras",
		["相机", "默认视图"],
		[]
	)
	perspective.position = Vector3(0.0, 20.5, 25.0)
	perspective.rotation_degrees = Vector3(-36.0, 0.0, 0.0)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 49.0
	camera.current = true
	perspective.add_child(camera)
	var top_down_host := _add_semantic_host(
		cameras,
		"preview_camera_top_down",
		"参考顶视相机",
		"camera",
		"none",
		"preview_cameras",
		["相机", "顶视", "参考图"],
		[]
	)
	top_down_host.position = Vector3(0.0, 42.0, 0.0)
	top_down_host.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var top_camera := Camera3D.new()
	top_camera.name = "Camera3D"
	top_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	top_camera.size = 36.0
	top_camera.current = false
	top_down_host.add_child(top_camera)


func _add_world_environment() -> void:
	var node := WorldEnvironment.new()
	node.name = "WORLD_ENVIRONMENT_雨夜冷灰"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#16222b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#78909d")
	environment.ambient_light_energy = 0.48
	environment.fog_enabled = true
	environment.fog_light_color = Color("#425965")
	environment.fog_light_energy = 0.7
	environment.fog_density = 0.012
	environment.fog_height = 0.0
	environment.fog_height_density = 0.08
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	node.environment = environment
	scene_root.add_child(node)


func _add_zone(
	p_parent: Node3D,
	p_id: String,
	p_display_name: String,
	p_tags: Array
) -> Node3D:
	return _add_semantic_host(
		p_parent,
		p_id,
		p_display_name,
		"zone",
		"none",
		REGION_ID,
		p_tags,
		[]
	)


func _add_semantic_host(
	p_parent: Node3D,
	p_id: String,
	p_display_name: String,
	p_kind: String,
	p_behavior: String,
	p_zone_id: String,
	p_tags: Array,
	p_links: Array
) -> Node3D:
	var host := Node3D.new()
	p_parent.add_child(host)
	var data := Schema.make(
		p_id,
		p_kind,
		p_behavior,
		p_zone_id,
		p_tags,
		p_links,
		{"candidate_scene": OUTPUT_PATH},
		p_display_name
	)
	data = Schema.apply_to_node(host, data)
	host.name = Schema.node_name(data)
	return host


func _add_platform(
	p_parent: Node3D,
	p_id: String,
	p_display_name: String,
	p_zone_id: String,
	p_base_position: Vector3,
	p_size: Vector3,
	p_tags: Array,
	p_repeat: bool = true
) -> Node3D:
	return _add_model(
		p_parent,
		p_id,
		p_display_name,
		"floor",
		p_zone_id,
		"dungeon_floor_detail",
		p_base_position + Vector3(0.0, p_size.y * 0.5, 0.0),
		p_size,
		Vector3.ZERO,
		p_tags,
		p_repeat
	)


func _add_puddle(
	p_parent: Node3D,
	p_id: String,
	p_display_name: String,
	p_zone_id: String,
	p_position: Vector3,
	p_size: Vector3
) -> Node3D:
	return _add_model(
		p_parent,
		p_id,
		p_display_name,
		"decor",
		p_zone_id,
		"puddle_ripple",
		p_position,
		p_size,
		Vector3.ZERO,
		["积水", "涟漪", "雨夜"],
		false,
		"float"
	)


func _add_waterfall(
	p_parent: Node3D,
	p_id: String,
	p_display_name: String,
	p_zone_id: String,
	p_base_position: Vector3,
	p_size: Vector3,
	p_height: float
) -> Node3D:
	return _add_model(
		p_parent,
		p_id,
		p_display_name,
		"decor",
		p_zone_id,
		"waterfall_wide" if p_size.x >= 2.0 else "waterfall_narrow",
		p_base_position + Vector3(0.0, p_height * 0.5, 0.0),
		p_size,
		Vector3.ZERO,
		["瀑布", "落水", "雨城"],
		false
	)


func _add_prop(
	p_parent: Node3D,
	p_id: String,
	p_display_name: String,
	p_zone_id: String,
	p_model_id: String,
	p_base_position: Vector3,
	p_size: Vector3,
	p_rotation: Vector3 = Vector3.ZERO,
	p_kind: String = "decor",
	p_behavior: String = "none",
	p_tags: Array = []
) -> Node3D:
	return _add_model(
		p_parent,
		p_id,
		p_display_name,
		p_kind,
		p_zone_id,
		p_model_id,
		p_base_position + Vector3(0.0, p_size.y * 0.5, 0.0),
		p_size,
		p_rotation,
		p_tags,
		false
	)


func _add_edge_run(
	p_parent: Node3D,
	p_id: String,
	p_display_name: String,
	p_zone_id: String,
	p_start: Vector3,
	p_end: Vector3
) -> Node3D:
	var direction := p_end - p_start
	var length := sqrt(direction.x * direction.x + direction.z * direction.z)
	var rotation := 0.0
	if absf(direction.z) > absf(direction.x):
		rotation = 90.0
	var center := (p_start + p_end) * 0.5
	return _add_model(
		p_parent,
		p_id,
		p_display_name,
		"decor",
		p_zone_id,
		"road_edge",
		Vector3(center.x, center.y + 0.035, center.z),
		Vector3(length, 0.07, 0.58),
		Vector3(0.0, rotation, 0.0),
		["路缘", "边缘", "承接"],
		true
	)


func _add_wall_run(
	p_parent: Node3D,
	p_id: String,
	p_display_name: String,
	p_zone_id: String,
	p_start: Vector3,
	p_end: Vector3,
	p_height: float,
	p_model_id: String
) -> Node3D:
	var direction := p_end - p_start
	var length := sqrt(direction.x * direction.x + direction.z * direction.z)
	var rotation := 0.0
	if absf(direction.z) > absf(direction.x):
		rotation = 90.0
	var center := (p_start + p_end) * 0.5
	return _add_model(
		p_parent,
		p_id,
		p_display_name,
		"decor",
		p_zone_id,
		p_model_id,
		Vector3(center.x, center.y + p_height * 0.5, center.z),
		Vector3(length, p_height, 0.48),
		Vector3(0.0, rotation, 0.0),
		["墙", "边界", "阻挡", "重复拼片"],
		true
	)


func _add_model(
	p_parent: Node3D,
	p_id: String,
	p_display_name: String,
	p_kind: String,
	p_zone_id: String,
	p_model_id: String,
	p_position: Vector3,
	p_size: Vector3,
	p_rotation: Vector3,
	p_tags: Array,
	p_repeat: bool,
	p_placement: String = ""
) -> Node3D:
	model_hosts += 1
	var host := _add_semantic_host(
		p_parent,
		p_id,
		p_display_name,
		p_kind,
		"none",
		p_zone_id,
		p_tags,
		[]
	)
	host.position = p_position
	host.rotation_degrees = p_rotation
	var placeholder := _make_placeholder(p_size, p_model_id)
	placeholder.name = "AuthoringPlaceholder"
	host.add_child(placeholder)

	var entry: Dictionary = VisualCatalog.find(p_model_id)
	if entry.is_empty():
		build_errors.append("%s：找不到模型 `%s`。" % [p_id, p_model_id])
		return host
	var prepared: Dictionary = entry.duplicate(true)
	prepared["repeat_along_longest"] = p_repeat
	if not p_placement.is_empty():
		prepared["placement"] = p_placement
	elif str(prepared.get("placement", "")).is_empty():
		prepared["placement"] = VisualCatalog.placement_for_model_id(p_model_id)
	var result: Dictionary = VisualCatalog.apply_model(host, prepared, scene_root)
	if not bool(result.get("ok", false)):
		build_errors.append("%s：应用 `%s` 失败：%s" % [
			p_id,
			p_model_id,
			str(result.get("error", "未知错误")),
		])
		return host
	model_ok += 1
	var visual_value = result.get("visual", {})
	if visual_value is Dictionary:
		var data := Schema.data_from_node(host)
		data["params"] = {
			"candidate_scene": OUTPUT_PATH,
			"visual": visual_value,
			"layout_note": "顶视参考候选布局",
		}
		Schema.apply_to_node(host, data)
	return host


func _make_placeholder(p_size: Vector3, p_model_id: String) -> MeshInstance3D:
	var normalized_size := p_size.max(Vector3(0.04, 0.04, 0.04))
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var material := StandardMaterial3D.new()
	material.albedo_color = _placeholder_color(p_model_id)
	material.roughness = 0.82
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.scale = normalized_size
	return node


func _placeholder_color(p_model_id: String) -> Color:
	if p_model_id.contains("water") or p_model_id.contains("river") or p_model_id.contains("waterfall") or p_model_id.contains("puddle"):
		return Color("#3c91ad")
	if p_model_id.contains("wall") or p_model_id.contains("gate") or p_model_id.contains("column") or p_model_id.contains("pillar"):
		return Color("#72877c")
	if p_model_id.contains("floor") or p_model_id.contains("road") or p_model_id.contains("plank"):
		return Color("#68756a")
	if p_model_id.contains("pine") or p_model_id.contains("tree"):
		return Color("#426d57")
	return Color("#7b7062")


func _add_environment(
	p_parent: Node,
	p_effect_id: String,
	p_display_name: String,
	p_position: Vector3
) -> void:
	var entry: Dictionary = EnvironmentCatalog.find(p_effect_id)
	if entry.is_empty():
		build_errors.append("环境特效 `%s` 不存在。" % p_effect_id)
		return
	var result: Dictionary = EnvironmentCatalog.apply_environment(
		p_parent,
		entry,
		scene_root,
		p_display_name
	)
	if not bool(result.get("ok", false)):
		build_errors.append("环境特效 `%s` 创建失败：%s" % [
			p_display_name,
			str(result.get("error", "未知错误")),
		])
		return
	var node := result.get("node") as Node3D
	if node:
		node.position = p_position
	environment_count += 1


func _assign_owner(p_node: Node, p_owner: Node) -> void:
	for child in p_node.get_children():
		child.owner = p_owner
		# PackedScene instances own their internal nodes. Assigning the authoring
		# root below an instance would serialize those children a second time and
		# create duplicate Water/Highlight/Bank nodes when the scene is reopened.
		if not child.scene_file_path.is_empty():
			continue
		_assign_owner(child, p_owner)


func _count_semantic_nodes(p_node: Node) -> int:
	var count := 0
	if p_node.has_meta(Schema.META_KEY):
		count += 1
	for child in p_node.get_children():
		count += _count_semantic_nodes(child)
	return count
