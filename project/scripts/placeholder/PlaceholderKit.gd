class_name PlaceholderKit
extends RefCounted

static var _material_cache: Dictionary = {}
static var _material_alpha_cache: Dictionary = {}
static var _box_mesh_cache: Dictionary = {}
static var _quad_mesh_cache: Dictionary = {}
static var _sphere_mesh_cache: Dictionary = {}
static var _emissive_material_cache: Dictionary = {}
static var _circle_texture_cache: Dictionary = {}


static func box(p_node_name: String, p_color: Color, p_size: Vector3) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = p_node_name
	item.mesh = box_mesh(p_size)
	item.material_override = material(p_color)
	return item


static func box_mesh(p_size: Vector3) -> BoxMesh:
	var key := "box_%s_%s_%s" % [p_size.x, p_size.y, p_size.z]
	if _box_mesh_cache.has(key):
		return _box_mesh_cache[key]
	var mesh := BoxMesh.new()
	mesh.size = p_size
	_box_mesh_cache[key] = mesh
	return mesh


static func capsule(p_node_name: String, p_color: Color, p_height: float, p_radius: float) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.height = p_height
	mesh.radius = p_radius
	var item := MeshInstance3D.new()
	item.name = p_node_name
	item.mesh = mesh
	item.material_override = material(p_color)
	return item


static func material(p_color: Color) -> StandardMaterial3D:
	var key := String(p_color.to_html(false))
	if _material_cache.has(key):
		return _material_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = p_color
	mat.roughness = 0.85
	mat.metallic = 0.0
	_material_cache[key] = mat
	return mat


static func material_alpha(p_color: Color, p_alpha: float) -> StandardMaterial3D:
	var key := "%s_%s" % [p_color.to_html(false), p_alpha]
	if _material_alpha_cache.has(key):
		return _material_alpha_cache[key]
	var mat: StandardMaterial3D = material(p_color).duplicate()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = p_alpha
	_material_alpha_cache[key] = mat
	return mat


static func ground_quad(p_node_name: String, p_color: Color, p_size: Vector2) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = p_node_name
	item.mesh = quad_mesh(p_size)
	item.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	item.material_override = material_alpha(p_color, 0.62)
	return item


static func quad_mesh(p_size: Vector2) -> QuadMesh:
	var key := "quad_%s_%s" % [p_size.x, p_size.y]
	if _quad_mesh_cache.has(key):
		return _quad_mesh_cache[key]
	var mesh := QuadMesh.new()
	mesh.size = p_size
	_quad_mesh_cache[key] = mesh
	return mesh


static func sphere_mesh(p_radius: float, p_height: float) -> SphereMesh:
	var key := "%s_%s" % [p_radius, p_height]
	if _sphere_mesh_cache.has(key):
		return _sphere_mesh_cache[key]
	var mesh := SphereMesh.new()
	mesh.radius = p_radius
	mesh.height = p_height
	_sphere_mesh_cache[key] = mesh
	return mesh


static func emissive_material(p_color: Color, p_energy: float = 2.2) -> StandardMaterial3D:
	var key := "%s_%s" % [p_color.to_html(false), p_energy]
	if _emissive_material_cache.has(key):
		return _emissive_material_cache[key]
	var mat: StandardMaterial3D = material(p_color).duplicate()
	mat.emission_enabled = true
	mat.emission = p_color
	mat.emission_energy_multiplier = p_energy
	_emissive_material_cache[key] = mat
	return mat


static func circle_texture(p_fill: Color, p_ring: Color, p_radius: int = 13) -> ImageTexture:
	var key := "%s_%s_%d" % [p_fill.to_html(false), p_ring.to_html(false), p_radius]
	if _circle_texture_cache.has(key):
		return _circle_texture_cache[key]
	var side := p_radius * 2 + 8
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var center := Vector2(side * 0.5, side * 0.5)
	for y in range(side):
		for x in range(side):
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance <= float(p_radius):
				image.set_pixel(x, y, p_fill)
			elif distance <= float(p_radius + 2):
				image.set_pixel(x, y, p_ring)
	var texture := ImageTexture.create_from_image(image)
	_circle_texture_cache[key] = texture
	return texture
