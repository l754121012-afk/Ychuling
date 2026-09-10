extends Node3D

const PlayerScript := preload("res://scripts/player/PlayerController.gd")
const GhostScript := preload("res://scripts/actors/TestGhost.gd")
const LiquidBarScript := preload("res://scripts/ui/LiquidHealthBar.gd")
const GateScript := preload("res://scripts/v2/V2AbilityGate.gd")
const PickupScript := preload("res://scripts/v2/V2AbilityPickup.gd")
const RitualScript := preload("res://scripts/v2/V2RitualEffect.gd")
const V2RouteData := preload("res://scripts/v2/V2RouteData.gd")
const V2RegionBuilder := preload("res://scripts/v2/V2RegionBuilder.gd")
const FSAuthoringRuntime := preload("res://scripts/authoring/FSAuthoringRuntime.gd")
const GameView := preload("res://scripts/authoring/FSGameView.gd")
const PlaytestMode := preload("res://scripts/authoring/FSPlaytestMode.gd")

const CASES: Array[Dictionary] = [
	{
		"route_id": "case_sofa",
		"title": "沙发下的灰影",
		"zone_x": -8.0,
		"ghost_positions": [Vector3(-9.6, 0.0, -1.7), Vector3(-8.3, 0.0, -0.7), Vector3(-8.1, 0.0, 0.9), Vector3(-6.7, 0.0, 1.5)],
		"ghost_styles": ["swipe", "shot", "pool", "lunge"],
	},
	{
		"route_id": "case_tv",
		"title": "电视里的歌声",
		"zone_x": 0.0,
		"ghost_positions": [Vector3(-1.7, 0.0, -1.5), Vector3(-0.7, 0.0, -0.7), Vector3(0.7, 0.0, 0.8), Vector3(1.5, 0.0, 1.5)],
		"ghost_styles": ["shot", "pool", "lunge", "swipe"],
	},
	{
		"route_id": "case_wardrobe",
		"title": "衣柜里的呼吸声",
		"zone_x": 8.0,
		"ghost_positions": [Vector3(6.8, 0.0, -1.6), Vector3(7.7, 0.0, -0.7), Vector3(8.5, 0.0, 0.8), Vector3(9.4, 0.0, 1.6)],
		"ghost_styles": ["lunge", "swipe", "shot", "pool"],
	},
]

const FINAL_POS := Vector3(11.0, 0.0, 0.0)
const FINAL_MINION_POS: Array[Vector3] = [
	Vector3(7.8, 0.0, -1.8),
	Vector3(14.4, 0.0, -1.4),
	Vector3(11.8, 0.0, 2.7),
]
const REST_POINTS: Array[Vector3] = [
	Vector3(-13.5, 0.9, 0.0),
	Vector3(-3.6, 0.9, 0.0),
	Vector3(4.4, 0.9, 0.0),
]

var _player: PlayerController
var _camera: Camera3D
var _hud_label: Label
var _event_label: Label
var _liquid_health
var _bean_rects: Array[TextureRect] = []
var _stamina_bar_fill: ColorRect
var _stamina_value_label: Label

var _case_index := 0
var _review_count := 0
var _chain_count := 0
var _player_health := 3
var _player_momentum := 0
var _player_stamina := 15.0
var _player_beans := 0
var _remaining_ghosts := 0
var _active_ghosts: Array[TestGhost] = []
var _case_pads: Array[MeshInstance3D] = []
var _route_gates: Array[StaticBody3D] = []
var _gate_visuals: Array[MeshInstance3D] = []
var _final_started := false
var _shift_done := false
var _boss_key_granted := false
var _target_prompt_shown := false
var _target_auto_timer := 0.0
var _seal_gate
var _target_marker: MeshInstance3D
var _has_night_stamp := false
var _boss_waiting_npc := false
var _boss_revealed := false
var _reward_pickup
var _map_open := false
var _map_layer: CanvasLayer
var _map_current_label: Label
var _world_map: V2WorldMap
var _npc_data: Array[Dictionary] = []
var _region_gates: Dictionary = {}
var _region_handle: Dictionary = {}
var _using_authored_region := false
var _case_origins: Array[Vector3] = []
var _rest_points: Array[Vector3] = []
var _spawn_position := Vector3(-14.6, 0.9, 0.0)
var _boss_position := FINAL_POS
var _playtest_mode := false


func _ready() -> void:
	_playtest_mode = PlaytestMode.is_enabled()
	if _playtest_mode:
		_build_playtest()
		return
	_build_environment()
	_build_region_world()
	if _using_authored_region:
		_adopt_authored_region()
	else:
		_build_route_floor()
		_build_case_pads()
		_build_rest_markers()
		_build_route_gates()
	_build_shortcut_gate_marker()
	_build_v2_seal_end()
	_build_player()
	_build_camera()
	_build_hud()
	_setup_map_hud()
	_build_v2_npcs()
	_activate_case(_case_index)


