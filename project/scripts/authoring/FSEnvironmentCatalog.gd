class_name FSEnvironmentCatalog
extends RefCounted

const ENVIRONMENT_PREFIX := "ENVIRONMENT_"
const META_KEY := "__fs_environment_effect"

const ENTRIES := [
	{
		"id": "warm_lantern_light",
		"label": "暖色灯笼光",
		"category": "灯光",
		"tags": ["灯光", "暖色", "街道", "雨夜"],
	},
	{
		"id": "cold_spotlight",
		"label": "冷色聚光",
		"category": "灯光",
		"tags": ["灯光", "冷色", "聚光", "重点区域"],
	},
	{
		"id": "moonlight",
		"label": "月光",
		"category": "灯光",
		"tags": ["灯光", "月光", "全局", "蓝灰"],
	},
	{
		"id": "ground_fog",
		"label": "地面雾",
		"category": "大气",
		"tags": ["雾", "地面", "湿冷", "大气"],
	},
	{
		"id": "cloud_layer",
		"label": "低云层",
		"category": "大气",
		"tags": ["云", "天空", "大气", "远层"],
	},
	{
		"id": "fire",
		"label": "火焰与动态光",
		"category": "火焰与粒子",
		"tags": ["火焰", "灯光", "粒子", "暖色"],
	},
	{
		"id": "rain_sheet",
		"label": "成片雨幕",
		"category": "天气",
		"tags": ["雨", "雨幕", "天气", "成片"],
	},
	{
		"id": "wind_lines",
		"label": "环境风线",
		"category": "天气",
		"tags": ["风", "气流", "雨城", "环境"],
	},
	{
		"id": "dust_motes",
		"label": "尘埃微粒",
		"category": "火焰与粒子",
		"tags": ["尘埃", "微粒", "空气", "散射"],
	},
]


static func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_entry in ENTRIES:
		if raw_entry is Dictionary:
			result.append(raw_entry.duplicate(true))
	return result


static func find(p_effect_id: String) -> Dictionary:
	for entry in entries():
		if str(entry.get("id", "")) == p_effect_id:
			return entry
	return {}


static func environment_params(p_entry: Dictionary) -> Dictionary:
	return {
		"effect_id": str(p_entry.get("id", "")),
		"label": str(p_entry.get("label", "")),
		"category": str(p_entry.get("category", "")),
		"tags": p_entry.get("tags", []).duplicate(),
	}


static func is_environment_node(p_node: Node) -> bool:
	return p_node != null and p_node.has_meta(META_KEY)


static func environment_node(p_node: Node) -> Node3D:
	if p_node is Node3D and is_environment_node(p_node):
		return p_node as Node3D
	for child in p_node.get_children():
		var found := environment_node(child)
		if found:
			return found
	return null


static func apply_environment(
	p_parent: Node,
	p_entry: Dictionary,
	p_owner: Node = null,
	p_display_name: String = ""
) -> Dictionary:
	if p_parent == null:
		return {"ok": false, "error": "没有可用于创建环境特效的父节点。"}
	var effect_id := str(p_entry.get("id", "")).strip_edges()
	if effect_id.is_empty():
		return {"ok": false, "error": "环境特效 ID 不能为空。"}

	var root := Node3D.new()
	var label := p_display_name.strip_edges()
	if label.is_empty():
		label = str(p_entry.get("label", effect_id)).strip_edges()
	root.name = _next_environment_name(p_parent, effect_id, label)
	p_parent.add_child(root)
	var build_error := _build_environment(root, effect_id)
	if not build_error.is_empty():
		p_parent.remove_child(root)
		root.free()
		return {"ok": false, "error": build_error}
	root.set_meta(META_KEY, environment_params(p_entry))
	if p_owner and p_owner.is_ancestor_of(root):
		_assign_owner_recursive(root, p_owner)
	return {
		"ok": true,
		"node": root,
		"environment": environment_params(p_entry),
	}


static func repair_environment_nodes(p_parent: Node, p_owner: Node) -> Dictionary:
	if (
		p_parent == null
		or p_owner == null
		or (p_parent != p_owner and not p_owner.is_ancestor_of(p_parent))
	):
		return {
			"ok": false,
			"repaired": 0,
			"rebuilt": 0,
			"errors": ["环境节点修复需要当前作者场景根节点作为 owner。"],
		}
	var environment_nodes: Array[Node] = []
	_collect_environment_nodes(p_parent, environment_nodes)
	var repaired := 0
	var rebuilt := 0
	var errors: Array[String] = []
	for node in environment_nodes:
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if node.get_child_count() == 0:
			var params_value = node.get_meta(META_KEY, {})
			var params: Dictionary = params_value if params_value is Dictionary else {}
			var effect_id := str(params.get("effect_id", "")).strip_edges()
			var build_error := _build_environment(node as Node3D, effect_id)
			if build_error.is_empty():
				rebuilt += 1
			else:
				errors.append("%s: %s" % [str(node.name), build_error])
				continue
		if _assign_owner_recursive(node, p_owner):
			repaired += 1
	return {
		"ok": errors.is_empty(),
		"repaired": repaired,
		"rebuilt": rebuilt,
		"errors": errors,
	}


