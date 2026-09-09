extends SceneTree

const ROUTE_SCENE := "res://scenes/main/V2FirstLoop.tscn"
const OUTPUT_DIR := "C:/Users/李泽文/Documents/Codex/2026-09-08/3d-f-crypt-custodian-green-chs/outputs"
const PNG_PATH := OUTPUT_DIR + "/map-v2-topdown.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load(ROUTE_SCENE)
	var main: Node = packed.instantiate()
	root.add_child(main)
	for _frame in range(4):
		await process_frame

	_hide_gameplay(main)

	# Bump the world ambient so the placeholder geometry (pillars, plants,
	# cases, gates) actually reads in a straight-down shot. This is capture-only
	# for the confirmation screenshot; it does not change the gameplay scene.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#11161f")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.92, 0.96, 1.0)
	env.ambient_light_energy = 2.6
	root.world_3d.environment = env

	var cam := Camera3D.new()
	cam.name = "CaptureTopDown"
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 26.0
	cam.near = 1.0
	cam.far = 80.0
	cam.position = Vector3(0.0, 30.0, 0.0)
	cam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	root.add_child(cam)
	cam.current = true

	# The gameplay scene's directional light points diagonally, so flat floor
	# tops receive almost no light from a straight-down camera. Add a dedicated
	# top-down light for the capture so the zone colors read clearly. This only
	# affects this render script, not the actual scene or gameplay data.
	var top_light := DirectionalLight3D.new()
	top_light.name = "CaptureTopLight"
	top_light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	top_light.shadow_enabled = false
	top_light.light_energy = 3.0
	root.add_child(top_light)

	_add_zone_overlays()
	_add_ground_labels()

	for _frame in range(6):
		await process_frame
	cam.current = true
	await process_frame

	var img: Image = root.get_texture().get_image()
	var err := img.save_png(PNG_PATH)
	print("CAPTURE saved=%s err=%s size=%sx%s png=%s" % [err == OK, err, img.get_width(), img.get_height(), PNG_PATH])
	quit(0 if err == OK else 1)


func _hide_gameplay(p_main: Node) -> void:
	for child in p_main.get_children():
		if child is CanvasLayer:
			child.visible = false
		elif child is CharacterBody3D:
			child.visible = false


func _add_zone_overlays() -> void:
	# Capture-only unshaded color patches so the four districts read as distinct
	# regions in a flat top-down confirmation shot. The gameplay route data is
	# untouched; these overlays only exist inside this render script.
	_add_zone_overlay("夜巡司", -14.75, 4.75, 16.0, Color("#4a90d9"))
	_add_zone_overlay("居住区", -2.75, 7.25, 16.0, Color("#56b98a"))
	_add_zone_overlay("旧剧场·电视台", 7.5, 3.0, 16.0, Color("#d9a441"))
	_add_zone_overlay("Boss 封印场", 15.25, 4.75, 16.0, Color("#c95d5d"))


func _add_zone_overlay(p_label: String, p_x: float, p_span: float, p_depth: float, p_color: Color) -> void:
	var overlay: MeshInstance3D = PlaceholderKit.box("CaptureZone_%s" % p_label, p_color, Vector3(p_span * 2.0, 0.02, p_depth))
	overlay.material_override = _unshaded_material(p_color)
	overlay.position = Vector3(p_x, 0.05, 0.0)
	root.add_child(overlay)


func _unshaded_material(p_color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = p_color
	return mat


func _add_ground_labels() -> void:
	var markers: Array[Dictionary] = [
		{"text": "夜巡司", "x": -14.75, "z": 0.0},
		{"text": "居住区", "x": -2.75, "z": 0.0},
		{"text": "旧剧场·电视台", "x": 7.5, "z": 0.0},
		{"text": "Boss 封印场", "x": 15.25, "z": 0.0},
		{"text": "案件1 沙发灰影", "x": -8.0, "z": -4.4},
		{"text": "案件2 电视歌声", "x": 0.0, "z": -4.4},
		{"text": "案件3 衣柜呼吸", "x": 8.0, "z": -4.4},
		{"text": "Boss 收工区", "x": 11.0, "z": -4.4},
		{"text": "封印终点", "x": 18.2, "z": -4.4},
		{"text": "休息点", "x": -13.5, "z": 4.0},
		{"text": "夜巡印章", "x": -8.0, "z": 4.0},
	]
	for marker in markers:
		_add_label(marker)


func _add_label(p_marker: Dictionary) -> void:
	var label := Label3D.new()
	label.name = "MapLabel_%s" % str(p_marker.get("text"))
	label.text = str(p_marker.get("text"))
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.no_depth_test = true
	label.position = Vector3(float(p_marker.get("x")), 0.18, float(p_marker.get("z")))
	label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	label.modulate = Color("#ffffff")
	label.outline_modulate = Color("#10161f")
	label.font_size = 96
	label.pixel_size = 0.05
	label.outline_size = 28
	root.add_child(label)