func _process(delta: float) -> void:
	if not _player or not _camera:
		return
	if _playtest_mode:
		_update_follow_camera(delta)
		return
	if Input.is_action_just_pressed("map"):
		_toggle_map()
	if _map_open:
		_update_map()
	_update_follow_camera(delta)
	if _boss_key_granted and not _shift_done:
		var near_target := is_instance_valid(_target_marker) and absf(_player.global_position.x - _target_marker.global_position.x) < 2.5
		if near_target:
			if not _target_prompt_shown:
				_target_prompt_shown = true
				_show_event("靠近封印终点：按 E 完成封印")
			_target_auto_timer += delta
			if Input.is_action_just_pressed("interact") or _target_auto_timer > 1.4:
				_finish_shift()
		elif is_instance_valid(_target_marker) and _player.global_position.x > _target_marker.global_position.x - 1.2:
			_finish_shift()
	var near_authored_target := is_instance_valid(_target_marker) \
		and absf(_player.global_position.x - _target_marker.global_position.x) < 3.0
	if Input.is_action_just_pressed("interact") and not (_boss_key_granted and near_authored_target):
		if not _try_region_gate():
			_try_v2_npc()


func _on_ghost_sent(ghost: TestGhost) -> void:
	if not _active_ghosts.has(ghost):
		return
	_active_ghosts.erase(ghost)
	_remaining_ghosts = maxi(0, _remaining_ghosts - 1)
	if _remaining_ghosts == 0 and not _final_started:
		_complete_current_case()
	elif _remaining_ghosts == 0 and _final_started and not _shift_done:
		_boss_cleared()
	else:
		_update_hud()


func _complete_current_case() -> void:
	_review_count += 1
	var case_pos := _case_origin(_case_index)
	_set_pad_color(_case_index, Color("#6fce8f"))
	if _case_index == 0 and not _has_night_stamp:
		_spawn_stamp_reward()
		_show_event("案件1清完：附近出现了夜巡印章")
		_update_hud()
		return
	_spawn_ritual(case_pos, Color("#ffe08a"))
	if _case_index < CASES.size() - 1:
		_show_event("顾客回访：五星好评，下一单已亮起")
		_case_index += 1
		if _case_index == 1:
			_open_route_gate(0)
		elif _case_index == 2:
			_open_route_gate(1)
		_activate_case(_case_index)
	else:
		_boss_waiting_npc = true
		_show_event("三单清完：收工 Boss 线索已出现，先去找神秘鬼确认弱点")
		_update_hud()


func _spawn_stamp_reward() -> void:
	if is_instance_valid(_reward_pickup):
		return
	_reward_pickup = PickupScript.new()
	_reward_pickup.set("ability_id", "night_stamp")
	_reward_pickup.set("ability_name", "夜巡印章")
	_reward_pickup.position = _case_origin(0) + Vector3(0.0, 0.0, -3.6)
	add_child(_reward_pickup)
	_reward_pickup.collected.connect(_on_ability_collected)


func _on_ability_collected(p_ability_id: String) -> void:
	if p_ability_id != "night_stamp":
		return
	_has_night_stamp = true
	_reward_pickup = null
	if is_instance_valid(_player):
		_player.set_base_sweep_damage(2)
	_spawn_ritual(_case_origin(0) + Vector3(0.0, 0.0, -3.6), Color("#eaffc9"))
	_open_route_gate(0)
	_show_event("获得夜巡印章：清扫伤害提升，下一案件门已打开")
	_case_index = 1
	_activate_case(1)
	_update_hud()


func _activate_case(p_index: int) -> void:
	_set_pad_color(p_index, Color("#ffd166"))
	var data: Dictionary = CASES[p_index]
	var positions: Array = data.ghost_positions
	var styles: Array = data.ghost_styles
	var case_origin := _case_origin(p_index)
	var authored_origin_x := float(data["zone_x"])
	for ghost_index in range(positions.size()):
		var ghost: TestGhost = GhostScript.new()
		ghost.name = "CaseGhost_%d_%d" % [p_index, ghost_index]
		var source: Vector3 = positions[ghost_index]
		ghost.position = case_origin + (source - Vector3(authored_origin_x, 0.0, 0.0))
		ghost.configure_attack_style(str(styles[ghost_index]))
		add_child(ghost)
		ghost.sent_off.connect(_on_ghost_sent)
		ghost.chain_triggered.connect(_on_chain_triggered)
		_active_ghosts.append(ghost)
	_remaining_ghosts = _active_ghosts.size()
	_update_hud()


func _case_origin(p_index: int) -> Vector3:
	if p_index >= 0 and p_index < _case_origins.size():
		return _case_origins[p_index]
	if p_index >= 0 and p_index < CASES.size():
		return Vector3(float(CASES[p_index]["zone_x"]), 0.0, 0.0)
	return Vector3.ZERO


