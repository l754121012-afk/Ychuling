extends Node3D

const PlayerScript := preload("res://scripts/player/PlayerController.gd")
const GhostScript := preload("res://scripts/actors/TestGhost.gd")
const LiquidBarScript := preload("res://scripts/ui/LiquidHealthBar.gd")
const GateScript := preload("res://scripts/v2/V2AbilityGate.gd")

const CAMERA_HEIGHT := 10.5
const CAMERA_BACK := 5.0

const CASES: Array[Dictionary] = [
	{
		"title": "沙发下的灰影",
		"zone_x": -8.0,
		"ghost_positions": [Vector3(-9.6, 0.0, -1.7), Vector3(-8.3, 0.0, -0.7), Vector3(-8.1, 0.0, 0.9), Vector3(-6.7, 0.0, 1.5)],
		"ghost_styles": ["swipe", "shot", "pool", "lunge"],
	},
	{
		"title": "电视里的歌声",
		"zone_x": 0.0,
		"ghost_positions": [Vector3(-1.7, 0.0, -1.5), Vector3(-0.7, 0.0, -0.7), Vector3(0.7, 0.0, 0.8), Vector3(1.5, 0.0, 1.5)],
		"ghost_styles": ["shot", "pool", "lunge", "swipe"],
	},
	{
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
var _seal_gate
var _target_marker: MeshInstance3D


func _ready() -> void:
	_build_environment()
	_build_route_floor()
	_build_case_pads()
	_build_rest_markers()
	_build_route_gates()
	_build_v2_seal_end()
	_build_player()
	_build_camera()
	_build_hud()
	_activate_case(_case_index)


func _process(delta: float) -> void:
	if not _player or not _camera:
		return
	var camera_target := _player.global_position + Vector3(0.0, CAMERA_HEIGHT, CAMERA_BACK)
	var blend := 1.0 - exp(-6.5 * delta)
	_camera.global_position = _camera.global_position.lerp(camera_target, blend)
	_camera.look_at(_player.global_position + Vector3.UP, Vector3.UP)
	if _boss_key_granted and not _shift_done and _player.global_position.x > 17.0:
		_finish_shift()


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
	_set_pad_color(_case_index, Color("#6fce8f"))
	if _case_index < CASES.size() - 1:
		_show_event("顾客回访：五星好评，下一单已亮起")
		_case_index += 1
		if _case_index == 1:
			_open_route_gate(0)
		elif _case_index == 2:
			_open_route_gate(1)
		_activate_case(_case_index)
	else:
		_show_event("三单清完，收工事件来了")
		_start_final_event()


func _activate_case(p_index: int) -> void:
	_set_pad_color(p_index, Color("#ffd166"))
	var data: Dictionary = CASES[p_index]
	var positions: Array = data.ghost_positions
	var styles: Array = data.ghost_styles
	for ghost_index in range(positions.size()):
		var ghost: TestGhost = GhostScript.new()
		ghost.name = "CaseGhost_%d_%d" % [p_index, ghost_index]
		ghost.position = positions[ghost_index]
		ghost.configure_attack_style(str(styles[ghost_index]))
		add_child(ghost)
		ghost.sent_off.connect(_on_ghost_sent)
		ghost.chain_triggered.connect(_on_chain_triggered)
		_active_ghosts.append(ghost)
	_remaining_ghosts = _active_ghosts.size()
	_update_hud()


func _start_final_event() -> void:
	_final_started = true
	var minion_styles: Array[String] = ["swipe", "pool", "shot"]
	for index in range(FINAL_MINION_POS.size()):
		var minion: TestGhost = GhostScript.new()
		minion.name = "FinalMinion_%d" % index
		minion.hits_to_stagger = 4
		minion.art_scale = 0.8
		minion.configure_attack_style(minion_styles[index])
		minion.position = FINAL_MINION_POS[index]
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
	big_ghost.position = FINAL_POS
	add_child(big_ghost)
	big_ghost.sent_off.connect(_on_ghost_sent)
	big_ghost.chain_triggered.connect(_on_chain_triggered)
	_active_ghosts.append(big_ghost)
	_remaining_ghosts = _active_ghosts.size()
	_update_hud()


func _finish_shift() -> void:
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
	if is_instance_valid(_seal_gate):
		_seal_gate.try_open({}, true)
	_show_event("封印钥匙到手：封印终点已打开，走过去确认收工")
	_update_hud()


func _build_v2_seal_end() -> void:
	_seal_gate = GateScript.new()
	_seal_gate.set("gate_id", "seal_door")
	_seal_gate.set("required_boss", "seal_boss")
	_seal_gate.position = Vector3(15.4, 0.0, 0.0)
	add_child(_seal_gate)

	_target_marker = PlaceholderKit.box("art_key_v2_seal_target", Color("#f2d77a"), Vector3(1.2, 4.0, 1.2))
	_target_marker.position = Vector3(18.2, 2.0, 0.0)
	add_child(_target_marker)


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
	for index in range(CASES.size()):
		var zone_x: float = CASES[index]["zone_x"]
		var pad := PlaceholderKit.box("art_key_case_pad_%d" % index, Color("#425065"), Vector3(4.4, 0.1, 4.6))
		pad.position = Vector3(zone_x, 0.05, 0.0)
		add_child(pad)
		_case_pads.append(pad)
		_set_pad_color(index, Color("#425065"))


func _build_rest_markers() -> void:
	for index in [0, REST_POINTS.size() - 1]:
		var marker := PlaceholderKit.box("art_key_rest_marker_%d" % index, Color("#57d4a5"), Vector3(1.2, 0.07, 1.2))
		marker.position = Vector3(REST_POINTS[index].x, 0.04, REST_POINTS[index].z)
		add_child(marker)


func _set_pad_color(p_index: int, p_color: Color) -> void:
	if p_index >= 0 and p_index < _case_pads.size():
		_case_pads[p_index].material_override = PlaceholderKit.material(p_color)


func _build_route_gates() -> void:
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
	_player.position = Vector3(-14.6, 0.9, 0.0)
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
	_camera.fov = 52.0
	add_child(_camera)
	_camera.global_position = _player.global_position + Vector3(0.0, CAMERA_HEIGHT, CAMERA_BACK)
	_camera.look_at(_player.global_position + Vector3.UP, Vector3.UP)


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
	if _boss_key_granted:
		objective_text = "封印终点：已打开，前往确认"
	_hud_label.text = "夜班派单 | 第 %s 单\n现场：%s\n目标：%s\n还能上班：%d/%d\n剩余闹事鬼：%d\n好评：%d\n清扫连锁：%d\n扫劲：%d/%d\n\nWASD 移动 | 空格 跳跃 | Shift 冲刺 | LMB 清扫 | RMB 短按横扫/长按陀螺 | 静止按住 X 回血 | E 送走" % [
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
	for ghost in _active_ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	_active_ghosts.clear()
	_remaining_ghosts = 0
	if is_instance_valid(_player):
		_player.reset_momentum()
	_player_momentum = 0

	var rest_position := REST_POINTS[0]
	if _final_started:
		rest_position = REST_POINTS[REST_POINTS.size() - 1]
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
