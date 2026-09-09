extends SceneTree

# R1 夜巡司区运行时验收：加载主场景，直接驱动两条互动路径——
#   1) 靠近线索档案按 E（_try_v2_npc）→ 地图 nw_clue 翻 DONE
#   2) 持夜巡印章靠近捷径门按 E（_try_region_gate）→ 门开启，nw_gate/nw_key 翻 DONE
# 该脚本直接调用场景根脚本的方法，不依赖真实按键，用于 headless 回归。


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main/V2FirstLoop.tscn")
	var main: Node = packed.instantiate()
	root.add_child(main)
	for _frame in range(10):
		await process_frame

	var player: Node3D = get_first_node_in_group("player")
	var world_map = main.get("_world_map")

	# --- 1) 线索档案：没有印章也先能读线索 ---
	var start_clue_state: int = world_map.state_of("nw_clue") if is_instance_valid(world_map) else -1
	player.global_position = Vector3(-11.6, 0.9, -2.2)
	await process_frame
	main._try_v2_npc()
	await process_frame
	var clue_after: int = world_map.state_of("nw_clue") if is_instance_valid(world_map) else -1

	# --- 2) 捷径门：未拿到印章 → 锁着 ---
	var gates: Dictionary = main.get("_region_gates")
	var shortcut: Node = gates.get("shortcut_gate")
	var gate_open_before: bool = shortcut.is_open() if is_instance_valid(shortcut) else false
	player.global_position = Vector3(-10.3, 0.9, -4.0)
	await process_frame
	var opened_locked: bool = main._try_region_gate()
	await process_frame
	var gate_open_after_lock: bool = shortcut.is_open() if is_instance_valid(shortcut) else false

	# --- 3) 拿到夜巡印章 → 开捷径门 ---
	main.set("_has_night_stamp", true)
	player.global_position = Vector3(-10.3, 0.9, -4.0)
	await process_frame
	var opened_with_stamp: bool = main._try_region_gate()
	await process_frame
	var gate_open_after_stamp: bool = shortcut.is_open() if is_instance_valid(shortcut) else false
	var gate_state: int = world_map.state_of("nw_gate") if is_instance_valid(world_map) else -1
	var key_state: int = world_map.state_of("nw_key") if is_instance_valid(world_map) else -1

	var ok: bool = (
		start_clue_state == world_map.STATE_IN_PROGRESS
		and clue_after == world_map.STATE_DONE
		and is_instance_valid(shortcut)
		and gate_open_before == false
		and opened_locked == true                      # 锁住时碰撞后返回(true)表示“这扇门处理了本次互动”，不再往外走
		and gate_open_after_lock == false
		and opened_with_stamp == true
		and gate_open_after_stamp == true
		and gate_state == world_map.STATE_DONE
		and key_state == world_map.STATE_DONE
	)

	print("V2_R1_RT clue=%s->%s gate_before=%s lock_return=%s gate_after_lock=%s stamp_return=%s gate_after_stamp=%s gate_state=%s key_state=%s"
		% [state_name(start_clue_state), state_name(clue_after), gate_open_before, opened_locked, gate_open_after_lock, opened_with_stamp, gate_open_after_stamp, state_name(gate_state), state_name(key_state)])

	quit(0 if ok else 1)


func state_name(p_state: int) -> String:
	if p_state == -1:
		return "N/A"
	if p_state == 2:
		return "DONE"
	if p_state == 1:
		return "IN_PROGRESS"
	return "LOCKED"
