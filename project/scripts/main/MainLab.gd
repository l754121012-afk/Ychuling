extends Node3D

const PlayerScript := preload("res://scripts/player/PlayerController.gd")
const GhostScript := preload("res://scripts/actors/TestGhost.gd")

const CAMERA_HEIGHT := 9.2
const CAMERA_BACK := 4.4

var _player: PlayerController
var _camera: Camera3D
var _sendoff_count := 0
var _hud_label: Label


func _ready() -> void:
	_build_environment()
	_build_test_room()
	_build_player()
	_build_ghosts()
	_build_camera()
	_build_debug_hud()


func _process(delta: float) -> void:
	if not _player or not _camera:
		return
	var camera_target := _player.global_position + Vector3(0.0, CAMERA_HEIGHT, CAMERA_BACK)
	var blend := 1.0 - exp(-7.0 * delta)
	_camera.global_position = _camera.global_position.lerp(camera_target, blend)
	_camera.look_at(_player.global_position + Vector3.UP, Vector3.UP)


func _on_player_sendoff(_target: Node) -> void:
	_sendoff_count += 1
	if _hud_label:
		_hud_label.text = "已送走鬼魂：%d\nWASD 移动 | 空格 跳跃 | Shift 冲刺 | 鼠标左键 清扫 | E 送走" % _sendoff_count


func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#17202c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#4c5a72")
	environment.ambient_light_energy = 0.55
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.shadow_enabled = true
	light.light_energy = 1.35
	light.rotation_degrees = Vector3(-58.0, -36.0, 0.0)
	add_child(light)


func _build_test_room() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	add_child(floor_body)

	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(20.0, 1.0, 15.0)
	var floor_collision := CollisionShape3D.new()
	floor_collision.shape = floor_shape
	floor_collision.position.y = -0.5
	floor_body.add_child(floor_collision)

	var floor_mesh := PlaceholderKit.box("art_key_room_floor", Color("#37445a"), Vector3(20.0, 1.0, 15.0))
	floor_mesh.position.y = -0.5
	floor_body.add_child(floor_mesh)

	_add_wall("art_key_wall_north", Vector3(20.0, 2.4, 0.6), Vector3(0.0, 1.2, -7.8))
	_add_wall("art_key_wall_south", Vector3(20.0, 2.4, 0.6), Vector3(0.0, 1.2, 7.8))
	_add_wall("art_key_wall_west", Vector3(0.6, 2.4, 16.0), Vector3(-10.2, 1.2, 0.0))
	_add_wall("art_key_wall_east", Vector3(0.6, 2.4, 16.0), Vector3(10.2, 1.2, 0.0))

	var prop := PlaceholderKit.box("art_key_room_prop_sofa", Color("#4f3a3a"), Vector3(1.4, 0.8, 0.9))
	prop.position = Vector3(-3.0, 0.4, 0.0)
	add_child(prop)
	var prop_wall := StaticBody3D.new()
	prop_wall.name = "PropCollider"
	var prop_shape := BoxShape3D.new()
	prop_shape.size = Vector3(1.4, 0.8, 0.9)
	var prop_col := CollisionShape3D.new()
	prop_col.shape = prop_shape
	prop_wall.add_child(prop_col)
	prop_wall.position = prop.position
	prop_wall.position.y = 0.5
	add_child(prop_wall)


func _add_wall(p_name: String, p_size: Vector3, p_position: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = p_name
	var shape := BoxShape3D.new()
	shape.size = p_size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	body.position = p_position
	add_child(body)

	var wall_mesh := PlaceholderKit.box(p_name, Color("#8b94a6"), p_size)
	body.add_child(wall_mesh)
	wall_mesh.position.y = 0.0


func _build_player() -> void:
	_player = PlayerScript.new()
	_player.name = "Player"
	_player.position = Vector3(0.0, 0.9, 1.8)
	add_child(_player)
	_player.sendoff_performed.connect(_on_player_sendoff)


func _build_ghosts() -> void:
	var ghosts: Array[Dictionary] = [
		{"pos": Vector3(-2.4, 0.0, -2.0)},
		{"pos": Vector3(2.2, 0.0, -2.6)},
		{"pos": Vector3(0.0, 0.0, -3.8)},
	]
	for index in range(ghosts.size()):
		var ghost: TestGhost = GhostScript.new()
		ghost.name = "Ghost_%d" % index
		ghost.position = ghosts[index].pos
		add_child(ghost)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = 50.0
	add_child(_camera)
	_camera.global_position = _player.global_position + Vector3(0.0, CAMERA_HEIGHT, CAMERA_BACK)
	_camera.look_at(_player.global_position + Vector3.UP, Vector3.UP)


func _build_debug_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DebugHud"
	add_child(layer)
	_hud_label = Label.new()
	_hud_label.position = Vector2(14.0, 10.0)
	_hud_label.add_theme_color_override("font_color", Color("#f4f7ff"))
	_hud_label.add_theme_font_size_override("font_size", 18)
	_hud_label.text = "已送走鬼魂：0\nWASD 移动 | 空格 跳跃 | Shift 冲刺 | 鼠标左键 清扫 | E 送走"
	layer.add_child(_hud_label)
