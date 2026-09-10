@tool
extends SubViewportContainer

const BACKGROUND_COLOR := Color("111820")
const FLOOR_COLOR := Color("28323d")
const FIT_SIZE := 1.85

var _viewport: SubViewport
var _pivot: Node3D
var _model: Node3D
var _auto_rotate := true


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 190.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	stretch = true
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_built()
	set_process(_auto_rotate)


func _process(p_delta: float) -> void:
	if is_instance_valid(_pivot):
		_pivot.rotate_y(p_delta * 0.35)


func set_model(p_entry: Dictionary) -> void:
	_ensure_built()
	_clear_model()
	var path := str(p_entry.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var packed := ResourceLoader.load(path)
	if not (packed is PackedScene):
		return
	var instance := (packed as PackedScene).instantiate()
	if not (instance is Node3D):
		instance.free()
		return
	_model = instance as Node3D
	_model.name = "PreviewModel"
	_pivot.add_child(_model)
	_normalize_model(_model)
	_pivot.rotation = Vector3.ZERO


func clear_model() -> void:
	_clear_model()


func set_auto_rotate(p_enabled: bool) -> void:
	_auto_rotate = p_enabled
	set_process(p_enabled)


func _clear_model() -> void:
	if is_instance_valid(_model):
		_model.free()
	_model = null


func _ensure_built() -> void:
	if is_instance_valid(_viewport):
		return
	_viewport = SubViewport.new()
	_viewport.name = "ModelPreviewViewport"
	_viewport.size = Vector2i(320, 210)
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.positional_shadow_atlas_size = 1024
	add_child(_viewport)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = BACKGROUND_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d7e4ef")
	environment.ambient_light_energy = 1.15
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_viewport.add_child(world_environment)

	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	camera.current = true
	camera.fov = 38.0
	_viewport.add_child(camera)
	camera.position = Vector3(3.7, 2.7, 4.8)
	camera.look_at(Vector3(0.0, 0.9, 0.0), Vector3.UP)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_color = Color("ffe9c7")
	key_light.light_energy = 1.55
	key_light.shadow_enabled = true
	key_light.rotation_degrees = Vector3(-46.0, -34.0, 0.0)
	_viewport.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.light_color = Color("9bc8ff")
	fill_light.light_energy = 0.7
	fill_light.rotation_degrees = Vector3(-24.0, 145.0, 0.0)
	_viewport.add_child(fill_light)

	var floor := MeshInstance3D.new()
	floor.name = "Floor"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.55
	cylinder.bottom_radius = 1.65
	cylinder.height = 0.05
	cylinder.radial_segments = 48
	floor.mesh = cylinder
	floor.position.y = -0.035
	var material := StandardMaterial3D.new()
	material.albedo_color = FLOOR_COLOR
	material.roughness = 0.96
	floor.material_override = material
	_viewport.add_child(floor)

	_pivot = Node3D.new()
	_pivot.name = "ModelPivot"
	_viewport.add_child(_pivot)


func _normalize_model(p_model: Node3D) -> void:
	var bounds := _node_aabb_in_parent(p_model)
	if bounds.size.length() <= 0.0001:
		return
	var max_size := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	var fit_scale := FIT_SIZE / maxf(max_size, 0.0001)
	p_model.scale = Vector3.ONE * fit_scale
	bounds = _node_aabb_in_parent(p_model)
	var center := bounds.get_center()
	p_model.position += Vector3(-center.x, -bounds.position.y, -center.z)


func _node_aabb_in_parent(p_node: Node3D) -> AABB:
	return _transform_aabb(_subtree_aabb(p_node), p_node.transform)


func _subtree_aabb(p_node: Node3D) -> AABB:
	var result := AABB()
	var has_bounds := false
	if p_node is MeshInstance3D and (p_node as MeshInstance3D).mesh:
		result = (p_node as MeshInstance3D).get_aabb()
		has_bounds = true
	for child in p_node.get_children():
		if not (child is Node3D):
			continue
		var child_bounds := _node_aabb_in_parent(child as Node3D)
		result = result.merge(child_bounds) if has_bounds else child_bounds
		has_bounds = true
	return result


func _transform_aabb(p_aabb: AABB, p_transform: Transform3D) -> AABB:
	var result := AABB(p_transform * p_aabb.position, Vector3.ZERO)
	for x in [p_aabb.position.x, p_aabb.end.x]:
		for y in [p_aabb.position.y, p_aabb.end.y]:
			for z in [p_aabb.position.z, p_aabb.end.z]:
				result = result.expand(p_transform * Vector3(x, y, z))
	return result