func _start_final_event() -> void:
	_final_started = true
	_boss_waiting_npc = false
	_boss_revealed = true
	_spawn_ritual(_boss_position, Color("#c9f2ff"))
	var minion_styles: Array[String] = ["swipe", "pool", "shot"]
	for index in range(FINAL_MINION_POS.size()):
		var minion: TestGhost = GhostScript.new()
		minion.name = "FinalMinion_%d" % index
		minion.hits_to_stagger = 4
		minion.art_scale = 0.8
		minion.configure_attack_style(minion_styles[index])
		minion.position = _boss_position + (FINAL_MINION_POS[index] - FINAL_POS)
		add_child(minion)
		minion.sent_off.connect(_on_ghost_sent)
		minion.chain_triggered.connect(_on_chain_triggered)
		_active_ghosts.append(minion)

	var big_ghost: TestGhost = GhostScript.new()
	big_ghost.name = "FinalClient"
	big_ghost.hits_to_stagger = 24
	big_ghost.art_scale = 2.9
	big_ghost.configure_attack_style("boss")
	big_ghost.can_use_pool = false
	big_ghost.position = _boss_position
	add_child(big_ghost)
	big_ghost.sent_off.connect(_on_ghost_sent)
	big_ghost.chain_triggered.connect(_on_chain_triggered)
	_active_ghosts.append(big_ghost)
	_remaining_ghosts = _active_ghosts.size()
	_update_hud()


func _finish_shift() -> void:
	if is_instance_valid(_target_marker):
		_spawn_ritual(_target_marker.global_position, Color("#f2d77a"))
	_shift_done = true
	_review_count += 1
	_set_pad_color(0, Color("#6fce8f"))
	_set_pad_color(1, Color("#6fce8f"))
	_set_pad_color(2, Color("#6fce8f"))
	_show_event("今晚收工：五星结业，事务所传来新订单预告")
	_update_hud()


func _boss_cleared() -> void:
	if _boss_key_granted:
		return
	_boss_key_granted = true
	_target_prompt_shown = false
	_target_auto_timer = 0.0
	if is_instance_valid(_seal_gate):
		_seal_gate.try_open({}, true)
	_spawn_ritual(FINAL_POS, Color("#d9f6ff"))
	_show_event("封印钥匙到手：封印终点已打开，走过去确认收工")
	_update_hud()


func _build_v2_seal_end() -> void:
	var built_door: Node = _region_gates.get("seal_door")
	if is_instance_valid(built_door):
		_seal_gate = built_door
	else:
		_seal_gate = GateScript.new()
		_seal_gate.set("gate_id", "seal_door")
		_seal_gate.set("required_boss", "seal_boss")
		_seal_gate.position = Vector3(15.4, 0.0, 0.0)
		add_child(_seal_gate)
	if is_instance_valid(_seal_gate):
		_seal_gate.opened.connect(_on_seal_gate_opened)

	_target_marker = _marker_visual(_authored_marker_node("seal_endpoint"))
	if _target_marker == null:
		_target_marker = PlaceholderKit.box("art_key_v2_seal_target", Color("#f2d77a"), Vector3(1.2, 4.0, 1.2))
		_target_marker.position = Vector3(18.2, 2.0, 0.0)
		add_child(_target_marker)


func _on_seal_gate_opened(_gate_id: String) -> void:
	_spawn_ritual(_seal_gate.global_position if is_instance_valid(_seal_gate) else Vector3(15.4, 0.0, 0.0), Color("#ffd166"))


func _build_v2_npcs() -> void:
	_npc_data = [
		{
			"id": "np_old_watchman",
			"position": Vector3(-12.0, 0.0, 4.2),
			"message": "老巡夜员：东区三案不是三个邻居吵架，它们都是在给封印‘续命’。第一案清完后，那边会浮出一枚夜巡印章。",
		},
		{
			"id": "np_mystery_ghost",
			"position": Vector3(6.2, 0.0, -4.6),
			"message": "神秘鬼：你要找的钥匙不在房间里，而在收工 Boss 心里。金色柱子就是那扇该被打开的门。",
		},
		{
			"id": "np_clue_archive",
			"position": Vector3(-11.6, 0.0, -2.2),
			"message": "线索档案：夜巡印章是开旧捷径门的凭据。第一单落地后它会浮出，回来按 E 打开这扇侧门。",
		},
	]
	for npc in _npc_data:
		var marker := PlaceholderKit.box("art_key_v2_npc_%s" % npc.id, Color("#57d4a5"), Vector3(0.8, 1.6, 0.8))
		marker.position = npc.position + Vector3(0.0, 0.8, 0.0)
		add_child(marker)