static func remove_environment(p_node: Node) -> bool:
	if not is_environment_node(p_node):
		return false
	var parent := p_node.get_parent()
	if parent == null:
		return false
	parent.remove_child(p_node)
	p_node.free()
	return true


static func _next_environment_name(
	p_parent: Node,
	p_effect_id: String,
	p_label: String
) -> String:
	var index := 1
	var name_prefix := "%s%s_%s" % [
		ENVIRONMENT_PREFIX,
		p_label,
		p_effect_id.to_upper(),
	]
	while p_parent.has_node("%s_%02d" % [name_prefix, index]):
		index += 1
	return "%s_%02d" % [name_prefix, index]


static func _build_environment(p_root: Node3D, p_effect_id: String) -> String:
	match p_effect_id:
		"warm_lantern_light":
			_add_omni_light(
				p_root,
				Vector3(0.0, 2.2, 0.0),
				Color("#ffc36a"),
				3.5,
				8.0
			)
		"cold_spotlight":
			var spot := SpotLight3D.new()
			spot.name = "冷色聚光"
			spot.position = Vector3(0.0, 5.0, 0.0)
			spot.rotation_degrees = Vector3(-55.0, 0.0, 0.0)
			spot.light_color = Color("#9edcff")
			spot.light_energy = 4.0
			spot.spot_range = 14.0
			spot.spot_angle = 32.0
			spot.shadow_enabled = true
			p_root.add_child(spot)
		"moonlight":
			var moon := DirectionalLight3D.new()
			moon.name = "月光"
			moon.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
			moon.light_color = Color("#b9d8ff")
			moon.light_energy = 0.65
			moon.shadow_enabled = true
			p_root.add_child(moon)
		"ground_fog":
			_add_fog_particles(p_root)
		"cloud_layer":
			_add_cloud_layer(p_root)
		"fire":
			_add_fire(p_root)
		"rain_sheet":
			_add_rain_sheet(p_root)
		"wind_lines":
			_add_wind_lines(p_root)
		"dust_motes":
			_add_dust_motes(p_root)
		_:
			return "未知环境特效：%s" % p_effect_id
	return ""


static func _add_omni_light(
	p_root: Node3D,
	p_position: Vector3,
	p_color: Color,
	p_energy: float,
	p_range: float
) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = "暖色灯光"
	light.position = p_position
	light.light_color = p_color
	light.light_energy = p_energy
	light.omni_range = p_range
	light.shadow_enabled = true
	p_root.add_child(light)
	return light


