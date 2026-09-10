@tool
extends Node3D

@export_enum(
	"case_gold_beacon",
	"ability_light_pillar",
	"breakable_hint",
	"door_red_seal",
	"objective_gold_pillar",
	"rest_recovery_ring",
	"pressure_plate_pulse",
	"dangerous_ground_warning"
) var effect_id: String = "case_gold_beacon":
	set(value):
		effect_id = value
		if is_inside_tree():
			call_deferred("_rebuild")

var _pulse_nodes: Array[Node3D] = []
var _spin_nodes: Array[Node3D] = []


func _ready() -> void:
	set_process(true)
	_rebuild()


func _process(p_delta: float) -> void:
	var time := float(Time.get_ticks_msec()) / 1000.0
	for index in range(_pulse_nodes.size()):
		var node := _pulse_nodes[index]
		if not is_instance_valid(node):
			continue
		var pulse := 1.0 + sin(time * 2.2 + float(index) * 0.7) * 0.06
		node.scale = Vector3.ONE * pulse
	for node in _spin_nodes:
		if is_instance_valid(node):
			node.rotate_y(p_delta * 0.65)


func _rebuild() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		remove_child(child)
		child.free()
	_pulse_nodes.clear()
	_spin_nodes.clear()
	match effect_id:
		"ability_light_pillar":
			_build_ability_pickup()
		"breakable_hint":
			_build_breakable_hint()
		"door_red_seal":
			_build_door_seal()
		"objective_gold_pillar":
			_build_objective_pillar()
		"rest_recovery_ring":
			_build_rest_ring()
		"pressure_plate_pulse":
			_build_pressure_plate_pulse()
		"dangerous_ground_warning":
			_build_dangerous_ground()
		_:
			_build_case_beacon()


func _build_case_beacon() -> void:
	_add_beam(Color("ffd166"), 3.4, 0.16, 0.72)
	var ring := _add_ring(Color("ffd166"), 0.85, 0.06, 0.16)
	_pulse_nodes.append(ring)
	var diamond := _add_box(
		"CaseDiamond",
		Vector3(0.42, 0.42, 0.42),
		Vector3(0.0, 2.75, 0.0),
		Vector3(45.0, 45.0, 0.0),
		Color("fff3b0"),
		0.95,
		3.2
	)
	_spin_nodes.append(diamond)


func _build_ability_pickup() -> void:
	_add_beam(Color("c9f26b"), 4.2, 0.28, 0.68)
	for index in range(3):
		var ring := _add_ring(
			Color("e7ff9a"),
			1.05 - float(index) * 0.18,
			0.12,
			0.18
		)
		ring.position.y = 0.35 + float(index) * 0.72
		_pulse_nodes.append(ring)
	for index in range(4):
		var angle := TAU * float(index) / 4.0
		_add_box(
			"AbilityArrow",
			Vector3(0.16, 0.82, 0.16),
			Vector3(cos(angle) * 1.15, 1.5, sin(angle) * 1.15),
			Vector3(0.0, -rad_to_deg(angle), -18.0),
			Color("dfff82"),
			0.92,
			2.8
		)


func _build_breakable_hint() -> void:
	var ring := _add_ring(Color("ffb35c"), 0.92, 0.09, 0.18)
	_pulse_nodes.append(ring)
	for index in range(4):
		var angle := TAU * float(index) / 4.0
		_add_box(
			"BreakMark",
			Vector3(0.12, 0.55, 0.12),
			Vector3(cos(angle) * 0.72, 0.38, sin(angle) * 0.72),
			Vector3(0.0, -rad_to_deg(angle), 24.0),
			Color("ff9b45"),
			0.9,
			2.4
		)


func _build_door_seal() -> void:
	for index in range(2):
		_add_box(
			"DoorSealPlane",
			Vector3(2.4, 2.5, 0.05),
			Vector3(-0.62 + float(index) * 1.24, 1.28, 0.0),
			Vector3.ZERO,
			Color("ff4d4d"),
			0.16,
			1.4
		)
	var seal := _add_ring(Color("ff5b5b"), 0.82, 0.11, 0.24)
	seal.position.y = 1.22
	seal.rotation_degrees.x = 90.0
	_pulse_nodes.append(seal)
	_add_box(
		"DoorSealCore",
		Vector3(0.18, 1.6, 0.18),
		Vector3(0.0, 1.2, 0.0),
		Vector3(0.0, 0.0, 42.0),
		Color("ffb0a3"),
		0.9,
		3.0
	)