func _spawn_ritual(p_position: Vector3, p_color: Color = Color("#ffe08a")) -> void:
	var effect: Node3D = RitualScript.new()
	add_child(effect)
	effect.global_position = p_position
	effect.call("play", p_color)


func _try_v2_npc() -> void:
	if not is_instance_valid(_player):
		return
	for npc in _npc_data:
		var npc_position: Vector3 = npc.position
		if _player.global_position.distance_to(npc_position) < 3.2:
			_show_event(str(npc.message))
			if str(npc.id) == "np_clue_archive" and is_instance_valid(_world_map):
				_world_map.set_state("nw_clue", V2WorldMap.STATE_DONE)
			if str(npc.id) == "np_mystery_ghost" and _boss_waiting_npc and not _final_started:
				_boss_waiting_npc = false
				_boss_revealed = true
				_start_final_event()
			return


func _build_shortcut_gate_marker() -> void:
	var gate: Node = _region_gates.get("shortcut_gate")
	if not is_instance_valid(gate):
		return
	var lock := PlaceholderKit.box("art_key_v2_shortcut_lock", Color("#ffd166"), Vector3(0.24, 0.3, 0.24))
	lock.material_override = PlaceholderKit.emissive_material(Color("#ffd166"), 2.2)
	lock.position = gate.global_position + Vector3(0.0, 3.3, 0.0)
	add_child(lock)


# 门/捷径互动：靠近一个带坐标的世界门按 E —— 满足条件则开启，否则给出锁提示。
func _try_region_gate() -> bool:
	if not is_instance_valid(_player):
		return false
	for gate_id in _region_gates:
		var gate: Node = _region_gates[gate_id]
		if not is_instance_valid(gate) or not gate.has_method("can_open"):
			continue
		var gate_pos: Vector3 = gate.global_position
		if _player.global_position.distance_to(gate_pos) < 3.4:
			var abilities := {}
			if _has_night_stamp:
				abilities["night_stamp"] = true
			if gate.can_open(abilities, _boss_key_granted):
				gate.attempt_open(abilities, _boss_key_granted)
				if gate_id == "shortcut_gate":
					_show_event("夜巡印章捷径门开启！通往东侧的旧路恢复了")
					_on_shortcut_gate_opened(gate_pos)
				else:
					_show_event(str(gate.get("prompt")))
				return true
			var req_ability := str(gate.get("required_ability"))
			var req_boss := str(gate.get("required_boss"))
			var req_quest := str(gate.get("required_quest"))
			if req_ability == "night_stamp":
				_show_event("夜巡印章捷径门锁着：需要『夜巡印章』才能打开")
			elif req_boss == "seal_boss":
				_show_event("封印之门：需要击败收工 Boss 才能打开")
			elif req_quest == "side_b":
				_show_event("Boss 之门：需要完成支线『遗物线索』才能打开")
			else:
				_show_event("门锁住了")
			return true
	return false


func _on_shortcut_gate_opened(p_pos: Vector3) -> void:
	_spawn_ritual(p_pos, Color("#ffd166"))
	if is_instance_valid(_world_map):
		_world_map.set_state("nw_gate", V2WorldMap.STATE_DONE)
		_world_map.set_state("nw_key", V2WorldMap.STATE_DONE)


func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#111824")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#53607a")
	environment.ambient_light_energy = 0.6
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.shadow_enabled = true
	light.light_energy = 1.4
	light.rotation_degrees = Vector3(-58.0, -38.0, 0.0)
	add_child(light)


func _build_playtest() -> void:
	_build_environment()
	_build_playtest_region()
	_build_playtest_ground()
	_build_player()
	_build_camera()


func _build_playtest_region() -> void:
	var region: Dictionary = V2RouteData.load_region()
	if region.is_empty():
		return
	var region_id := str(region.get("region_id", "first_night"))
	var scene_path := FSAuthoringRuntime.scene_path_for_region(region_id)
	var handle: Dictionary = FSAuthoringRuntime.build(self, region, scene_path)
	if handle.is_empty():
		return
	_region_handle = handle
	_using_authored_region = true

	var focus := Vector3.ZERO
	var spawn := _authored_marker_node("spawn")
	if not is_instance_valid(spawn):
		var spawns := _authored_marker_nodes_by_kind("spawn")
		if not spawns.is_empty():
			spawn = spawns[0]
	if is_instance_valid(spawn):
		focus = spawn.global_position
	_spawn_position = Vector3(focus.x, 4.0, focus.z)


func _build_playtest_ground() -> void:
	var body := StaticBody3D.new()
	body.name = "PlaytestGround"
	var shape := BoxShape3D.new()
	shape.size = Vector3(120.0, 1.0, 120.0)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = -0.5
	body.add_child(collision)
	add_child(body)


