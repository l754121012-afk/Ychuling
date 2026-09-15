extends SceneTree

const DEFAULT_SCENE_PATH := "res://authoring/scenes/spirit_sprawl_geometry_cubes_v2_test.tscn"
const DEFAULT_OUTPUT_PATH := "C:/Users/李泽文/Documents/Codex/2026-09-08/3d-f-crypt-custodian-green-chs/outputs/cube-v2-topdown.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_path := DEFAULT_SCENE_PATH
	var output_path := DEFAULT_OUTPUT_PATH
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scene="):
			scene_path = argument.trim_prefix("--scene=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")

	var packed := ResourceLoader.load(scene_path) as PackedScene
	if packed == null:
		push_error("无法加载场景：%s" % scene_path)
		quit(1)
		return
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	for _frame in range(4):
		await process_frame

	root.size = Vector2i(1920, 1080)
	_set_flat_top_capture_environment()
	_hide_non_terrain(scene)

	var camera := Camera3D.new()
	camera.name = "CaptureTopDown"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 160.0
	camera.near = 1.0
	camera.far = 500.0
	camera.position = Vector3(0.0, 260.0, 1.0)
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	root.add_child(camera)
	camera.current = true

	var light := DirectionalLight3D.new()
	light.name = "CaptureTopLight"
	light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	light.shadow_enabled = false
	light.light_energy = 2.8
	root.add_child(light)

	for _frame in range(6):
		await process_frame
	var image := root.get_texture().get_image()
	var save_error := image.save_png(output_path)
	print(
		"FS_CAPTURE_TOP_DOWN saved=%s size=%dx%d scene=%s output=%s errors=%d" % [
			save_error == OK,
			image.get_width(),
			image.get_height(),
			scene_path,
			output_path,
			0 if save_error == OK else 1,
		]
	)
	quit(0 if save_error == OK else 1)


func _set_flat_top_capture_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#18212b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.95, 0.98, 1.0)
	environment.ambient_light_energy = 2.2
	root.world_3d.environment = environment


func _hide_non_terrain(p_scene: Node) -> void:
	for child in p_scene.get_children():
		if child is CanvasLayer or child is CharacterBody3D:
			child.visible = false
		if str(child.name).to_upper().contains("WATER"):
			child.visible = false
		_hide_non_terrain(child)