func _build_objective_pillar() -> void:
	_add_beam(Color("ffd45c"), 5.2, 0.34, 0.62)
	var lower := _add_ring(Color("ffe58a"), 1.15, 0.1, 0.2)
	lower.position.y = 0.18
	_pulse_nodes.append(lower)
	var upper := _add_ring(Color("fff0b8"), 0.75, 0.08, 0.2)
	upper.position.y = 3.65
	_pulse_nodes.append(upper)
	var star := _add_box(
		"ObjectiveStar",
		Vector3(0.55, 0.55, 0.55),
		Vector3(0.0, 4.25, 0.0),
		Vector3(45.0, 45.0, 0.0),
		Color("fff6cf"),
		1.0,
		4.0
	)
	_spin_nodes.append(star)


func _build_rest_ring() -> void:
	var ring := _add_ring(Color("d9ffe4"), 1.25, 0.13, 0.22)
	ring.position.y = 0.08
	_pulse_nodes.append(ring)
	_add_box(
		"RestCrossH",
		Vector3(1.1, 0.18, 0.18),
		Vector3(0.0, 0.18, 0.0),
		Vector3.ZERO,
		Color("b9ffcf"),
		0.92,
		2.4
	)
	_add_box(
		"RestCrossV",
		Vector3(0.18, 1.1, 0.18),
		Vector3(0.0, 0.18, 0.0),
		Vector3.ZERO,
		Color("b9ffcf"),
		0.92,
		2.4
	)


func _build_pressure_plate_pulse() -> void:
	for index in range(3):
		var ring := _add_ring(
			Color("8eeaff"),
			0.75 + float(index) * 0.32,
			0.04,
			0.14
		)
		ring.position.y = 0.07 + float(index) * 0.02
		_pulse_nodes.append(ring)
	for index in range(4):
		var angle := TAU * float(index) / 4.0
		_add_box(
			"PlateArrow",
			Vector3(0.12, 0.12, 0.65),
			Vector3(cos(angle) * 0.18, 0.12, sin(angle) * 0.18),
			Vector3(0.0, -rad_to_deg(angle), 0.0),
			Color("aef4ff"),
			0.92,
			2.2
		)


func _build_dangerous_ground() -> void:
	_add_box(
		"DangerField",
		Vector3(2.4, 0.035, 2.4),
		Vector3(0.0, 0.02, 0.0),
		Vector3.ZERO,
		Color("ef3f3f"),
		0.18,
		1.2
	)
	for index in range(6):
		var x := -1.0 + float(index) * 0.4
		_add_box(
			"DangerStripe",
			Vector3(0.12, 0.04, 2.15),
			Vector3(x, 0.055, 0.0),
			Vector3(0.0, 28.0, 0.0),
			Color("ff6b5f"),
			0.72,
			1.8
		)
	var border := _add_ring(Color("ff4d4d"), 1.3, 0.08, 0.2)
	border.position.y = 0.08
	_pulse_nodes.append(border)


func _add_beam(
	p_color: Color,
	p_height: float,
	p_radius: float,
	p_alpha: float
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = p_radius * 0.72
	mesh.bottom_radius = p_radius
	mesh.height = p_height
	mesh.radial_segments = 24
	return _add_mesh(
		"Beam",
		mesh,
		Vector3(0.0, p_height * 0.5, 0.0),
		Vector3.ZERO,
		p_color,
		p_alpha,
		2.4
	)


func _add_ring(
	p_color: Color,
	p_radius: float,
	p_thickness: float,
	p_alpha: float
) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(0.01, p_radius - p_thickness * 0.5)
	mesh.outer_radius = p_radius + p_thickness * 0.5
	mesh.rings = 32
	mesh.ring_segments = 8
	return _add_mesh(
		"Ring",
		mesh,
		Vector3.ZERO,
		Vector3.ZERO,
		p_color,
		p_alpha,
		2.8
	)


func _add_box(
	p_name: String,
	p_size: Vector3,
	p_position: Vector3,
	p_rotation_degrees: Vector3,
	p_color: Color,
	p_alpha: float,
	p_emission: float
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = p_size
	return _add_mesh(
		p_name,
		mesh,
		p_position,
		p_rotation_degrees,
		p_color,
		p_alpha,
		p_emission
	)


func _add_mesh(
	p_name: String,
	p_mesh: Mesh,
	p_position: Vector3,
	p_rotation_degrees: Vector3,
	p_color: Color,
	p_alpha: float,
	p_emission: float
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = p_name
	instance.mesh = p_mesh
	instance.position = p_position
	instance.rotation_degrees = p_rotation_degrees
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.material_override = _make_material(p_color, p_alpha, p_emission)
	add_child(instance)
	return instance


func _make_material(
	p_color: Color,
	p_alpha: float,
	p_emission: float
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(p_color.r, p_color.g, p_color.b, p_alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = p_color
	material.emission_energy_multiplier = p_emission
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