func _build_route_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "RouteFloor"
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(40.0, 1.0, 16.0)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = -0.5
	body.add_child(collision)
	var mesh := PlaceholderKit.box("art_key_route_floor", Color("#39475d"), Vector3(40.0, 1.0, 16.0))
	mesh.position.y = -0.5
	body.add_child(mesh)

	_add_boundary_wall("art_key_route_wall_north", Vector3(40.0, 2.6, 0.6), Vector3(0.0, 1.3, -8.5))
	_add_boundary_wall("art_key_route_wall_south", Vector3(40.0, 2.6, 0.6), Vector3(0.0, 1.3, 8.5))
	_add_boundary_wall("art_key_route_wall_west", Vector3(0.6, 2.6, 18.0), Vector3(-20.5, 1.3, 0.0))
	_add_boundary_wall("art_key_route_wall_east", Vector3(0.6, 2.6, 18.0), Vector3(20.5, 1.3, 0.0))

	var start_pad := PlaceholderKit.box("art_key_route_start", Color("#b58b4a"), Vector3(2.0, 0.08, 3.4))
	start_pad.position = Vector3(-13.8, 0.04, 0.0)
	add_child(start_pad)


func _build_region_world() -> void:
	var region: Dictionary = V2RouteData.load_region()
	if region.is_empty():
		return
	var handle: Dictionary = FSAuthoringRuntime.build(self, region)
	if not handle.is_empty():
		_using_authored_region = true
	else:
		handle = V2RegionBuilder.build(self, region)
	_region_handle = handle
	var gates: Dictionary = handle.get("gates", {})
	_region_gates = gates


func _adopt_authored_region() -> void:
	_case_origins.clear()
	_rest_points.clear()
	for index in range(CASES.size()):
		var case_node := _authored_marker_node(str(CASES[index].get("route_id", "case_%d" % index)))
		var origin := Vector3(float(CASES[index]["zone_x"]), 0.0, 0.0)
		if is_instance_valid(case_node):
			origin = case_node.global_position
			origin.y = 0.0
		_case_origins.append(origin)
		var pad := _marker_visual(case_node)
		if pad == null:
			pad = PlaceholderKit.box("art_key_case_pad_%d" % index, Color("#425065"), Vector3(4.4, 0.1, 4.6))
			pad.position = origin + Vector3(0.0, 0.05, 0.0)
			add_child(pad)
		_case_pads.append(pad)
		_set_pad_color(index, Color("#425065"))

	var authored_rests := _authored_marker_nodes_by_kind("rest")
	for node in authored_rests:
		_rest_points.append(node.global_position)
	if _rest_points.is_empty():
		_rest_points.assign(REST_POINTS)

	var spawn_node := _authored_marker_node("spawn")
	if is_instance_valid(spawn_node):
		_spawn_position = spawn_node.global_position
	var boss_node := _authored_marker_node("boss_room")
	if is_instance_valid(boss_node):
		_boss_position = boss_node.global_position

	for index in range(2):
		var route_gate := _authored_route_gate("route_gate_%d" % index)
		if not is_instance_valid(route_gate):
			continue
		_route_gates.append(route_gate)
		var visual := _direct_mesh_child(route_gate)
		if visual:
			_gate_visuals.append(visual)


func _authored_marker_node(p_id: String) -> Node3D:
	var nodes: Dictionary = _region_handle.get("marker_nodes", {})
	var node: Node = nodes.get(p_id)
	return node as Node3D


func _authored_marker_nodes_by_kind(p_kind: String) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var markers: Dictionary = _region_handle.get("markers", {})
	var nodes: Dictionary = _region_handle.get("marker_nodes", {})
	for semantic_id in markers:
		var data: Dictionary = markers[semantic_id]
		if str(data.get("kind", "")) != p_kind:
			continue
		var node: Node = nodes.get(semantic_id)
		if node is Node3D:
			result.append(node)
	return result


func _authored_route_gate(p_id: String) -> StaticBody3D:
	var gates: Dictionary = _region_handle.get("route_gates", {})
	return gates.get(p_id) as StaticBody3D


func _marker_visual(p_node: Node) -> MeshInstance3D:
	if not is_instance_valid(p_node):
		return null
	return p_node.get_node_or_null("AuthoringMarker") as MeshInstance3D


func _direct_mesh_child(p_node: Node) -> MeshInstance3D:
	for child in p_node.get_children():
		if child is MeshInstance3D:
			return child
	return null


