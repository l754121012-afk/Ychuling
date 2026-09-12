class_name FSGroundPaintCatalog
extends RefCounted

const MIN_RADIUS := 0.5
const MAX_RADIUS := 12.0
const STAMP_SPACING_RATIO := 0.32
const GROUP_NAME := "GROUND_PAINT_地面绘制"
const PREFIX := "GROUND_PAINT_"
const META_KEY := "__fs_ground_paint"
const SURFACE_OFFSET := 0.018
const SURFACE_THICKNESS := 0.018

const PRESETS := [
	{
		"id": "wet_mud",
		"label": "湿泥",
		"color": "#5d5140",
		"accent": "#776a52",
		"roughness": 0.44,
		"metallic": 0.0,
		"emission": 0.0,
	},
	{
		"id": "moss",
		"label": "青苔",
		"color": "#3f5f38",
		"accent": "#6f8b4d",
		"roughness": 0.9,
		"metallic": 0.0,
		"emission": 0.0,
	},
	{
		"id": "stone_chips",
		"label": "石屑",
		"color": "#777a76",
		"accent": "#b9b8ad",
		"roughness": 0.82,
		"metallic": 0.0,
		"emission": 0.0,
	},
	{
		"id": "water_sheen",
		"label": "水光",
		"color": "#407e91",
		"accent": "#a8e0e6",
		"roughness": 0.12,
		"metallic": 0.12,
		"emission": 0.16,
	},
	{
		"id": "ruined_dirt",
		"label": "破败土痕",
		"color": "#4a3931",
		"accent": "#86664a",
		"roughness": 0.72,
		"metallic": 0.0,
		"emission": 0.0,
	},
]

const SHAPES := [
	{"id": "circle", "label": "圆形笔触"},
	{"id": "oval", "label": "长椭圆笔触"},
	{"id": "rectangle", "label": "方形笔触"},
]


static func presets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in PRESETS:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	return result


static func shapes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in SHAPES:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	return result


static func brush_params(
	p_preset_id: String,
	p_shape_id: String,
	p_radius: float,
	p_opacity: float
) -> Dictionary:
	var preset := _find_preset(p_preset_id)
	if preset.is_empty():
		preset = PRESETS[0] as Dictionary
	var shape := _find_shape(p_shape_id)
	if shape.is_empty():
		shape = SHAPES[0] as Dictionary
	return {
		"preset_id": str(preset.get("id", "wet_mud")),
		"preset_label": str(preset.get("label", "湿泥")),
		"shape_id": str(shape.get("id", "circle")),
		"shape_label": str(shape.get("label", "圆形笔触")),
		"radius": clampf(p_radius, MIN_RADIUS, MAX_RADIUS),
		"opacity": clampf(p_opacity, 0.05, 1.0),
		"material": preset.duplicate(true),
	}


static func apply_stamp(
	p_parent: Node3D,
	p_position: Vector3,
	p_normal: Vector3,
	p_owner: Node,
	p_params: Dictionary
) -> Dictionary:
	if p_parent == null:
		return {"ok": false, "error": "没有可用于保存地面绘制的父节点。"}
	if p_owner == null:
		return {"ok": false, "error": "地面绘制需要一个作者场景根节点作为 owner。"}
	var preset_id := str(p_params.get("preset_id", "wet_mud"))
	var shape_id := str(p_params.get("shape_id", "circle"))
	var preset := _find_preset(preset_id)
	if preset.is_empty():
		return {"ok": false, "error": "未知地面绘制预设：%s" % preset_id}
	var shape := _find_shape(shape_id)
	if shape.is_empty():
		return {"ok": false, "error": "未知地面绘制形状：%s" % shape_id}
	var radius := clampf(float(p_params.get("radius", 2.5)), MIN_RADIUS, MAX_RADIUS)
	var opacity := clampf(float(p_params.get("opacity", 0.7)), 0.05, 1.0)
	var normal := p_normal.normalized()
	if normal.is_zero_approx():
		normal = Vector3.UP
	var world_position := p_position + normal * SURFACE_OFFSET
	var patch := MeshInstance3D.new()
	patch.name = _next_name(p_parent, preset_id, shape_id)
	patch.mesh = _make_mesh(shape_id, radius)
	patch.material_override = _make_material(preset, opacity)
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p_parent.add_child(patch)
	var basis := _basis_for_normal(normal).rotated(normal, _stable_yaw(world_position))
	if shape_id == "oval":
		basis = basis.scaled(Vector3(1.0, 1.0, 0.42))
	patch.global_transform = Transform3D(basis, world_position)
	patch.set_meta(META_KEY, {
		"preset_id": preset_id,
		"preset_label": str(preset.get("label", preset_id)),
		"shape_id": shape_id,
		"radius": radius,
		"opacity": opacity,
	})
	patch.owner = p_owner
	return {
		"ok": true,
		"node": patch,
		"paint": patch.get_meta(META_KEY).duplicate(true),
	}


