extends SceneTree

const WorldMap := preload("res://scripts/v2/V2WorldMap.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var m: WorldMap = WorldMap.new()
	m.load_from(WorldMap.seed_night_watch())

	var rooms: int = m.rooms.size()
	var edges: int = m.edges.size()
	var rest_state: int = m.state_of("rest")
	var hub_state: int = m.state_of("nw_hub")
	var seal_state: int = m.state_of("seal")

	# 世界 X → 房间定位
	var at_rest: String = m.room_for_world_x(-13.5)
	var at_case1: String = m.room_for_world_x(-8.0)
	var at_boss: String = m.room_for_world_x(11.0)

	# 当前节点高亮 + 封印终点变色
	m.set_current(at_case1)
	m.set_state("seal", WorldMap.STATE_DONE)
	var seal_after: int = m.state_of("seal")

	var ok: bool = (
		rooms == 12
		and edges == 12
		and rest_state == WorldMap.STATE_DONE
		and hub_state == WorldMap.STATE_IN_PROGRESS
		and seal_state == WorldMap.STATE_LOCKED
		and at_rest == "rest"
		and at_case1 == "case_sofa"
		and at_boss == "boss"
		and m.current_id == at_case1
		and seal_after == WorldMap.STATE_DONE
	)

	print("V2_WORLDMAP rooms=%d edges=%d rest=%s hub=%s seal_init=%s map@-13.5=%s map@-8=%s map@11=%s seal_after=%s current=%s" % [
		rooms,
		edges,
		state_name(rest_state),
		state_name(hub_state),
		state_name(seal_state),
		at_rest,
		at_case1,
		at_boss,
		state_name(seal_after),
		m.current_id,
	])
	m.free()
	quit(0 if ok else 1)


func state_name(p_state: int) -> String:
	if p_state == WorldMap.STATE_DONE:
		return "DONE"
	if p_state == WorldMap.STATE_IN_PROGRESS:
		return "IN_PROGRESS"
	return "LOCKED"