func _add_boundary_wall(p_name: String, p_size: Vector3, p_position: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = p_name
	var shape := BoxShape3D.new()
	shape.size = p_size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	body.position = p_position
	add_child(body)
	var mesh := PlaceholderKit.box(p_name, Color("#97a1b2"), p_size)
	body.add_child(mesh)


func _build_case_pads() -> void:
	_case_origins.clear()
	_case_pads.clear()
	for index in range(CASES.size()):
		var zone_x: float = CASES[index]["zone_x"]
		_case_origins.append(Vector3(zone_x, 0.0, 0.0))
		var pad := PlaceholderKit.box("art_key_case_pad_%d" % index, Color("#425065"), Vector3(4.4, 0.1, 4.6))
		pad.position = Vector3(zone_x, 0.05, 0.0)
		add_child(pad)
		_case_pads.append(pad)
		_set_pad_color(index, Color("#425065"))


func _build_rest_markers() -> void:
	_rest_points.assign(REST_POINTS)
	for index in [0, REST_POINTS.size() - 1]:
		var marker := PlaceholderKit.box("art_key_rest_marker_%d" % index, Color("#57d4a5"), Vector3(1.2, 0.07, 1.2))
		marker.position = Vector3(REST_POINTS[index].x, 0.04, REST_POINTS[index].z)
		add_child(marker)


func _set_pad_color(p_index: int, p_color: Color) -> void:
	if p_index >= 0 and p_index < _case_pads.size():
		_case_pads[p_index].material_override = PlaceholderKit.material(p_color)


func _build_route_gates() -> void:
	_route_gates.clear()
	_gate_visuals.clear()
	for gate_x in [-4.0, 4.0]:
		var body := StaticBody3D.new()
		body.name = "RouteGate_%s" % str(gate_x).replace(".0", "")
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.28, 3.0, 16.4)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		body.position = Vector3(gate_x, 1.5, 0.0)
		add_child(body)
		_route_gates.append(body)
		var mesh := PlaceholderKit.box("art_key_route_gate", Color("#6d7a90"), Vector3(0.28, 3.0, 16.4))
		body.add_child(mesh)
		_gate_visuals.append(mesh)


func _open_route_gate(p_index: int) -> void:
	if p_index < 0 or p_index >= _route_gates.size():
		return
	_route_gates[p_index].collision_layer = 0
	_route_gates[p_index].collision_mask = 0
	_gate_visuals[p_index].visible = false


func _build_player() -> void:
	_player = PlayerScript.new()
	_player.name = "Player"
	_player.position = _spawn_position
	_player.spawn_point = _player.position
	add_child(_player)
	_player.health_changed.connect(_on_player_health_changed)
	_player.momentum_changed.connect(_on_player_momentum_changed)
	_player.stamina_changed.connect(_on_player_stamina_changed)
	_player.beans_changed.connect(_on_player_beans_changed)
	_player.enhanced_sweep_ready.connect(_on_enhanced_sweep_ready)
	_player.enhanced_sweep_used.connect(_on_enhanced_sweep_used)
	_player.followup_available.connect(_on_followup_available)
	_player.defeated.connect(_handle_player_defeat)
	_player_health = _player.health
	_player_momentum = _player.get_momentum()
	_player_stamina = _player.stamina
	_player_beans = _player.beans


func _build_camera() -> void:
	_camera = Camera3D.new()
	add_child(_camera)
	GameView.apply_to_camera(_camera, _player.global_position)


func _update_follow_camera(delta: float) -> void:
	var camera_target := GameView.camera_position_for_focus(_player.global_position)
	var blend := 1.0 - exp(-6.5 * delta)
	_camera.global_position = _camera.global_position.lerp(camera_target, blend)
	_camera.look_at(GameView.look_target_for_focus(_player.global_position), Vector3.UP)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Hud"
	add_child(layer)
	_hud_label = Label.new()
	_hud_label.position = Vector2(700.0, 12.0)
	_hud_label.size = Vector2(880.0, 180.0)
	_hud_label.add_theme_color_override("font_color", Color("#f7fafd"))
	_hud_label.add_theme_font_size_override("font_size", 19)
	layer.add_child(_hud_label)

	_event_label = Label.new()
	_event_label.position = Vector2(0.0, 82.0)
	_event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_label.size = Vector2(1600.0, 40.0)
	_event_label.add_theme_color_override("font_color", Color("#ffe9a8"))
	_event_label.add_theme_font_size_override("font_size", 24)
	layer.add_child(_event_label)
	_build_status_panel()
	_update_hud()


func _update_hud() -> void:
	if not _hud_label:
		return
	var case_text := "收工事件"
	var stage_text := "%d / %d" % [CASES.size(), CASES.size()]
	if not _final_started:
		var data: Dictionary = CASES[_case_index]
		case_text = data.title
		stage_text = "%d / %d" % [_case_index + 1, CASES.size()]
	var objective_text := "封印终点：暂时无法到达"
	if _boss_waiting_npc:
		objective_text = "三单已清：寻找神秘鬼确认 Boss 弱点"
	elif _final_started and not _boss_key_granted:
		objective_text = "收工 Boss 现身：击败后取得封印钥匙"
	elif _boss_key_granted:
		objective_text = "封印终点：已打开，靠近金色柱按 E 确认"
	_hud_label.text = "夜班派单 | 第 %s 单\n现场：%s\n目标：%s\n还能上班：%d/%d\n剩余闹事鬼：%d\n好评：%d\n清扫连锁：%d\n扫劲：%d/%d\n\nWASD 移动 | Tab 地图 | 空格 跳跃 | Shift 冲刺(无消耗) | Q 撤步冲撞 | LMB 清扫 | RMB 短按横扫/长按陀螺 | 静止按住 X 回血 | E 互动/送走" % [
		stage_text,
		case_text,
		objective_text,
		_player_health,
		5,
		_remaining_ghosts,
		_review_count,
		_chain_count,
		_player_momentum,
		3,
	]