static func is_paint_node(p_node: Node) -> bool:
	return (
		p_node != null
		and str(p_node.name).begins_with(PREFIX)
		and p_node.has_meta(META_KEY)
	)


static func remove_paint_node(p_node: Node) -> bool:
	if not is_paint_node(p_node):
		return false
	var parent := p_node.get_parent()
	if parent == null:
		return false
	parent.remove_child(p_node)
	p_node.free()
	return true


static func _find_preset(p_preset_id: String) -> Dictionary:
	for entry in PRESETS:
		if str(entry.get("id", "")) == p_preset_id:
			return entry
	return {}


static func _find_shape(p_shape_id: String) -> Dictionary:
	for entry in SHAPES:
		if str(entry.get("id", "")) == p_shape_id:
			return entry
	return {}


static func _next_name(p_parent: Node, p_preset_id: String, p_shape_id: String) -> String:
	var prefix := "%s%s_%s" % [PREFIX, p_preset_id.to_upper(), p_shape_id.to_upper()]
	var index := 1
	while p_parent.has_node("%s_%03d" % [prefix, index]):
		index += 1
	return "%s_%03d" % [prefix, index]


static func _make_mesh(p_shape_id: String, p_radius: float) -> Mesh:
	match p_shape_id:
		"rectangle":
			var box := BoxMesh.new()
			box.size = Vector3(p_radius * 1.55, SURFACE_THICKNESS, p_radius * 1.12)
			return box
		_:
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = p_radius
			cylinder.bottom_radius = p_radius
			cylinder.height = SURFACE_THICKNESS
			cylinder.radial_segments = 28
			cylinder.rings = 1
			return cylinder


static func _make_material(p_preset: Dictionary, p_opacity: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = _color_from(str(p_preset.get("color", "#5d5140")), p_opacity)
	material.roughness = clampf(float(p_preset.get("roughness", 0.7)), 0.0, 1.0)
	material.metallic = clampf(float(p_preset.get("metallic", 0.0)), 0.0, 1.0)
	var emission := clampf(float(p_preset.get("emission", 0.0)), 0.0, 1.0)
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = _color_from(str(p_preset.get("accent", "#ffffff")), 1.0)
		material.emission_energy_multiplier = emission * 1.8
	return material


static func _color_from(p_html: String, p_alpha: float) -> Color:
	var color := Color.from_string(p_html, Color.WHITE)
	color.a = clampf(p_alpha, 0.0, 1.0)
	return color


static func _basis_for_normal(p_normal: Vector3) -> Basis:
	var up := p_normal.normalized()
	var reference := Vector3.FORWARD
	if absf(up.dot(reference)) > 0.92:
		reference = Vector3.RIGHT
	var right := reference.cross(up).normalized()
	var forward := up.cross(right).normalized()
	var basis := Basis()
	basis.x = right
	basis.y = up
	basis.z = forward
	return basis.orthonormalized()


static func _stable_yaw(p_position: Vector3) -> float:
	var value := sin(p_position.x * 12.9898 + p_position.z * 78.233) * 43758.5453
	return fposmod(value, TAU)