static func _add_mesh_instance(
	p_root: Node3D,
	p_name: String,
	p_mesh: Mesh,
	p_position: Vector3,
	p_scale: Vector3 = Vector3.ONE
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = p_name
	instance.mesh = p_mesh
	instance.position = p_position
	instance.scale = p_scale
	p_root.add_child(instance)
	return instance


static func _transparent_material(p_color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = p_color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


static func _emissive_material(p_color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = p_color
	material.emission_enabled = true
	material.emission = p_color
	material.emission_energy_multiplier = 2.4
	return material


static func _collect_environment_nodes(p_node: Node, p_result: Array[Node]) -> void:
	if is_environment_node(p_node):
		p_result.append(p_node)
	for child in p_node.get_children():
		_collect_environment_nodes(child, p_result)


static func _assign_owner_recursive(p_node: Node, p_owner: Node) -> bool:
	if p_node == null or p_owner == null:
		return false
	var changed := false
	if p_node.owner != p_owner:
		p_node.owner = p_owner
		changed = true
	for child in p_node.get_children():
		if _assign_owner_recursive(child, p_owner):
			changed = true
	return changed


static func _particle_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	return material


static func _configure_particles(
	p_particles: GPUParticles3D,
	p_amount: int,
	p_lifetime: float
) -> void:
	p_particles.amount = p_amount
	p_particles.lifetime = p_lifetime
	p_particles.preprocess = p_lifetime * 0.5
	p_particles.local_coords = false
	p_particles.visibility_aabb = AABB(
		Vector3(-12.0, -5.0, -12.0),
		Vector3(24.0, 14.0, 24.0)
	)


static func _add_fog_particles(p_root: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "地面雾粒子"
	_configure_particles(particles, 48, 9.0)
	var process := _particle_material()
	process.emission_box_extents = Vector3(9.0, 0.7, 9.0)
	process.direction = Vector3(0.0, 0.1, 0.0)
	process.spread = 12.0
	process.initial_velocity_min = 0.05
	process.initial_velocity_max = 0.25
	process.gravity = Vector3(0.0, 0.02, 0.0)
	process.scale_min = 1.4
	process.scale_max = 3.2
	process.color = Color(0.72, 0.82, 0.86, 0.18)
	particles.process_material = process
	var fog_material := _transparent_material(Color(0.72, 0.82, 0.86, 0.22))
	fog_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var quad := QuadMesh.new()
	quad.size = Vector2(2.6, 1.2)
	quad.material = fog_material
	particles.draw_pass_1 = quad
	p_root.add_child(particles)


static func _add_cloud_layer(p_root: Node3D) -> void:
	var cloud_material := _transparent_material(Color(0.72, 0.76, 0.8, 0.42))
	var offsets := [
		Vector3(-4.0, 6.2, -2.0),
		Vector3(0.0, 6.7, 0.5),
		Vector3(4.2, 6.1, -1.0),
		Vector3(-2.2, 7.1, 2.4),
		Vector3(2.5, 7.3, 2.8),
		Vector3(-6.8, 6.8, 2.7),
		Vector3(6.6, 7.0, 2.2),
	]
	for index in range(offsets.size()):
		var sphere := SphereMesh.new()
		sphere.radius = 1.5 if index != 1 else 2.0
		sphere.height = 3.0 if index != 1 else 4.0
		sphere.radial_segments = 12
		sphere.rings = 6
		sphere.material = cloud_material
		_add_mesh_instance(
			p_root,
			"云团_%02d" % (index + 1),
			sphere,
			offsets[index],
			Vector3(1.0, 0.55, 1.0)
		)


static func _add_fire(p_root: Node3D) -> void:
	_add_omni_light(
		p_root,
		Vector3(0.0, 1.4, 0.0),
		Color("#ff8a36"),
		2.8,
		6.0
	)
	var particles := GPUParticles3D.new()
	particles.name = "火焰粒子"
	_configure_particles(particles, 72, 1.15)
	var process := _particle_material()
	process.emission_box_extents = Vector3(0.28, 0.08, 0.28)
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 18.0
	process.initial_velocity_min = 1.1
	process.initial_velocity_max = 2.5
	process.gravity = Vector3(0.0, -1.8, 0.0)
	process.scale_min = 0.22
	process.scale_max = 0.55
	process.color = Color("#ff8a36")
	particles.process_material = process
	var flame := SphereMesh.new()
	flame.radius = 0.22
	flame.height = 0.44
	flame.material = _emissive_material(Color("#ff7a2f"))
	particles.draw_pass_1 = flame
	p_root.add_child(particles)


static func _add_rain_sheet(p_root: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "成片雨幕"
	_configure_particles(particles, 360, 0.9)
	var process := _particle_material()
	process.emission_box_extents = Vector3(9.0, 0.3, 9.0)
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 2.0
	process.initial_velocity_min = 11.0
	process.initial_velocity_max = 16.0
	process.gravity = Vector3(0.0, -7.0, 0.0)
	process.scale_min = 0.65
	process.scale_max = 1.25
	particles.process_material = process
	var streak := BoxMesh.new()
	streak.size = Vector3(0.018, 0.58, 0.018)
	streak.material = _transparent_material(Color(0.68, 0.86, 1.0, 0.62))
	particles.draw_pass_1 = streak
	p_root.add_child(particles)


static func _add_wind_lines(p_root: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "环境风线"
	_configure_particles(particles, 96, 2.6)
	var process := _particle_material()
	process.emission_box_extents = Vector3(10.0, 4.0, 8.0)
	process.direction = Vector3(0.86, 0.08, -0.5).normalized()
	process.spread = 10.0
	process.initial_velocity_min = 5.5
	process.initial_velocity_max = 10.0
	process.gravity = Vector3.ZERO
	process.scale_min = 0.55
	process.scale_max = 1.35
	particles.process_material = process
	var line := BoxMesh.new()
	line.size = Vector3(1.2, 0.018, 0.018)
	line.material = _transparent_material(Color(0.75, 0.9, 0.96, 0.34))
	particles.draw_pass_1 = line
	p_root.add_child(particles)


static func _add_dust_motes(p_root: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "尘埃微粒"
	_configure_particles(particles, 90, 5.0)
	var process := _particle_material()
	process.emission_box_extents = Vector3(7.0, 3.0, 7.0)
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 180.0
	process.initial_velocity_min = 0.02
	process.initial_velocity_max = 0.16
	process.gravity = Vector3(0.0, 0.015, 0.0)
	process.scale_min = 0.04
	process.scale_max = 0.12
	particles.process_material = process
	var mote := SphereMesh.new()
	mote.radius = 0.07
	mote.height = 0.14
	mote.material = _emissive_material(Color(0.85, 0.92, 0.93))
	particles.draw_pass_1 = mote
	p_root.add_child(particles)