func _on_chain_triggered(_target: Node, _source: Node) -> void:
	_chain_count += 1
	if is_instance_valid(_player):
		_player.add_momentum(1)
		_player.add_bean(1)
	_show_event("清扫连锁 x%d" % _chain_count)
	_update_hud()


func _on_player_health_changed(p_health: int, _p_max_health: int) -> void:
	_player_health = p_health
	_update_hud()
	_refresh_health_pips()


func _on_player_momentum_changed(p_momentum: int, _p_max_momentum: int) -> void:
	_player_momentum = p_momentum
	_update_hud()


func _on_player_stamina_changed(p_stamina: float, _p_max_stamina: float) -> void:
	_player_stamina = p_stamina
	_refresh_stamina_bar()


func _on_player_beans_changed(p_beans: int, _p_max_beans: int) -> void:
	_player_beans = p_beans
	_refresh_beans()


func _on_enhanced_sweep_ready() -> void:
	_show_event("扫劲满：武器已充能，下一次 LMB 清扫造成双倍清扫")


func _on_enhanced_sweep_used() -> void:
	_show_event("强化清扫释放")


func _on_followup_available() -> void:
	_show_event("连携就绪：2 秒内按 RMB 追击")


func _handle_player_defeat() -> void:
	_show_event("出局：回到最近的休息点，当前案件重头开始")
	_chain_count = 0
	if not _final_started:
		_has_night_stamp = false
		_boss_waiting_npc = false
		_boss_revealed = false
		if is_instance_valid(_reward_pickup):
			_reward_pickup.queue_free()
		_reward_pickup = null
		if is_instance_valid(_player):
			_player.set_base_sweep_damage(1)
	for ghost in _active_ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	_active_ghosts.clear()
	_remaining_ghosts = 0
	if is_instance_valid(_player):
		_player.reset_momentum()
	_player_momentum = 0

	var rest_position := _rest_position(0)
	if _final_started:
		rest_position = _rest_position(_rest_points.size() - 1)
		_start_final_event()
	else:
		_case_index = 0
		_review_count = 0
		_close_all_route_gates()
		for index in range(_case_pads.size()):
			_set_pad_color(index, Color("#425065"))
		_activate_case(_case_index)

	if is_instance_valid(_player):
		_player.revive(rest_position)
	_update_hud()


func _rest_position(p_index: int) -> Vector3:
	if p_index >= 0 and p_index < _rest_points.size():
		return _rest_points[p_index]
	if p_index >= 0 and p_index < REST_POINTS.size():
		return REST_POINTS[p_index]
	return REST_POINTS[0]


func _close_all_route_gates() -> void:
	for gate in _route_gates:
		gate.collision_layer = 1
		gate.collision_mask = 1
	for visual in _gate_visuals:
		visual.visible = true


func _show_event(p_text: String) -> void:
	_event_label.text = p_text
	await get_tree().create_timer(1.8).timeout
	if is_instance_valid(_event_label):
		_event_label.text = ""


