extends SceneTree

# R1 夜巡司区验收：值房柜台 / 线索档案桌 / 捷径门(夜巡印章) / 可击破罐 / 地图状态。
# 这些断言来自 V2RouteData.load_region 生成的区域世界，不改任何游戏数据。

const RouteData := preload("res://scripts/v2/V2RouteData.gd")
const RegionBuilder := preload("res://scripts/v2/V2RegionBuilder.gd")
const WorldMap := preload("res://scripts/v2/V2WorldMap.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var region: Dictionary = RouteData.load_region()
	var root_node := Node3D.new()
	root.add_child(root_node)

	var handle: Dictionary = RegionBuilder.build(root_node, region)
	for _frame in range(6):
		await process_frame

	var gates: Dictionary = handle.get("gates", {})
	var props: int = int(handle.get("props", 0))

	# 1) 捷径门世界实体存在，且是夜巡印章能力门
	var shortcut: Node = gates.get("shortcut_gate")
	var shortcut_ok: bool = is_instance_valid(shortcut) and shortcut.has_method("can_open")
	var shortcut_req: String = shortcut.get("required_ability") if shortcut_ok else "_"
	var shortcut_locked: bool = shortcut_ok and not shortcut.can_open({}, false)            # 没印章不能开
	var shortcut_openable: bool = shortcut_ok and shortcut.can_open({"night_stamp": true}, false)  # 有印章可开

	# 2) 封印之门实体仍在
	var seal: Node = gates.get("seal_door")
	var seal_ok: bool = is_instance_valid(seal) and seal.has_method("can_open")

	# 3) 值房柜台 & 线索档案桌平台（按位置扫描 StaticBody3D，EnvFactory 不保留 id 名）
	var counter_ok: bool = _platform_near(root_node, Vector3(-14.8, 0.0, -3.0), 1.2)
	var clue_ok: bool = _platform_near(root_node, Vector3(-11.6, 0.0, -3.0), 1.2)

	# 4) 可击破罐有可见体（JarBody 子节点）
	var jar_ok: bool = _has_named_child_near(root_node, "JarBody", Vector3(-16.5, 0.0, 5.6), 1.2)

	# 5) 地图初始状态：夜巡司值房 = 正在做(IN_PROGRESS)，捷径门/线索 = 正在做，印章 = 未开始
	var map: WorldMap = WorldMap.new()
	map.load_from(WorldMap.seed_night_watch())
	var hub_state: int = map.state_of("nw_hub")
	var clue_state: int = map.state_of("nw_clue")
	var gate_state: int = map.state_of("nw_gate")
	var key_state: int = map.state_of("nw_key")
	var hub_done_after: bool = false
	map.set_state("nw_hub", WorldMap.STATE_DONE)
	hub_done_after = map.state_of("nw_hub") == WorldMap.STATE_DONE
	map.free()

	var ok: bool = (
		props >= 18
		and shortcut_ok
		and shortcut_req == "night_stamp"
		and shortcut_locked
		and shortcut_openable
		and seal_ok
		and counter_ok
		and clue_ok
		and jar_ok
		and hub_state == WorldMap.STATE_IN_PROGRESS
		and clue_state == WorldMap.STATE_IN_PROGRESS
		and gate_state == WorldMap.STATE_IN_PROGRESS
		and key_state == WorldMap.STATE_LOCKED
		and hub_done_after
	)

	print("V2_R1 props=%d shortcut=%s req=%s locked=%s openable=%s seal=%s counter=%s clue=%s jar=%s"
		% [props, shortcut_ok, shortcut_req, shortcut_locked, shortcut_openable, seal_ok, counter_ok, clue_ok, jar_ok])
	print("V2_R1_MAP hub=%s clue=%s gate=%s key=%s hub_done_after=%s"
		% [state_name(hub_state), state_name(clue_state), state_name(gate_state), state_name(key_state), hub_done_after])

	quit(0 if ok else 1)


func _platform_near(p_root: Node, p_pos: Vector3, p_tol: float) -> bool:
	for child in p_root.get_children():
		if child is StaticBody3D:
			if child.global_position.distance_to(p_pos) < p_tol:
				return true
	return false


func _has_named_child_near(p_root: Node, p_name: String, p_pos: Vector3, p_tol: float) -> bool:
	for child in p_root.get_children():
		if child.global_position.distance_to(p_pos) < p_tol:
			if child.get_node_or_null(p_name) != null:
				return true
	return false


func state_name(p_state: int) -> String:
	if p_state == WorldMap.STATE_DONE:
		return "DONE"
	if p_state == WorldMap.STATE_IN_PROGRESS:
		return "IN_PROGRESS"
	return "LOCKED"