func _build_status_panel() -> void:
	var panel := ColorRect.new()
	panel.name = "StatusPanel"
	panel.color = Color(0.08, 0.1, 0.14, 0.92)
	panel.position = Vector2(16.0, 12.0)
	panel.size = Vector2(430.0, 240.0)
	var hud_parent := _hud_label.get_parent()
	hud_parent.add_child(panel)

	var character_label := Label.new()
	character_label.text = "夜班除灵师"
	character_label.position = Vector2(22.0, 18.0)
	character_label.add_theme_color_override("font_color", Color("#e8eef7"))
	character_label.add_theme_font_size_override("font_size", 20)
	hud_parent.add_child(character_label)

	_liquid_health = LiquidBarScript.new()
	_liquid_health.name = "LiquidHealth"
	_liquid_health.position = Vector2(24.0, 66.0)
	_liquid_health.size = Vector2(90.0, 120.0)
	hud_parent.add_child(_liquid_health)
	_refresh_health_pips()

	for index in range(3):
		var bean := TextureRect.new()
		bean.position = Vector2(136.0 + index * 26.0, 80.0)
		bean.size = Vector2(22.0, 22.0)
		bean.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bean.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hud_parent.add_child(bean)
		_bean_rects.append(bean)
	_refresh_beans()

	var stamina_label := Label.new()
	stamina_label.text = "体力"
	stamina_label.position = Vector2(136.0, 168.0)
	stamina_label.add_theme_color_override("font_color", Color("#9fd8b4"))
	stamina_label.add_theme_font_size_override("font_size", 15)
	hud_parent.add_child(stamina_label)

	var stamina_background := ColorRect.new()
	stamina_background.color = Color(0.22, 0.3, 0.32, 0.9)
	stamina_background.position = Vector2(178.0, 173.0)
	stamina_background.size = Vector2(210.0, 8.0)
	hud_parent.add_child(stamina_background)

	_stamina_bar_fill = ColorRect.new()
	_stamina_bar_fill.color = Color("#65e0a5")
	_stamina_bar_fill.position = Vector2(178.0, 173.0)
	_stamina_bar_fill.size = Vector2(210.0, 8.0)
	hud_parent.add_child(_stamina_bar_fill)
	_stamina_value_label = Label.new()
	_stamina_value_label.text = "15/15"
	_stamina_value_label.position = Vector2(392.0, 168.0)
	_stamina_value_label.add_theme_color_override("font_color", Color("#bff0d4"))
	_stamina_value_label.add_theme_font_size_override("font_size", 13)
	hud_parent.add_child(_stamina_value_label)
	_refresh_stamina_bar()


func _refresh_health_pips() -> void:
	if is_instance_valid(_liquid_health):
		_liquid_health.set_ratio(float(_player_health) / 5.0)


func _refresh_beans() -> void:
	for index in range(_bean_rects.size()):
		var texture := PlaceholderKit.circle_texture(Color("#f5fbff") if index < _player_beans else Color("#2b3038"), Color("#8a949c"), 8)
		_bean_rects[index].texture = texture


func _refresh_stamina_bar() -> void:
	if not is_instance_valid(_stamina_bar_fill):
		return
	var ratio := clampf(_player_stamina / 15.0, 0.0, 1.0)
	_stamina_bar_fill.size.x = 210.0 * ratio
	if is_instance_valid(_stamina_value_label):
		_stamina_value_label.text = "%d/15" % ceili(_player_stamina)


func _setup_map_hud() -> void:
	_map_layer = CanvasLayer.new()
	_map_layer.name = "RegionMap"
	add_child(_map_layer)

	var panel := ColorRect.new()
	panel.name = "RegionMapPanel"
	panel.color = Color(0.07, 0.1, 0.12, 0.96)
	panel.position = Vector2(400.0, 120.0)
	panel.size = Vector2(800.0, 620.0)
	_map_layer.add_child(panel)

	var title := Label.new()
	title.text = "首夜城区·路网图"
	title.position = Vector2(424.0, 146.0)
	title.add_theme_color_override("font_color", Color("#f4f7fb"))
	title.add_theme_font_size_override("font_size", 28)
	_map_layer.add_child(title)

	_map_current_label = Label.new()
	_map_current_label.position = Vector2(424.0, 190.0)
	_map_current_label.add_theme_color_override("font_color", Color("#ffd166"))
	_map_current_label.add_theme_font_size_override("font_size", 20)
	_map_layer.add_child(_map_current_label)

	# 用节点式世界地图替换旧“区域文字堆叠”——每个节点按 build state（未开始/正在做/已做）上色。
	_world_map = V2WorldMap.new()
	_world_map.name = "NightWatchRegionMap"
	_world_map.position = Vector2(424.0, 232.0)
	_world_map.size = Vector2(752.0, 430.0)
	_world_map.load_from(V2WorldMap.seed_night_watch())
	_map_layer.add_child(_world_map)

	var map_hint := Label.new()
	map_hint.text = "按 Tab 关闭地图"
	map_hint.position = Vector2(424.0, 700.0)
	map_hint.add_theme_color_override("font_color", Color("#93a2b5"))
	map_hint.add_theme_font_size_override("font_size", 16)
	_map_layer.add_child(map_hint)
	_map_layer.visible = false


func _toggle_map() -> void:
	_map_open = not _map_open
	_map_layer.visible = _map_open
	_update_map()


func _update_map() -> void:
	if not is_instance_valid(_map_current_label) or not is_instance_valid(_world_map):
		return
	var current_id := ""
	if is_instance_valid(_player):
		current_id = _world_map.room_for_world_x(_player.global_position.x)
	_world_map.set_current(current_id)
	var current := "未定位"
	if not current_id.is_empty():
		current = str(_world_map.room(current_id).get("name", current_id))
	_map_current_label.text = "当前位置：%s" % current

	# 封印终点随进度变色：拿到印章后可作为终结目标。
	if _boss_key_granted:
		_world_map.set_state("seal", V2WorldMap.STATE_DONE)
	elif _final_started:
		_world_map.set_state("seal", V2WorldMap.STATE_IN_PROGRESS)
